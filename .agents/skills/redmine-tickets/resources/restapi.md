# Redmine REST API Reference

Base URL: `https://taskman.eionet.europa.eu/`

Authenticate with header `X-Redmine-API-Key`.

## Common IDs

| ID | Name |
|---|---|
| Project 188 | Climate-Adapt Mission Portal |
| Tracker 4 | Task |
| Status 1 | New |
| User 263 | Team lead |

To discover other IDs, query:
- `/projects.json` — list projects
- `/issues/ISSUE_ID.json` — get issue details including available status options

## Reading a ticket

```bash
curl -s -H "X-Redmine-API-Key: $REDMINE_API_KEY" \
  "https://taskman.eionet.europa.eu/issues/ISSUE_ID.json"
```

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

Add a note without changing the description:

```bash
curl -s -X PUT \
  -H "X-Redmine-API-Key: $REDMINE_API_KEY" \
  -H "Content-Type: application/json" \
  "https://taskman.eionet.europa.eu/issues/ISSUE_ID.json" \
  -d '{"issue": {"notes": "Comment text here"}}'
```

## Using the redmine_request tool (in pi)

When working inside pi, the `redmine_request` tool is available:

```
redmine_request(path="/issues/302928.json", method="get")
redmine_request(path="/issues.json", method="post", data={"issue": {"subject": "...", "description": "...", ...}})
redmine_request(path="/issues/302928.json", method="put", data={"issue": {"description": "..."}})
```
