/**
 * Pi Extension: Redmine API Tools
 *
 * Provides generic Redmine API access via `redmine_request`, `redmine_paths_list`,
 * and `redmine_paths_info` tools — mirroring the approach of mcp-redmine.
 *
 * Usage:
 *   pi -p --extension ./bin/pi-redmine-tools.ts "$PROMPT"
 *
 * Environment variables:
 *   REDMINE_URL                  - Redmine instance URL (required)
 *   REDMINE_API_KEY              - API key (required)
 *   REDMINE_HEADERS              - Comma-separated custom headers (optional)
 *   REDMINE_RESPONSE_FORMAT      - "yaml" or "json" (default: yaml)
 *   REDMINE_REQUEST_INSTRUCTIONS - Path to instructions file (optional)
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

// ── Configuration ────────────────────────────────────────────────────────────

const REDMINE_URL = (process.env.REDMINE_URL || "https://taskman.eionet.europa.eu/")
  .replace(/\/+$/, "");

const REDMINE_API_KEY = process.env.REDMINE_API_KEY || "";

const REDMINE_HEADERS: Record<string, string> = {};
if (process.env.REDMINE_HEADERS) {
  for (const header of process.env.REDMINE_HEADERS.split(",")) {
    const idx = header.indexOf(":");
    if (idx > -1) {
      const key = header.slice(0, idx).trim();
      const value = header.slice(idx + 1).trim();
      if (key && value) REDMINE_HEADERS[key] = value;
    }
  }
}

const RESPONSE_FORMAT = (process.env.REDMINE_RESPONSE_FORMAT || "yaml").toLowerCase() === "json";

const REQUEST_INSTRUCTIONS = process.env.REDMINE_REQUEST_INSTRUCTIONS
  ? readFileSync(resolve(process.env.REDMINE_REQUEST_INSTRUCTIONS), "utf-8")
  : "";

// ── OpenAPI spec loading ─────────────────────────────────────────────────────

let SPEC: { paths?: Record<string, any> } = {};

try {
  const specPath = resolve(__dirname, "redmine_openapi.yml");
  // Use a simple YAML parser — js-yaml is available in pi's bundled deps
  const { default: yaml } = await import("js-yaml");
  const raw = readFileSync(specPath, "utf-8");
  const parsed = yaml.default?.load(raw);
  if (parsed && typeof parsed === "object" && "paths" in parsed) {
    SPEC = parsed as { paths?: Record<string, any> };
  }
} catch {
  // No spec available — discovery tools will return empty
}

// ── Helpers ──────────────────────────────────────────────────────────────────

function formatResponse(statusCode: number, body: unknown, error: string): string {
  const result = { status_code: statusCode, body, error };
  // Use JSON format for reliable serialization (YAML requires js-yaml at runtime)
  return JSON.stringify(result, null, 2);
}

function wrapInsecure(content: string): string {
  const tag = Math.random().toString(36).slice(2, 18);
  return `<insecure-content-${tag}>\n${content}\n</insecure-content-${tag}>`;
}

// ── Core Redmine request ─────────────────────────────────────────────────────

async function redmineRequest(
  path: string,
  method: string = "get",
  data?: unknown,
  params?: Record<string, string>,
): Promise<string> {
  const cleanPath = path.startsWith("/") ? path.slice(1) : path;
  const url = new URL(cleanPath, REDMINE_URL);

  if (params) {
    for (const [key, value] of Object.entries(params)) {
      url.searchParams.set(key, value);
    }
  }

  const headers: Record<string, string> = {
    "X-Redmine-API-Key": REDMINE_API_KEY,
    "Content-Type": "application/json",
  };
  Object.assign(headers, REDMINE_HEADERS);

  try {
    const opts: RequestInit = { method: method.toUpperCase(), headers };
    if (data && ["post", "put", "patch"].includes(method.toLowerCase())) {
      opts.body = JSON.stringify(data);
    }

    const res = await fetch(url.toString(), opts);
    let body: unknown;
    const ct = res.headers.get("content-type") || "";
    if (ct.includes("json")) {
      body = await res.json();
    } else {
      body = await res.text();
    }

    if (!res.ok) {
      return wrapInsecure(await formatResponse(res.status, body, `${res.status} ${res.statusText}`));
    }
    return wrapInsecure(await formatResponse(res.status, body, ""));
  } catch (e: unknown) {
    const err = e as Error;
    return wrapInsecure(await formatResponse(0, null, `${err.name}: ${err.message}`));
  }
}

// ── Extension ────────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  // Generic Redmine request tool — mirrors mcp-redmine's single-tool approach
  pi.registerTool({
    name: "redmine_request",
    label: "Redmine Request",
    description: `Make a request to the Redmine API.\n\n${REQUEST_INSTRUCTIONS}`.trim(),
    parameters: Type.Object({
      path: Type.String({
        description: "API endpoint path (e.g. '/issues.json', '/projects.json', '/issues/12345.json')",
      }),
      method: Type.Optional(
        Type.String({ description: "HTTP method (default: 'get')", default: "get" }),
      ),
      data: Type.Optional(
        Type.Record(Type.String(), Type.Unknown(), {
          description: "Request body for POST/PUT (JSON object)",
        }),
      ),
      params: Type.Optional(
        Type.Record(Type.String(), Type.String(), {
          description: "Query parameters (e.g. { status_id: 'open', limit: '100' })",
        }),
      ),
    }),
    async execute(_toolCallId, params) {
      return {
        content: [
          {
            type: "text",
            text: await redmineRequest(
              params.path,
              params.method,
              params.data,
              params.params,
            ),
          },
        ],
      };
    },
  });

  // Discovery: list available API paths from OpenAPI spec
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

  // Discovery: get full path specifications
  pi.registerTool({
    name: "redmine_paths_info",
    label: "Redmine Paths Info",
    description: "Get full API specifications for given path templates",
    parameters: Type.Object({
      path_templates: Type.Array(Type.String(), {
        description: "List of path templates (e.g. ['/issues.json', '/projects.json'])",
      }),
    }),
    async execute(_toolCallId, params) {
      const info: Record<string, any> = {};
      for (const p of params.path_templates) {
        if (SPEC.paths?.[p]) {
          info[p] = SPEC.paths[p];
        }
      }
      return {
        content: [{ type: "text", text: formatResponse(200, info, "") }],
      };
    },
  });
}
