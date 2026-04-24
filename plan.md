# Plan: Create OpenCode Version of Climate-ADAPT Check Script

## Goal
Create an OpenCode-powered version of the existing Gemini-based `bin/check-climate-adapt.sh` script.

## What Exists

### Gemini Version (existing)
- **Script**: `bin/check-climate-adapt.sh`
  - Reads prompt from `prompts/climate_adapt_check.txt`
  - Runs: `gemini -p "$PROMPT" --skip-trust --approval-mode=yolo | glow`
- **Config**: `.gemini/settings.json` — defines `redmine` MCP server using `uvx mcp-redmine`
- **Credentials**: `.gemini/.env` — contains `REDMINE_URL`, `REDMINE_API_KEY`, `REDMINE_REQUEST_INSTRUCTIONS`, `REDMINE_ALLOWED_DIRECTORIES`
- **Prompt**: `prompts/climate_adapt_check.txt`

### OpenCode Environment
- **Global config**: `~/.config/opencode/opencode.jsonc` — has provider `localgw` pointing to `http://localhost:6000/v1` (LLM gateway, no MCP)
- **MCP section** in global config: `"mcp"` key exists but is empty/commented out
- **OpenCode CLI**: `opencode run <message>` — takes prompt as positional argument
- **No local opencode config** in the project (`no .opencode/` directory)

## What Was Found During Exploration
- `opencode run` messages must be passed as positional arguments (e.g., `opencode run "hello"`)
- Model available at `localgw` provider: `Qwen3.6-35B-A3B-UD-Q4_K_M`
- The gateway at `localhost:6000` is for LLMs only — does not have MCP servers
- MCP servers must be configured within OpenCode's own config

## What Needs to Be Created

### 1. `.opencode/.env`
Copy Redmine credentials from `.gemini/.env`:
```
REDMINE_URL=https://taskman.eionet.europa.eu/
REDMINE_API_KEY=f792d6c140317ec7ed1a119c1d01fba2f2d0b649
REDMINE_REQUEST_INSTRUCTIONS=/home/tibi/work/taskman/INSTRUCTIONS.md
REDMINE_ALLOWED_DIRECTORIES=/tmp,/home/tibi/tmp
```

### 2. `.opencode/config.jsonc` (project-level OpenCode config)
Add redmine MCP server to the `"mcp"` section. Format based on OpenCode's config schema:
```jsonc
{
  "mcp": {
    "redmine": {
      "type": "local",
      "command": ["uvx", "--from", "mcp-redmine==2026.01.13.152335", "--refresh-package", "mcp-redmine", "mcp-redmine"],
      "environment": {
        "REDMINE_URL": "${REDMINE_URL}",
        "REDMINE_API_KEY": "${REDMINE_API_KEY}",
        "REDMINE_REQUEST_INSTRUCTIONS": "${REDMINE_REQUEST_INSTRUCTIONS}",
        "REDMINE_ALLOWED_DIRECTORIES": "${REDMINE_ALLOWED_DIRECTORIES}"
      }
    }
  }
}
```
— Need to verify the exact `"environment"` key format OpenCode uses (vs MCP spec's `"env"`).

### 3. `bin/check-climate-adapt-opencode.sh`
New script mirroring the Gemini version but using `opencode run`:
```bash
#!/bin/bash
cd "$(dirname "$0")/.." || exit 1
source .opencode/.env
while IFS= read -r line; do PROMPT="${PROMPT}${line}"$'\n'; done < prompts/climate_adapt_check.txt
# Requires opencode to already have MCP tools loaded via config
opencode run "$PROMPT" --dangerously-skip-permissions | glow
```

### 4. Add to `Makefile` (optional)
Add target: `make check-climate-adapt-opencode`

## Remaining Uncertainty
- Exact `"environment"` key name in OpenCode MCP config (`"environment"` vs `"env"` vs `"envs"`)
- Whether OpenCode supports `"type": "local"` for MCP servers
- Whether `--dangerously-skip-permissions` is the right flag for auto-approval
- Whether prompt should be inlined or passed via `-f/--file` flag
- Whether `| glow` formatting still works with OpenCode output