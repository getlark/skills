---
name: create-workflow
description: This skill should be used when the user asks to "create a workflow", "create a getlark test", "add an end-to-end test", "author a larkci workflow", or runs `/getlark:create-workflow`. Converts a natural-language test description (target URL + ordered steps) into a `getlark workflows create` invocation with an auto-generated name.
allowed-tools: Bash, AskUserQuestion
argument-hint: "[description]"
---

# create-workflow

Turn a short natural-language test description into a new getlark workflow. The user supplies the description (target URL + steps). This skill derives a concise workflow name, surfaces optional settings (mode, secret contexts, group), and calls `getlark workflows create`.

## Inputs

- **Description** (required) — free-form text containing a target URL and ordered steps. Examples:
  - "Go to https://app.example.com/login, sign in with the `staging` credentials, click 'New project', confirm the modal, assert dashboard loads."
  - "https://acme.test — add item to cart, checkout as guest, verify order confirmation page."

If the user invoked `/getlark:create-workflow <text>`, treat `<text>` as the description. Otherwise ask for it.

## Procedure

### Step 1 — Collect / confirm the description

Ensure the description contains **a URL** and **at least one action step**. If either is missing, ask one targeted follow-up. Do not pad thin descriptions with invented steps — confirm with the user first.

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

Description is passed **verbatim** — getlark's generation step parses the URL and steps server-side. Do not restructure or bullet-ify it.

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
