---
name: getlark-overview
description: This skill should be used when the user mentions "getlark", "getlark.ai", "larkci", "larkci CLI", "end-to-end test workflow", or asks about authoring, running, or debugging automated browser tests on the getlark platform. Provides background on getlark concepts (workflows, workflow groups, executions, repairs, generations, secret contexts, events) and points to the other plugin skills for actions.
---

# getlark-overview

Provide accurate context about the getlark.ai platform and the `getlark` CLI so that code generation, command suggestions, and test authoring align with the real system. Do not invent fields, flags, or resource types — consult `references/concepts.md` when details are needed.

## What getlark is

getlark.ai is a platform for authoring and running end-to-end browser tests. Tests are called **workflows**. Users describe a workflow in natural language (target URL + steps); getlark generates an executable test, runs it on demand or on schedule, and auto-repairs when the app under test changes.

The `getlark` CLI (`npm i -g @getlark/cli`) is the primary programmatic surface. It wraps the getlark HTTP API with `X-API-Key` auth. All output is JSON.

## Core resources

- **workflow** — a single end-to-end test. Modes: `ai_driven` (default) or `deterministic`. Status moves through `pending_generation` → `generating` → `active` (or `needs_repair`, `archived`).
- **workflow-group** — organizational grouping of workflows. Useful for running "all checkout tests" at once.
- **execution** — one run of a workflow. Status: `pending`/`running`/`success`/`failure`/`cancelled`.
- **generation** — creating the runnable test artifact from the description.
- **repair** — auto-fixing a workflow after the underlying UI changed.
- **secret-context** — named bag of credentials (keys + values) that a workflow can reference for auth, API keys, etc.
- **event** — unified log entry across generation/execution/repair for a workflow.

Detailed field definitions and status values are in `references/concepts.md`.

## CLI surface

Top-level groups:

```
getlark workflows { list | get | create | update | archive | unarchive | invoke
                   | executions | repairs | generations | events }
getlark workflow-groups { list | get | create | update | delete }
getlark secret-contexts { list | get | create | update | delete | delete-key }
```

Global flags: `--api-key <key>` (or `LARKCI_API_KEY` env), `--api-url <url>` (or `LARKCI_API_URL` env; defaults to `https://api.getlark.ai`).

Exit codes: `0` success, `1` failure, `2` timeout, `3` unexpected error.

## Routing to the right skill

When the user expresses one of these intents, defer to (or suggest running) the corresponding skill:

| Intent | Skill |
|---|---|
| Install/configure CLI, set API key | `/getlark:setup` |
| Author a new end-to-end test | `/getlark:create-workflow` |
| Run a workflow, wait for result | `/getlark:invoke-workflow` |
| List/inspect/update/archive resources | `/getlark:manage` |
| Test the current feature branch | `/getlark:validate-branch` |

## When to load `references/concepts.md`

Load the reference when answering a question that requires specific field names, status enums, CLI flag specifics, or API response shape — not for general "what is getlark?" questions.

## Writing tests (key guidance)

- A workflow description should include the **target URL** and **ordered steps**. It does not have to be verbose — getlark's generation step fleshes out the runnable test.
- Credentials or tokens referenced by steps must live in a **secret context**, not the description itself. Attach via `--secret-contexts <names...>` at creation.
- Workflows in `ai_driven` mode tolerate minor UI changes; `deterministic` mode locks behavior to a generated script. Use `ai_driven` unless the user explicitly wants lock-in.

## Do NOT

- Do not guess workflow IDs, group IDs, or execution IDs — query them first via `/getlark:manage` or `getlark workflows list`.
- Do not put secrets in workflow descriptions. Route them through `secret-contexts`.
- Do not fabricate CLI flags. If unsure, run `getlark <cmd> --help` or consult `references/concepts.md`.
