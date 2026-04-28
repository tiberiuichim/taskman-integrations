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
3. **Direct HTTP calls** — `curl`, `fetch`, or any HTTP client against `https://taskman.eionet.europa.eu/`. Authenticate with header `X-Redmine-API-Key`.

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

## Creating a ticket

POST to `/issues.json`:

```bash
curl -s -X POST \
  -H "X-Redmine-API-Key: $REDMINE_API_KEY" \
  -H "Content-Type: application/json" \
  "https://taskman.eionet.europa.eu/issues.json" \
  -d '{
    "issue": {
      "project_id": 188,
      "tracker_id": 4,
      "subject": "Short clear title of the task",
      "description": "Description of what needs to be done...",
      "status_id": 1,
      "assigned_to": { "id": 263 }
    }
  }'
```

### Common IDs

| ID | Name |
|---|---|
| Project 188 | Climate-Adapt Mission Portal |
| Tracker 4 | Task |
| Status 1 | New |
| User 263 | Team lead |

To discover other IDs, query:
- `/projects.json` — list projects
- `/issues/ISSUE_ID.json` — get issue details including available status options

## Updating a ticket

PUT to `/issues/ISSUE_ID.json`:

```bash
curl -s -X PUT \
  -H "X-Redmine-API-Key: $REDMINE_API_KEY" \
  -H "Content-Type: application/json" \
  "https://taskman.eionet.europa.eu/issues/ISSUE_ID.json" \
  -d '{
    "issue": {
      "description": "Updated description...",
      "status_id": 5
    }
  }'
```

Only send the fields that need changing — omitted fields are left untouched.

## Adding a note/comment

Add a note without changing the description by including `notes` in a journal entry. This is done via a PUT to the issue with only the note text:

```bash
curl -s -X PUT \
  -H "X-Redmine-API-Key: $REDMINE_API_KEY" \
  -H "Content-Type: application/json" \
  "https://taskman.eionet.europa.eu/issues/ISSUE_ID.json" \
  -d '{"issue": {"notes": "Comment text here"}}'
```

## Reading a ticket

```bash
curl -s -H "X-Redmine-API-Key: $REDMINE_API_KEY" \
  "https://taskman.eionet.europa.eu/issues/ISSUE_ID.json"
```

## Using the redmine_request tool (in pi)

When working inside pi, the `redmine_request` tool is available:

```
redmine_request(path="/issues/302928.json", method="get")
redmine_request(path="/issues.json", method="post", data={"issue": {"subject": "...", "description": "...", ...}})
redmine_request(path="/issues/302928.json", method="put", data={"issue": {"description": "..."}})
```

## Summary

- Describe **what** needs to be done, not **who** asked for it
- Present problems and solutions objectively
- Include all relevant links and context
- Use whichever access method is available — `redmine_request` tool, MCP server, or direct HTTP
- Keep the tone professional but warm — we're a team, not a helpdesk
