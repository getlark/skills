# getlark

A Claude Code plugin for onboarding to [getlark.ai](https://getlark.ai) and managing end-to-end test workflows via the `larkci` CLI.

## Features

- **getlark-overview** — background knowledge that auto-loads when working with getlark
- **/getlark:setup** — install the `larkci` CLI and configure your API key
- **/getlark:create-workflow** — turn a natural-language test description into a workflow
- **/getlark:invoke-workflow** — run workflows and wait for results
- **/getlark:manage** — list / get / update / archive workflows, groups, secret contexts, and more
- **/getlark:validate-branch** — run workflows against the current feature branch
- **Optional hook** — automatically validate after `git commit`/`git push` when enabled

## Prerequisites

- Node.js ≥ 18
- A getlark.ai account and API key ([dashboard](https://dashboard.getlark.ai/settings/api-keys))

## Installation

Install via your Claude Code plugin marketplace, or load locally:

```bash
claude --plugin-dir /path/to/getlark-plugin
```

Then run `/getlark:setup` to install the CLI and configure credentials.

## Optional: enable the branch-validation hook

Create `.claude/getlark.local.md` at the root of any project where you want the hook active:

```yaml
---
enabled: true
# Optional: restrict to specific workflows (default: run all)
workflow_ids: []
# Optional: restrict to a workflow group
workflow_group_id: ""
# Optional: poll timeout in seconds (default: 600)
poll_timeout_seconds: 600
---
```

When enabled, the plugin runs your configured workflows after `git commit` or `git push` and reports pass/fail to Claude.

## Configuration

| Env var | Purpose | Default |
|---|---|---|
| `LARKCI_API_KEY` | API key | (required) |
| `LARKCI_API_URL` | API base URL | `https://api.getlark.ai` |
