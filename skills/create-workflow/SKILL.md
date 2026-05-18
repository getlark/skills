---
name: create-workflow
description: This skill should be used when the user asks to "create a workflow", "create a getlark test", "add an end-to-end test", "author a larkci workflow", or runs `/getlark:create-workflow`. Converts a natural-language test description (target + ordered steps; target may be a URL, API endpoint, CLI binary, script, or any other software surface) into a `getlark workflows create` invocation with an auto-generated name. Prefer `manage` when the user wants to update or archive an existing workflow, and `invoke-workflow` when they want to run one — this skill only *creates* new workflows.
license: MIT
compatibility: "Requires the getlark CLI (`npm install -g @getlark/cli`) and `GETLARK_API_KEY` in the environment (or a saved profile via `getlark login`). Run `/getlark:setup` first if either is missing."
allowed-tools: Bash, AskUserQuestion
argument-hint: "[description]"
---

# create-workflow

Turn a short natural-language test description into a new getlark workflow. The user supplies the description (target + steps). This skill derives a concise workflow name, surfaces optional settings (mode, secret contexts, group), and calls `getlark workflows create`.

getlark workflows can test any surface — web UIs, HTTP/GraphQL APIs, CLIs, shell scripts, data pipelines, or mixed flows. Do not assume the target is a browser URL.

## Inputs

- **Description** (required) — free-form text containing a target (URL, API base, CLI binary, script path, etc.) and ordered steps. Examples:
  - Browser: "Go to https://app.example.com/login, sign in with the `staging` credentials, click 'New project', confirm the modal, assert dashboard loads."
  - API: "POST https://api.acme.test/v1/orders with `staging_api` creds and a sample cart payload, assert 201 and that the response `order.status` is `pending`."
  - CLI: "Run `mytool import ./fixtures/sample.csv --dry-run`, assert exit code 0 and stdout contains `3 rows parsed`."

If the user invoked `/getlark:create-workflow <text>`, treat `<text>` as the description. Otherwise ask for it.

## Procedure

### Step 1 — Collect / confirm the description

Ensure the description contains **a target** (URL, API endpoint, CLI command, script path, etc.) and **at least one action step**. If either is missing, ask one targeted follow-up. Do not pad thin descriptions with invented steps — confirm with the user first.

### Step 2 — Derive a name

Generate a short, Title-Case name (3–6 words) that captures the intent. Heuristic:

- Start from the primary verb + object in the description ("Sign In Flow", "Guest Checkout", "Create New Project").
- Keep under ~50 characters.
- Avoid URL fragments, credentials, or timestamps.

Show the derived name to the user before creating. Offer to accept or override.

### Step 3 — Ask about optional fields (only if relevant)

Ask only the questions that matter for this workflow. Skip the rest.

- **Mode** — default `ai_driven`. Only ask if the user mentioned "deterministic", "scripted", "locked", or similar.
- **Secret contexts** — ask if the description references credentials, API tokens, or anything named in quotes that looks like a context (e.g., "the `staging` credentials"). Offer to list existing contexts via `getlark secret-contexts list`.
- **Group** — ask if the user has mentioned organizing tests, or if `getlark workflow-groups list` has existing groups. Otherwise skip.

Use AskUserQuestion for a single batched prompt when more than one optional field is in play.

### Step 4 — Invoke the CLI

Build the command with properly quoted arguments:

```bash
getlark workflows create \
  --name "<derived name>" \
  --description "<full description>" \
  [--mode deterministic] \
  [--secret-contexts name1 name2] \
  [--group-id <id>]
```

Description is passed **verbatim** — getlark's generation step parses the target and steps server-side. Do not restructure or bullet-ify it.

Note: `--secret-contexts` takes space-separated values (variadic), not comma-separated.

### Step 5 — Report result

The CLI prints the new workflow JSON to stdout. Extract and report:

- Workflow `id`
- `status` (will typically be `pending_generation` initially)
- Link: `https://dashboard.getlark.ai/workflows/<id>`

Tell the user the workflow is now queued for generation and suggest they run `/getlark:invoke-workflow` once the workflow status reaches `active` (or `generation_successful`). They can check status via `getlark workflows get <id>`.

## Failure modes

- **`--name` or `--description` missing**: the CLI hard-errors. This skill must always supply both.
- **Unknown `--group-id`**: verify with `getlark workflow-groups list` before passing.
- **Unknown `--secret-contexts` name**: verify with `getlark secret-contexts list`. The API will reject unknown contexts.

## Example

User says: `/getlark:create-workflow Go to https://app.example.com/signup, fill the form with a new email, submit, verify confirmation email message appears.`

Derive: name = "Signup Flow Confirmation"

Run:
```bash
getlark workflows create \
  --name "Signup Flow Confirmation" \
  --description "Go to https://app.example.com/signup, fill the form with a new email, submit, verify confirmation email message appears."
```

Report id + dashboard link.
