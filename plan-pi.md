# Plan: `check-climate-adapt` Script Using `pi` Agent

## Background

The `taskman` directory contains tools to query the EEA Taskman (Redmine) instance for the Climate-ADAPT project. There are currently two implementations:

| Script | Tool | How it works |
|--------|------|-------------|
| `check-climate-adapt.sh` | `gemini` CLI | Reads prompt from file, pipes to Gemini CLI which has MCP access to Redmine via `.gemini/settings.json` |
| `check-climate-adapt-opencode.sh` | `opencode` CLI | Reads prompt from file, passes to OpenCode which has MCP access to Redmine via `.opencode/config.jsonc` |

Both scripts rely on the LLM tool having **MCP (Model Context Protocol) access** to the Redmine API, which provides tools like `list_issues`, `get_issue`, etc.

## Goal

Create `bin/check-climate-adapt-pi.sh` — a third variant that uses the `pi` agent CLI (`pi` command) to achieve the same result.

## Key Challenge

Unlike `gemini` and `opencode`, **pi does not have built-in MCP server support**. Pi's tool ecosystem works differently:

- **Gemini**: Native MCP server support via `mcpServers` in settings
- **OpenCode**: Native MCP server support via `mcp` in config
- **Pi**: Uses **TypeScript extensions** that register **custom tools** via `pi.registerTool()`

This means we cannot simply point pi at an MCP server. Instead, we need one of two approaches:

---

## Approach A: Pi Extension with Generic `redmine_request` Tool (Recommended)

