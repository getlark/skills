---
name: invoke-workflow
description: This skill should be used when the user asks to "run a workflow", "invoke a larkci workflow", "run getlark tests", "trigger a test", "run all workflows", or runs `/getlark:invoke-workflow`. Invokes one or more getlark workflows, waits for terminal status, and reports pass/fail summaries. Prefer `validate-branch` when the user wants to gate a git branch (it picks the right workflows automatically); use `manage` to inspect past executions without kicking off a new run; use `create-workflow` first if no workflow exists yet.
license: MIT
compatibility: "Requires the getlark CLI (`npm install -g @getlark/cli`) and `LARKCI_API_KEY` in the environment. Run `/getlark:setup` first if either is missing."
allowed-tools: Bash, AskUserQuestion
argument-hint: "[workflow-id | --all | --group <name>]"
---

# invoke-workflow

Run one or more getlark workflows and wait for completion, then report results. Default behavior is **invoke + poll** — the user gets a verdict, not just an execution ID.

## Inputs

Accept any of:

- A specific workflow ID (`wf_...`)
- A workflow name (resolve to ID via `getlark workflows list`)
- A workflow group ID or group name
- `--all` / "all" to run everything

If the user ran `/getlark:invoke-workflow <arg>`, parse `<arg>` accordingly. Otherwise ask.

## Procedure

### Step 1 — Resolve target(s)

Based on input shape:

| Input | Resolution |
|---|---|
| Starts with `wf_` | Use directly as `--workflow-ids` |
| Looks like a name | `getlark workflows list --limit 100`, find match by `name`, use its `id`. If multiple match, ask. |
| Group ID (`wfl_grp_*` or similar) | Use `--group-id` |
| Group name | Use `--group-name "<name>"` |
| `all` / `--all` / unspecified + user said "everything" | Use `--all` |

### Step 2 — Invoke with wait

Always pass `--wait` by default. Set a timeout that matches the expected run time; `--timeout 600` (10 min) is a reasonable default for a single workflow, scale up for `--all` or large groups.

```bash
getlark workflows invoke \
  --workflow-ids <id> \
  --wait \
  --timeout 600
```

Or for multiple:
```bash
getlark workflows invoke --all --wait --timeout 1800
```

If the user explicitly says "don't wait" / "fire and forget", drop `--wait`.

### Step 3 — Interpret exit code & output

| Exit | Meaning | Action |
|---|---|---|
| 0 | All invoked workflows succeeded | Report ✅ with execution IDs |
| 1 | One or more workflows failed | List failing workflow IDs + their summaries |
| 2 | Timed out | Tell the user, offer to extend `--timeout` or check via `/getlark:manage` |
| 3 | Unexpected error | Surface stderr verbatim |

The CLI prints one line per workflow:

- Success: `Workflow <id> executed successfully. Execution ID: <exec_id>`
- Failure: `Workflow <id> executed with failure. Execution ID: <exec_id>. Summary: <summary>`
- Cancelled: `Workflow <id> was cancelled. Execution ID: <exec_id>`

Parse these lines into a concise report for the user.

### Step 4 — On failure: offer debug actions (do not auto-run)

If any workflow failed, offer — do not auto-execute — follow-ups:

- "Run `getlark workflows executions get <wf_id> <exec_id>` to see step-by-step details?"
- "Fetch logs with `getlark workflows executions logs <wf_id> <exec_id>`?"
- "Trigger a repair with `getlark workflows repairs trigger <wf_id>`?"

Wait for user confirmation before running any of these.

## Dashboard links

For any execution, surface: `https://dashboard.getlark.ai/workflows/<wf_id>/executions/<exec_id>`

## Examples

**Single workflow by ID:**
```bash
getlark workflows invoke --workflow-ids wf_abc123 --wait
```

**Group by name:**
```bash
getlark workflows invoke --group-name "Checkout Flow" --wait --timeout 1800
```

**Everything:**
```bash
getlark workflows invoke --all --wait --timeout 3600
```

## Do NOT

- Do not silently swallow a non-zero exit code.
- Do not invent execution or workflow IDs — derive them only from CLI output or prior `list`/`get` calls.
- Do not automatically fetch repairs/logs/generations on failure — offer first.
