# getlark skills

Agent skills for [getlark](https://getlark.ai) — author, run, and manage end-to-end browser test workflows from your coding agent.

Works with Claude Code, Cursor, Codex, OpenCode, Windsurf, Gemini CLI, Copilot, and any other agent supported by Vercel's [`skills`](https://github.com/vercel-labs/skills) ecosystem.

## Install

```bash
npx skills add getlark/skills
```

This installs the skills in the format your agent expects (Claude `SKILL.md`, Cursor rules, `AGENTS.md`, etc).

Claude Code users can alternatively install the full plugin — which includes these skills plus slash commands and hooks — from the getlark marketplace.

## Prerequisites

The skills shell out to the [`@getlark/cli`](https://www.npmjs.com/package/@getlark/cli) and expect `LARKCI_API_KEY` in your environment. If you haven't set that up yet, invoke the `setup` skill and it will walk you through it.

## Skills

| Skill              | What it does                                                                                                                                              |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `getlark-overview` | Background on getlark concepts (workflows, groups, executions, repairs, generations, secret contexts, events). Loaded when you mention getlark or larkci. |
| `setup`            | Installs `@getlark/cli` and configures `LARKCI_API_KEY` in your shell rc.                                                                                 |
| `create-workflow`  | Turns a natural-language test description into a `getlark workflows create` invocation.                                                                   |
| `invoke-workflow`  | Runs one or more workflows, waits for terminal status, reports pass/fail.                                                                                 |
| `validate-branch`  | Runs configured workflows against the current branch to check for regressions.                                                                            |
| `manage`           | Read/update/archive workflows, groups, secret contexts, executions, repairs, generations, and events.                                                     |

## Links

- Dashboard: https://dashboard.getlark.ai
- CLI: https://www.npmjs.com/package/@getlark/cli
- Claude Code plugin: https://github.com/getlark/claude-code-plugin
