---
name: redmine-tickets
description: Create and update Redmine tickets. Use when the user wants to create a new ticket, update an existing one, add notes, change status, or manage issues in Redmine.
tags:
  - redmine
  - tickets
  - issues
  - taskman
---

# Redmine Tickets — Create & Update

This skill covers creating and updating tickets on the Redmine instance at `https://taskman.eionet.europa.eu/`.

## Access

There are three ways to interact with Redmine:

1. **`redmine_request` tool** (preferred in pi) — registered by the extension at `pi/pi-redmine-tools.ts`. Use it directly from within pi.
2. **Redmine MCP server** — available via the `mcp-redmine` package. Provides tools for querying and managing issues. Check `.gemini/settings.json` for server configuration. Use when MCP tools are available in your environment.
3. **Direct HTTP calls** — `curl`, `fetch`, or any HTTP client. See [resources/restapi.md](resources/restapi.md) for endpoint details and examples.

## Writing ticket descriptions

When creating or updating tickets, follow these conventions:

### Describe the work, not the conversation

- State **what needs to be done** and **why**, in abstract terms.
- Present the situation objectively — describe the problem or requirement.
- Outline possible solutions or approaches if known.
- Include relevant links, sources, or references.

### What to avoid

- **Do not attribute requests to people** — never write "X asked", "the user asked", "someone requested", etc.
- **Do not quote people** — paraphrase the requirement or problem instead.
- **Do not refer to "the user"** — it feels impersonal and creates distance.
- **Do not frame the ticket as a conversation record** — it should read like a task description, not meeting minutes.

### Checklists for multi-step tickets

For complex tickets that imply multiple steps, add a checklist to outline the resolution goals. Only do this when the steps are clear — don't invent them.

**Always include updating documentation as part of the ticket tasks.** Even for simple changes, document what was done so the knowledge doesn't disappear.

Example:

> **Checklist:**
> - [ ] Identify the source pages that need redirection
> - [ ] Choose the redirection approach (delete, archive, or rename)
> - [ ] Create the redirection rules
> - [ ] Test all affected URLs
> - [ ] Update documentation

### Good vs bad examples

**Bad:**
> Based on conversation with someone:
> The user asked: "I want to add a redirection to it..."

**Good:**
> A redirection is needed to an external page: https://example.com
>
> Current sources that should redirect:
> 1. News item: https://example.com/news-item
> 2. Folder: https://example.com/folder
>
> Possible approaches:
> - Delete the page and create a redirection with the same short name/url
> - Archive the page and create a redirection with the same short name/url
> - Rename the page and create a redirection with the same short name/url

## Summary

- Describe **what** needs to be done, not **who** asked for it
- Present problems and solutions objectively
- Include all relevant links and context
- Use whichever access method is available — `redmine_request` tool, MCP server, or direct HTTP
- Keep the tone professional but warm — we're a team, not a helpdesk