After studying [mcp-redmine](https://github.com/runekaagaard/mcp-redmine), the clever insight is that the MCP server uses a **single generic `redmine_request` tool** rather than separate tools per endpoint. It takes `(path, method, data, params)` and makes HTTP calls — the LLM itself figures out which Redmine endpoints to call.

The pi extension follows the same pattern: one generic `redmine_request` tool that mirrors the MCP server's approach, plus discovery tools for the OpenAPI spec.

### Implementation Steps

1. **Create `bin/pi-redmine-tools.ts`** — a pi extension that:
   - Registers a generic `redmine_request(path, method, data, params)` tool — identical in spirit to mcp-redmine
   - Optionally registers `redmine_paths_list()` and `redmine_paths_info(paths)` discovery tools
   - Reads credentials from env vars (`REDMINE_URL`, `REDMINE_API_KEY`, `REDMINE_REQUEST_INSTRUCTIONS`)
   - Uses `fetch()` to make HTTP calls (no MCP dependency)
   - Wraps responses with `<insecure-content>` tags (from mcp-redmine pattern) for safety
   - Formats responses as YAML or JSON (configurable)

2. **Create `bin/check-climate-adapt-pi.sh`** — the shell script:
   - Sources the same `.opencode/.env` for credentials
   - Reads the same prompt from `prompts/climate_adapt_check.txt`
   - Invokes: `pi -p --extension ./bin/pi-redmine-tools.ts "$PROMPT" | glow`
   - Uses `--extension` to load the custom tools extension
   - Optionally sets a model via `--model` flag

3. **Add Makefile target**:
   ```makefile
   .PHONY: check-climate-adapt-pi
   check-climate-adapt-pi: ## Check Climate-ADAPT project using pi agent
       @./bin/check-climate-adapt-pi.sh
   ```

### Pros
- Self-contained, no external MCP dependencies
- Leverages pi's native extension system
- Tools are type-safe (TypeBox schemas)
- Follows pi's design philosophy

### Cons
- Requires writing TypeScript extension code
- Must replicate Redmine API logic that MCP already handles

---

## Approach B: Bash Tools + System Prompt Injection

Use pi's built-in `bash` tool to query Redmine via `curl`, and inject instructions into the system prompt so the LLM knows how to interpret the results.

### Implementation Steps

1. **Create `bin/check-climate-adapt-pi.sh`**:
   - Pre-fetch Redmine issue data using `curl` to the Redmine API
   - Inject the data into the prompt as context
   - Use `pi -p --append-system-prompt` with instructions on how to use the data
   - Pipe output to `glow`

2. **Script flow**:
   ```bash
   # Fetch all open issues for Climate-ADAPT project
   ISSUES=$(curl -s "https://taskman.eionet.europa.eu/issues.json?key=API_KEY&project_id=climate-adapt&status_id=open" | jq ...)
   
   # Build prompt with embedded data
   PROMPT="Here are the current Climate-ADAPT issues:\n\n$ISSUES\n\nReview these issues and identify critical items..."
   
   # Run pi with the prompt
   pi -p "$PROMPT" | glow
   ```

### Pros
- Simpler, no TypeScript extension needed
- Uses only pi CLI flags (no custom code)
- No tool registration overhead

### Cons
- **Token-heavy**: All issue data sent in every prompt
- **No interactivity**: LLM can't ask follow-up questions about specific issues
- **Fragile**: Large issue sets may exceed context window
- **Less elegant**: Hard-coding API calls in bash vs. proper tool integration

---

## Approach C: Pi SDK Script (Node.js)

Write a Node.js script that uses the pi SDK directly, loading the MCP-redmine tool via pi's extension system. This is the most complex option.

### Cons
- Requires Node.js runtime setup
- Over-engineered for a simple CLI wrapper
- Not a drop-in replacement for the shell scripts

---

## Recommended: Approach A

**Approach A** is the best fit because:

1. It mirrors the capability of the existing scripts (LLM with Redmine tool access)
2. It follows pi's extension-based architecture
3. The custom tools are reusable and composable
4. It keeps the Redmine API logic in one well-defined place

## Implementation Details for Approach A

### File: `bin/pi-redmine-tools.ts`

Following the mcp-redmine pattern, this extension registers a **generic `redmine_request` tool** — the same single-tool approach that makes the MCP server so simple and powerful. The LLM itself determines which Redmine endpoints to call.

```typescript
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const REDMINE_URL = (process.env.REDMINE_URL || "https://taskman.eionet.europa.eu/").replace(/\/$/, "");
const REDMINE_API_KEY = process.env.REDMINE_API_KEY || "";
const REDMINE_HEADERS = process.env.REDMINE_HEADERS || "";
const RESPONSE_FORMAT = (process.env.REDMINE_RESPONSE_FORMAT || "yaml").toLowerCase();
const REQUEST_INSTRUCTIONS = process.env.REDMINE_REQUEST_INSTRUCTIONS
  ? readFileSync(resolve(process.env.REDMINE_REQUEST_INSTRUCTIONS), "utf-8")
  : "";

// Load OpenAPI spec for discovery tools
const specPath = resolve(__dirname, "redmine_openapi.yml");
let SPEC: any;
try {
  const yaml = await import("js-yaml");
  SPEC = yaml.default?.load(readFileSync(specPath, "utf-8")) ?? {};
} catch {
  SPEC = {};
}

function toYAML(obj: any): string {
  // Simple YAML serializer (or use js-yaml if available)
  return JSON.stringify(obj, null, 2);
}

function formatResponse(statusCode: number, body: any, error: string): string {
  const result = { status_code: statusCode, body, error };
  return RESPONSE_FORMAT === "json" ? JSON.stringify(result, null, 2) : toYAML(result);
}

function wrapInsecure(content: string): string {
  const tag = Math.random().toString(36).slice(2, 18);
  return `<insecure-content-${tag}>\n${content}\n</insecure-content-${tag}>`;
}

async function redmineRequest(
  path: string,
  method: string = "get",
  data?: any,
  params?: Record<string, string>
): Promise<string> {
  const url = new URL(path.startsWith("/") ? path.slice(1) : path, REDMINE_URL);
  if (params) {
    Object.entries(params).forEach(([k, v]) => url.searchParams.set(k, v));
  }

  const headers: Record<string, string> = {
    "X-Redmine-API-Key": REDMINE_API_KEY,
    "Content-Type": "application/json",
  };
  if (REDMINE_HEADERS) {
    REDMINE_HEADERS.split(",").forEach((h) => {
      if (h.includes(":")) {
        const [key, ...rest] = h.split(":");
        headers[key.trim()] = rest.join(":").trim();
      }
    });
  }

  try {
    const opts: RequestInit = { method: method.toUpperCase(), headers };
    if (data && ["post", "put", "patch"].includes(method.toLowerCase())) {
      opts.body = JSON.stringify(data);
    }

    const res = await fetch(url.toString(), opts);
    let body: any;
    const ct = res.headers.get("content-type") || "";
    if (ct.includes("json")) {
      body = await res.json();
    } else {
      body = await res.text();
    }

    if (!res.ok) {
      return wrapInsecure(formatResponse(res.status, body, `${res.status} ${res.statusText}`));
    }
    return wrapInsecure(formatResponse(res.status, body, ""));
  } catch (e: any) {
    return wrapInsecure(formatResponse(0, null, `${e.name}: ${e.message}`));
  }
}

export default function (pi: ExtensionAPI) {
  // Generic Redmine request tool — mirrors mcp-redmine's approach
  pi.registerTool({
    name: "redmine_request",
    label: "Redmine Request",
    description: `Make a request to the Redmine API.\n\n${REQUEST_INSTRUCTIONS}`.trim(),
    parameters: Type.Object({
      path: Type.String({ description: "API endpoint path (e.g. '/issues.json', '/projects.json')" }),
      method: Type.Optional(Type.String({ description: "HTTP method (default: 'get')", default: "get" })),
      data: Type.Optional(Type.Record(Type.String(), Type.Unknown(), { description: "Request body for POST/PUT" })),
      params: Type.Optional(Type.Record(Type.String(), Type.String(), { description: "Query parameters" })),
    }),
    async execute(_toolCallId, params) {
      return {
        content: [{ type: "text", text: await redmineRequest(params.path, params.method, params.data, params.params) }],
      };
    },
  });

  // Discovery: list available API paths
  pi.registerTool({
    name: "redmine_paths_list",
    label: "Redmine Paths List",
    description: "Return a list of available API paths from the Redmine OpenAPI spec",
    parameters: Type.Object({}),
    async execute() {
      const paths = SPEC.paths ? Object.keys(SPEC.paths) : [];
      return {
        content: [{ type: "text", text: formatResponse(200, paths, "") }],
      };
    },
  });

  // Discovery: get path specs
  pi.registerTool({
    name: "redmine_paths_info",
    label: "Redmine Paths Info",
    description: "Get full API specifications for given path templates",
    parameters: Type.Object({
      path_templates: Type.Array(Type.String(), { description: "List of path templates (e.g. ['/issues.json'])" }),
    }),
    async execute(_toolCallId, params) {
      const info: Record<string, any> = {};
      for (const p of params.path_templates) {
        if (SPEC.paths?.[p]) info[p] = SPEC.paths[p];
      }
      return {
        content: [{ type: "text", text: formatResponse(200, info, "") }],
      };
    },
  });
}
```

### File: `bin/check-climate-adapt-pi.sh`

```bash
#!/bin/bash

# Ensure we run from the project root
cd "$(dirname "$0")/.." || exit 1

# Load Redmine credentials from .env
source .opencode/.env

PROMPT_FILE="prompts/climate_adapt_check.txt"

if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: Prompt file $PROMPT_FILE not found."
    exit 1
fi

PROMPT=$(cat "$PROMPT_FILE")

# Call pi with the prompt, loading the Redmine tools extension,
# in print mode (-p) for non-interactive execution, pipe to glow for formatting
pi -p --extension ./bin/pi-redmine-tools.ts "$PROMPT" | glow
```

## Files to Create

| File | Description |
|------|-------------|
| `bin/check-climate-adapt-pi.sh` | Shell script entry point (like existing two scripts) |
| `bin/pi-redmine-tools.ts` | Pi extension with generic `redmine_request` tool + discovery tools |
| `bin/redmine_openapi.yml` | Copy of the Redmine OpenAPI spec (from mcp-redmine) for discovery tools |
| `Makefile` (update) | Add `check-climate-adapt-pi` target |

## Files to Update

| File | Change |
|------|--------|
| `Makefile` | Add `.PHONY: check-climate-adapt-pi` and target |
| `GEMINI.md` (optional) | Document the new pi variant |

## Testing Strategy

1. Run `./bin/check-climate-adapt-pi.sh` and verify it queries Redmine
2. Verify the output contains clickable Markdown issue links (as required by the prompt)
3. Compare output quality with the gemini and opencode versions
4. Test with `pi --list-models` to choose an appropriate model if needed
