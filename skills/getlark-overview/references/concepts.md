# getlark concepts & CLI reference

Authoritative details for the `getlark` CLI and the resources it manages. Load this file when answers require exact field names, status enums, or flag specifics.

## Global CLI options

| Flag | Env var | Default | Purpose |
|---|---|---|---|
| `--api-key <key>` | `GETLARK_API_KEY` | — (required unless using a saved profile) | API authentication |
| `--api-url <url>` | `GETLARK_API_URL` | `https://api.getlark.ai` | API base URL |
| `--profile <name>` | — | current profile in `~/.getlark/config.json` | Select a saved config profile |

Note: `LARKCI_API_KEY` and `LARKCI_API_URL` are accepted but deprecated — the CLI will print a warning to rename them.

Exit codes: `0` success · `1` failure · `2` timeout · `3` unexpected error.

## Resource: workflow

```ts
{
  id: string;                       // e.g. "wf_..."
  name: string;
  description: string;
  mode: "ai_driven" | "deterministic";
  status:
    | "active" | "pending_generation" | "generating"
    | "generation_successful" | "generation_failed"
    | "archived" | "needs_repair" | "repairing"
    | "repair_successful" | "repair_failed";
  secret_contexts: string[] | null;
  group_id: string | null;
  schedule: string | null;          // cron expression
  last_execution_id, last_execution_started_at, last_execution_stopped_at,
  last_execution_result_type: "success" | "failure" | "cancelled" | null;
  last_generation_id, last_generation_started_at, last_generation_stopped_at,
  last_generation_result_type: "success" | "failure" | "cancelled" | null;
  last_repair_id, last_repair_started_at, last_repair_stopped_at,
  last_repair_result_type: "success" | "failure" | "cancelled" | null;
  archived_at: string | null;
  next_execution_at: string | null;
  created_at, updated_at: string;
}
```

### `getlark workflows` subcommands

| Subcommand | Key flags / args |
|---|---|
| `list` | `--limit <n>` (1–100, default 10), `--offset <n>`, `--group-id <id>` |
| `get <workflow_id>` | — |
| `create` | `--name <name>` **(required)**, `--description <text>` **(required)**, `--mode <ai_driven\|deterministic>` (default `ai_driven`), `--secret-contexts <names...>`, `--group-id <id>` |
| `update <workflow_id>` | `--name`, `--description`, `--schedule`, `--secret-contexts`, `--group-id` |
| `archive <workflow_id>` / `unarchive <workflow_id>` | — |
| `invoke` | `--workflow-ids <id...>` OR `--all` OR `--group-id <id>` OR `--group-name <name>`; `--wait`, `--timeout <seconds>` (default 600), `--verbose` |

### Workflow executions (nested under `getlark workflows`)

| Subcommand | Args |
|---|---|
| `executions get <workflow_id> <execution_id>` | — |
| `executions list <workflow_id>` | paging |
| `executions logs <workflow_id> <execution_id>` | — |
| `executions cancel <workflow_id> <execution_id>` | — |

### Workflow repairs (nested)

| Subcommand | Args |
|---|---|
| `repairs list <workflow_id>` | paging |
| `repairs get <workflow_id> <repair_id>` | — |
| `repairs trigger <workflow_id>` | — |
| `repairs cancel <workflow_id> <repair_id>` | — |

### Workflow generations (nested)

| Subcommand | Args |
|---|---|
| `generations list <workflow_id>` | paging |
| `generations get <workflow_id> <generation_id>` | — |
| `generations logs <workflow_id> <generation_id>` | — |
| `generations cancel <workflow_id> <generation_id>` | — |

### Workflow events (nested)

`events <workflow_id>` — unified stream of generation/execution/repair events.

## Resource: workflow-group

```ts
{ id: string; name: string; created_at: string; updated_at: string; }
```

| Subcommand | Args |
|---|---|
| `workflow-groups list` | `--limit`, `--offset` |
| `workflow-groups get <group_id>` | — |
| `workflow-groups create` | `--name <name>` |
| `workflow-groups update <group_id>` | `--name` |
| `workflow-groups delete <group_id>` | — |

## Resource: secret-context

Stores named key/value bags. Values are write-only; `get` returns key names only.

| Subcommand | Args |
|---|---|
| `secret-contexts list` | — |
| `secret-contexts get <context>` | returns `{ context, keys: string[] }` |
| `secret-contexts create <context>` | `--key <k> --value <v>` (repeatable) |
| `secret-contexts update <context>` | `--key <k> --value <v>` (repeatable) |
| `secret-contexts delete <context>` | — |
| `secret-contexts delete-key <context>` | `--key <k>` |

## Resource: job

Long-running background operation (e.g. bulk workflow import).

```ts
{
  id: string;
  name: string;
  type: "workflow_import";
  status: "pending" | "running" | "completed" | "failed" | "cancelled";
  dashboard_url: string;
  created_at: string;
  updated_at: string;
}
```

| Subcommand | Key flags / args |
|---|---|
| `jobs list` | `--limit <n>` (default 20), `--offset <n>`, `--status <status>` (repeatable) |
| `jobs get <job_id>` | — |
| `jobs cancel <job_id>` | — |
| `jobs upload` | `--name <name>` **(required)**, `--file <path>` **(required)**, `--type <type>` (default `workflow_import`) |
| `jobs validate` | `--file <path>` **(required)**, `--type <type>` (default `workflow_import`) — validates without creating a job |
| `jobs create` | `--name <name>` **(required)**, `--input-file <path>` **(required)** — inline JSON alternative to `upload` |

`jobs upload` and `jobs validate` accept a multipart file upload. `jobs create` accepts an inline JSON body. Prefer `upload` for bulk workflow imports. Use `/getlark:manage-bulk` for the full bulk-import workflow.

## Resource: config profile

Named credential set stored in `~/.getlark/config.json`. Managed via `getlark login` / `getlark logout` / `getlark config`.

| Subcommand | Args |
|---|---|
| `login` | `--api-key <key>` (skips prompt), `--profile <name>` (default: current or `default`) |
| `logout` | `--profile <name>` (default: current profile) |
| `config list` | — lists all profiles, marks current with `*` |
| `config use <profile>` | — sets the active profile |

Config file location: `~/.getlark/config.json`. Credentials stored per profile: `api_key` (required), `api_url` (optional).

Priority order when resolving credentials: `--api-key` flag > `GETLARK_API_KEY` env > active config profile.

## Execution / generation / repair status enum

All three share the same status values:

```
pending → running → success | failure | cancelled
```

## Artifacts

Executions, generations, and repairs may include artifacts of these types:
`screenshot`, `video`, `javascript`, `python`, `shellscript`. Each has a presigned URL and expiry.

## Friction points

Execution steps may carry `friction_points[]` with a string label and a `friction_score` — use these to highlight where a test struggled even when it succeeded.
