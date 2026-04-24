# Taskman Integrations

A collection of automation tools and scripts designed to streamline workflows with **EEA Taskman** (a hosted Redmine instance). This project leverages the **Gemini CLI** and the **Redmine MCP server** to automate task analysis, reporting, and management.

## 🚀 Overview

The primary goal of this repository is to provide a central place for scripts that interact with Taskman issues autonomously. By using structured prompts and AI agents, we can perform complex queries and receive summarized insights that would otherwise require significant manual effort.

## 🛠 Features

- **Automated Issue Tracking**: Scripts to identify urgent issues and recent activity.
- **AI-Powered Analysis**: Uses Gemini CLI to interpret Redmine data.
- **MCP Integration**: Seamlessly connects to Taskman via the Model Context Protocol (MCP).
- **Extensible Prompt System**: Manage your AI instructions in the `prompts/` directory.

## 📋 Prerequisites

To use these tools, you need:

1.  **[Gemini CLI](https://github.com/google/gemini-cli)**: The core command-line tool.
2.  **Redmine MCP Server**: Configured in `.gemini/settings.json`.
3.  **Taskman Access**: A valid Redmine API key and URL.

## ⚙️ Setup

1.  **Environment Variables**: Create a `.env` file in the root directory (ignored by git) and add your credentials:
    ```bash
    REDMINE_URL=https://taskman.eionet.europa.eu
    REDMINE_API_KEY=your_api_key_here
    ```

2.  **Configuration**: Ensure your `.gemini/settings.json` is pointing to the `mcp-redmine` server.

## 📖 Usage

We use a `Makefile` to simplify command execution.

### Check Climate-ADAPT Issues
To get a summary of Climate-ADAPT project issues requiring immediate attention:
```bash
make check-climate-adapt
```

## 📁 Project Structure

- `bin/`: Executable bash scripts that wrap Gemini CLI calls.
- `prompts/`: Text files containing the instructions (prompts) for the AI agent.
- `Makefile`: Convenient entry points for various automation tasks.
- `.gemini/`: Project-specific configuration for Gemini CLI and MCP servers.

## 🤝 Project Context

This project is maintained by **Tiberiu Ichim**, Team Leader for the **Climate-ADAPT** project. The tools are optimized to support Climate-ADAPT workflows but can be adapted for any Redmine-based project.

---
*Generated with ❤️ by Gemini CLI*
