# Taskman Integrations

A collection of automation tools and scripts designed to streamline workflows with **EEA Taskman** (a hosted Redmine instance). This project supports multiple AI agents, each with its own configuration and tooling.

## 🚀 Overview

The primary goal of this repository is to provide a central place for scripts that interact with Taskman issues autonomously. By using structured prompts and AI agents, we can perform complex queries and receive summarized insights that would otherwise require significant manual effort.

## 🛠 Agents & Tools

This project supports **three AI agents**, each with its own setup:

| Agent | CLI | Integration | Config Dir |
|-------|-----|-------------|------------|
| **Gemini** | `gemini` | MCP server (`mcp-redmine`) | `.gemini/` |
| **OpenCode** | `opencode` | MCP server (`mcp-redmine`) | `.opencode/` |
| **pi** | `pi` | TypeScript extension | `pi/` |

All agents share the same prompt file in `prompts/` and the same Redmine credentials (stored per-agent).

## 🛠 Features

- **Automated Issue Tracking**: Scripts to identify urgent issues and recent activity.
- **Multi-Agent Support**: Run the same analysis via Gemini, OpenCode, or pi.
- **Rich Visuals**: Formats output using `glow` for a clean terminal experience.
- **Extensible Prompt System**: Manage your AI instructions in the `prompts/` directory.

## 📋 Prerequisites

### Common
- **[glow](https://github.com/charmbracelet/glow)**: For rendering Markdown in the terminal.
- **Taskman Access**: A valid Redmine API key and URL.

### Per-Agent
- **Gemini**: Install [Gemini CLI](https://github.com/google/gemini-cli) and configure MCP in `.gemini/settings.json`.
- **OpenCode**: Install [OpenCode](https://github.com/stntnguyen/opencode) and configure MCP in `.opencode/config.jsonc`.
- **pi**: Install [pi](https://github.com/mariozechner/pi-coding-agent) — the extension in `pi/` is loaded automatically via `--extension`.

## ⚙️ Setup

### 1. Redmine Credentials (per-agent)

Each agent stores its own credentials in its config directory:

**Gemini** (`.gemini/.env`):
```bash
REDMINE_URL=https://taskman.eionet.europa.eu
REDMINE_API_KEY=your_api_key_here
```

**OpenCode** (`.opencode/.env`):
```bash
REDMINE_URL=https://taskman.eionet.europa.eu
REDMINE_API_KEY=your_api_key_here
```

### 2. Agent-Specific Configuration

- **Gemini**: Ensure `.gemini/settings.json` references the `mcp-redmine` server.
- **OpenCode**: Ensure `.opencode/config.jsonc` references the `mcp-redmine` server.
- **pi**: No additional config needed — the extension is loaded via `--extension`.

## 📖 Usage

We use a `Makefile` to simplify command execution.

### Check Climate-ADAPT Issues

Get a summary of Climate-ADAPT project issues requiring immediate attention, using your preferred agent:

```bash
# Gemini (MCP via mcp-redmine)
make check-climate-adapt

# OpenCode (MCP via mcp-redmine)
make check-climate-adapt-opencode

# pi (TypeScript extension)
make check-climate-adapt-pi
```

### Check GenAI - AI Hub Issues

Get a summary of GenAI - AI Hub project issues requiring immediate attention, using your preferred agent:

```bash
# Gemini (MCP via mcp-redmine)
make check-genai-ai-hub

# OpenCode (MCP via mcp-redmine)
make check-genai-ai-hub-opencode

# pi (TypeScript extension)
make check-genai-ai-hub-pi
```

## 📁 Project Structure

```
taskman/
├── bin/                    # Thin shell wrappers (scripts only)
│   ├── check-climate-adapt.sh          # Gemini variant
│   ├── check-climate-adapt-opencode.sh # OpenCode variant
│   ├── check-climate-adapt-pi.sh       # pi variant
│   ├── check-genai-ai-hub.sh           # Gemini variant
│   ├── check-genai-ai-hub-opencode.sh  # OpenCode variant
│   └── check-genai-ai-hub-pi.sh        # pi variant
├── pi/                     # pi-specific code
│   ├── pi-redmine-tools.ts   # Pi extension (Redmine API tools)
│   └── redmine_openapi.yml   # OpenAPI spec (for endpoint discovery)
├── .gemini/                # Gemini-specific config
│   ├── .env
│   ├── settings.json
│   └── styles/
├── .opencode/              # OpenCode-specific config
│   ├── .env
│   ├── config.jsonc
│   └── package.json
├── prompts/                # Shared prompts
│   ├── climate_adapt_check.txt
│   └── genai_ai_hub_check.txt
└── mcp-redmine/            # Standalone MCP server (Python)
```

- **`bin/`**: Executable bash scripts — thin wrappers that source credentials and invoke the CLI.
- **`pi/`**: Pi-specific code. The extension (`pi-redmine-tools.ts`) registers custom Redmine API tools, and `redmine_openapi.yml` provides endpoint discovery.
- **`prompts/`**: Shared prompt files used by all agents.
- **`mcp-redmine/`**: Standalone MCP server (Python) used by Gemini and OpenCode.

## 🤝 Project Context

This project is maintained by **Tiberiu Ichim**, Team Leader for the **Climate-ADAPT** and **GenAI - AI Hub** projects. The tools are optimized to support both workflows but can be adapted for any Redmine-based project.
