---
name: setup
description: This skill should be used when the user asks to "set up getlark", "install larkci", "install the getlark CLI", "configure LARKCI_API_KEY", "authenticate with getlark", or runs `/getlark:setup`. Walks the user through installing @getlark/cli and exporting LARKCI_API_KEY in their shell rc. One-time per machine — skip if `getlark --version` already works and `LARKCI_API_KEY` is already set; defer to the action skills (`create-workflow`, `invoke-workflow`, `manage`, `validate-branch`) in that case.
license: MIT
compatibility: "Requires Node.js ≥18 and npm on PATH. Writes to the user's shell rc file (`~/.zshrc` or `~/.bashrc`) to persist `LARKCI_API_KEY`."
allowed-tools: Bash, Read, Edit, Write
argument-hint: "[api-key]"
---

# setup

Install the `getlark` CLI globally via npm and configure `LARKCI_API_KEY` so subsequent getlark commands work without extra flags. Run this once per machine.

## Inputs

- Optional argument: an API key. If the user passed one with `/getlark:setup <key>`, use it directly. Otherwise direct them to the dashboard to generate one.

## Procedure

### Step 1 — Verify prerequisites

Run in parallel:

- `node --version` (must be ≥ 18)
- `npm --version`
- `command -v getlark || echo "not installed"`

Report findings in one line. If Node is < 18 or missing, stop and tell the user to install Node 18+ first.

### Step 2 — Install the CLI

If `getlark` is not on `PATH`:

```bash
npm install -g @getlark/cli
```

The package `@getlark/cli` installs a binary called **`getlark`** (not `larkci`).

If `getlark` is already installed, run `getlark --version` and ask if the user wants to upgrade (`npm update -g @getlark/cli`). Do not upgrade without confirmation.

Verify the install:

```bash
getlark --version
```

### Step 3 — Obtain an API key

If the user did not provide a key:

> Open https://dashboard.getlark.ai/settings/api-keys, create a new key, and paste it here.

Wait for the user to paste. Never echo the full key back — truncate to `sk_...abcd` when confirming.

### Step 4 — Persist the key in shell rc

Detect the user's shell:

```bash
echo "$SHELL"
```

Map to rc file:

- `/bin/zsh` or `/usr/bin/zsh` → `~/.zshrc`
- `/bin/bash` → `~/.bashrc` on Linux, `~/.bash_profile` on macOS
- `/usr/bin/fish` → `~/.config/fish/config.fish`

Check whether `LARKCI_API_KEY` is already exported in that file before appending. If not, append:

```bash
# For bash/zsh:
echo '\nexport LARKCI_API_KEY="<KEY>"' >> ~/.zshrc

# For fish:
echo '\nset -gx LARKCI_API_KEY "<KEY>"' >> ~/.config/fish/config.fish
```

Use the Edit or Write tool rather than `echo` when possible, so the diff is visible. Never commit or stage rc files.

Tell the user to either `source` the rc file or open a new shell. Do NOT run `source` inside the Bash tool — it will not affect the user's interactive shell.

### Step 5 — (Optional) Set a custom API URL

Only if the user mentions staging / self-hosted:

```bash
export LARKCI_API_URL="https://<host>"
```

Default (`https://api.getlark.ai`) covers all production users.

### Step 6 — Smoke test

After the user confirms they've reloaded their shell, run:

```bash
getlark workflows list --limit 1
```

A JSON response with a `workflows` array (possibly empty) confirms setup. A `401`/`403` means the key is wrong; a network error means `LARKCI_API_URL` is wrong.

## Success criteria

- `getlark --version` prints a version
- `LARKCI_API_KEY` is present in the user's shell rc
- `getlark workflows list --limit 1` returns a JSON response

## Recovery

- **Command not found after install**: check `npm bin -g` is on `PATH`; suggest `export PATH="$(npm bin -g):$PATH"` or reinstalling with `sudo` on Linux.
- **401 Unauthorized**: the pasted key is wrong; send the user back to https://dashboard.getlark.ai/settings/api-keys.
- **ENOTFOUND / network error**: confirm they're not behind a proxy that blocks `api.getlark.ai`.
