---
name: manage
description: This skill should be used when the user asks to "list workflows", "show getlark workflows", "get workflow details", "archive a workflow", "update a workflow", "list workflow groups", "manage secret contexts", "show executions", "show repairs", "show generations", "show events", or runs `/getlark:manage`. Covers read/update/archive operations across all getlark resources and formats CLI JSON as human-friendly tables. Use `create-workflow` to create new workflows and `invoke-workflow` (or `validate-branch`) to run them — this skill never triggers executions, it only inspects and mutates metadata.
license: MIT
compatibility: "Requires the getlark CLI (`npm install -g @getlark/cli`) and `LARKCI_API_KEY` in the environment. Run `/getlark:setup` first if either is missing."
allowed-tools: Bash, AskUserQuestion
argument-hint: "[resource] [action] [args...]"
---

# manage

Inspect and mutate getlark resources via the `getlark` CLI, then render JSON output as a readable table for the user. Applies to: workflows, workflow-groups, secret-contexts, executions, repairs, generations, and events.

## Resource/action matrix

| Resource | Actions |
|---|---|
| workflows | list, get, update, archive, unarchive |
| workflows/executions | list, get, logs, cancel |
| workflows/repairs | list, get, trigger, cancel |
| workflows/generations | list, get, logs, cancel |
| workflows/events | list |
| workflow-groups | list, get, create, update, delete |
| secret-contexts | list, get, create, update, delete, delete-key |

Creation of workflows lives in `/getlark:create-workflow`, not here. Invocation lives in `/getlark:invoke-workflow`.

## Procedure

### Step 1 — Map the user's request to a command

Examples:

| User request | Command |
|---|---|
| "list my workflows" | `getlark workflows list --limit 100` |
| "show workflow wf_abc" | `getlark workflows get wf_abc` |
| "archive that workflow" | `getlark workflows archive <id>` (confirm first) |
| "rename workflow X to Y" | `getlark workflows update <id> --name "Y"` |
| "list workflow groups" | `getlark workflow-groups list` |
| "what secrets are in the staging context" | `getlark secret-contexts get staging` |
| "show last execution of wf_abc" | `getlark workflows executions list wf_abc --limit 1` → `executions get` |
| "show repair history for wf_abc" | `getlark workflows repairs list wf_abc` |

If the user refers to a resource by name (not ID), resolve via the corresponding `list` call first.

### Step 2 — Confirm before mutating

For `archive`, `unarchive`, `update`, `delete`, `delete-key`, `cancel`, `trigger`: echo the exact command and the resource identifier and ask the user to confirm before running. Deletes and archives are user-visible and not always reversible.

`list` and `get` run without confirmation.

### Step 3 — Render JSON as a table

The CLI emits pretty-printed JSON. Convert it to a compact, human-readable table before replying to the user. Guidance per resource:

**workflows list** — columns: `id`, `name`, `status`, `mode`, `group_id`, `last_execution_result_type`, `updated_at`

**workflows get** — key/value list, highlight: `status`, `mode`, `secret_contexts`, `group_id`, `schedule`, `last_execution_*`, `last_repair_*`.

**workflow-groups list** — `id`, `name`, `updated_at`

**secret-contexts list** — `context`, `updated_at`

**secret-contexts get** — `context` + bullet list of `keys`

**executions list** — `id`, `status`, `started_at`, `stopped_at` (duration if both present)

**executions get** — highlight `status`, `summary`; list `steps[]` with `step`, `result`, and any friction_points

**repairs list / generations list / events list** — `id`, `status`, `started_at`, `stopped_at`

Drop timestamps that are null and ISO-trim to minute precision when space is tight. For long lists (>15 rows), show top N and note total.

### Step 4 — Offer the dashboard link

Include `https://dashboard.getlark.ai/workflows/<id>` (or relevant subpath) after the table so the user can click through.

## Pagination

`list` subcommands accept `--limit` (max 100) and `--offset`. If a response has `has_more: true`, offer to fetch the next page — do not auto-loop.

## Do NOT

- Do not echo raw JSON to the user; always format. If the user explicitly asks for JSON, pass it through with a code fence.
- Do not chain destructive commands without confirmation.
- Do not guess IDs — resolve via `list` first.
