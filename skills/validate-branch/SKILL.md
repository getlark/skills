---
name: validate-branch
description: This skill should be used when the user asks to "validate the branch", "validate this branch", "test this feature branch", "run workflows against this branch", "check if my changes broke anything", or runs `/getlark:validate-branch`. Runs configured getlark workflows against the current branch on demand. Pair with the optional PostToolUse hook for automatic validation after git commit/push. Prefer this over `invoke-workflow` whenever the intent is tied to the current git branch — it selects the right workflows automatically from `.claude/getlark.local.md`; fall back to `invoke-workflow` for ad-hoc runs unrelated to the branch, and to `create-workflow` if no workflows exist yet.
license: MIT
compatibility: "Requires the getlark CLI (`npm install -g @getlark/cli`), `LARKCI_API_KEY` in the environment, and a git working copy. Run `/getlark:setup` first if the CLI or API key is missing."
allowed-tools: Bash, Read
argument-hint: "[workflow-id | group-name]"
---

# validate-branch

Run getlark workflows to validate the work-in-progress on the current git branch, on demand. Reads optional configuration from `.claude/getlark.local.md` if present, otherwise runs **all** workflows (the sensible default for onboarding).

## Procedure

### Step 1 — Identify current branch

```bash
git rev-parse --abbrev-ref HEAD
```

Abort with a clear message if not in a git repo or HEAD is detached — unless the user explicitly opted into running anyway.

### Step 2 — Load project config (if present)

Look for `.claude/getlark.local.md` in `$CLAUDE_PROJECT_DIR` (or `pwd` fallback). If it exists, parse the YAML frontmatter:

```yaml
---
enabled: true
workflow_ids: []            # empty = all workflows
workflow_group_id: ""       # alternative to workflow_ids
poll_timeout_seconds: 600
---
```

Use Read to inspect it. Settings precedence, when multiple are set:

1. `workflow_ids` (if non-empty)
2. `workflow_group_id` (if non-empty)
3. Otherwise run `--all`

If the file is missing, default to `--all`.

### Step 3 — Override from skill argument

If the user passed an argument to `/getlark:validate-branch`:

- `wf_...` → single workflow via `--workflow-ids`
- Group name → `--group-name "<name>"`
- Any other token → ask the user to clarify

The argument wins over the config file.

### Step 4 — Invoke

Always wait for completion. Use the configured timeout or 600s default.

```bash
getlark workflows invoke --all --wait --timeout <seconds>
# or
getlark workflows invoke --workflow-ids <ids...> --wait --timeout <seconds>
# or
getlark workflows invoke --group-id <id> --wait --timeout <seconds>
```

### Step 5 — Report

Follow the same result-interpretation rules as `/getlark:invoke-workflow`:

- Exit 0 → ✅ branch passes
- Exit 1 → list failing workflows + dashboard links
- Exit 2 → timeout
- Exit 3 → unexpected error

Include the current branch name in the summary so the user sees e.g. "Branch `feature/checkout-v2` passed all 12 workflows."

## Relationship to the hook

This plugin ships an opt-in `PostToolUse` hook that runs this same validation automatically after `git commit` or `git push`. It uses the same `.claude/getlark.local.md` config. Enable it by setting `enabled: true` in that file. When disabled or missing, the hook is a no-op.

Users can always run `/getlark:validate-branch` manually regardless of hook state.

## Do NOT

- Do not guess the CLI command format; reuse the same flags as `/getlark:invoke-workflow`.
- Do not run on `main` / `master` / the repo's default branch unless the user explicitly asks (the purpose is feature-branch validation).
