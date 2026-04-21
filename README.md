# getlark skills

Agent skills for [getlark](https://getlark.ai) — author, run, and manage end-to-end test workflows from your coding agent.

Works with Claude Code (as a full plugin with slash commands and hooks), plus Cursor, Codex, OpenCode, Windsurf, Gemini CLI, Copilot, and any other agent supported by Vercel's [`skills`](https://github.com/vercel-labs/skills) ecosystem.

## Install

### Claude Code

```
/plugin marketplace add getlark/skills
/plugin install getlark
```

This installs the skills plus the optional `git commit`/`git push` validation hook. Then run `/getlark:setup` to install the CLI and configure credentials.

### Other agents

```bash
npx skills add getlark/skills
```

This installs the skills in the format your agent expects (Claude `SKILL.md`, Cursor rules, `AGENTS.md`, etc). Invoke the `setup` skill afterwards to install `@getlark/cli` and set `LARKCI_API_KEY`.

## Prerequisites

- Node.js ≥ 18
- A getlark.ai account and API key ([dashboard](https://dashboard.getlark.ai/settings/api-keys))

The skills shell out to [`@getlark/cli`](https://www.npmjs.com/package/@getlark/cli) and expect `LARKCI_API_KEY` in your environment — `setup` handles both.

## Skills

| Skill              | What it does                                                                                                                                              |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `getlark-overview` | Background on getlark concepts (workflows, groups, executions, repairs, generations, secret contexts, events). Loaded when you mention getlark or larkci. |
| `setup`            | Installs `@getlark/cli` and configures `LARKCI_API_KEY` in your shell rc.                                                                                 |
| `create-workflow`  | Turns a natural-language test description into a `getlark workflows create` invocation.                                                                   |
| `invoke-workflow`  | Runs one or more workflows, waits for terminal status, reports pass/fail.                                                                                 |
| `validate-branch`  | Runs configured workflows against the current branch to check for regressions.                                                                            |
| `manage`           | Read/update/archive workflows, groups, secret contexts, executions, repairs, generations, and events.                                                     |

## Optional: Claude Code branch-validation hook

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

| Env var           | Purpose       | Default                    |
| ----------------- | ------------- | -------------------------- |
| `LARKCI_API_KEY`  | API key       | (required)                 |
| `LARKCI_API_URL`  | API base URL  | `https://api.getlark.ai`   |

## Links

- Dashboard: https://dashboard.getlark.ai
- CLI: https://www.npmjs.com/package/@getlark/cli
