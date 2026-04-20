#!/bin/bash
# PostToolUse hook for getlark plugin.
# Runs configured workflows after `git commit` or `git push` when opted-in via
# .claude/getlark.local.md at the project root.
#
# Silently no-ops when:
#   - the triggering command is not `git commit` / `git push`
#   - `.claude/getlark.local.md` is missing
#   - the config's `enabled` field is not `true`
#   - `larkci` is not on PATH

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  # Hook depends on jq to parse stdin; silently no-op if missing.
  exit 0
fi

input=$(cat)

tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty')
if [ "$tool_name" != "Bash" ]; then
  exit 0
fi

cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
# Match `git commit ...` or `git push ...` anywhere in the command string,
# including chained commands (`git add . && git commit ...`).
if ! printf '%s' "$cmd" | grep -Eq '(^|[^A-Za-z0-9_-])git[[:space:]]+(commit|push)([[:space:]]|$)'; then
  exit 0
fi

project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
config_file="$project_dir/.claude/getlark.local.md"
if [ ! -f "$config_file" ]; then
  exit 0
fi

# Extract YAML frontmatter (between the first two `---` markers).
frontmatter=$(awk '
  /^---[[:space:]]*$/ { n++; next }
  n == 1 { print }
  n >= 2 { exit }
' "$config_file")

get_field() {
  printf '%s\n' "$frontmatter" | awk -v key="$1" '
    $0 ~ "^"key"[[:space:]]*:" {
      sub("^"key"[[:space:]]*:[[:space:]]*", "")
      gsub(/^["'\'']|["'\'']$/, "")
      print
      exit
    }
  '
}

enabled=$(get_field enabled)
if [ "$enabled" != "true" ]; then
  exit 0
fi

if ! command -v larkci >/dev/null 2>&1; then
  printf '{"systemMessage":"getlark hook: `larkci` is not installed; skipping branch validation. Run /getlark:setup."}\n'
  exit 0
fi

workflow_group_id=$(get_field workflow_group_id)
poll_timeout=$(get_field poll_timeout_seconds)
poll_timeout=${poll_timeout:-600}

# workflow_ids is a YAML list; pull non-empty quoted/bare tokens from the matching line.
workflow_ids_raw=$(printf '%s\n' "$frontmatter" | awk '
  /^workflow_ids[[:space:]]*:/ {
    sub("^workflow_ids[[:space:]]*:[[:space:]]*", "")
    print
    exit
  }
')
# Strip surrounding brackets and split by commas.
workflow_ids=$(printf '%s' "$workflow_ids_raw" | sed -E 's/^\[[[:space:]]*//; s/[[:space:]]*\]$//; s/[",]/ /g' | xargs || true)

branch=$(git -C "$project_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

set +e
if [ -n "$workflow_ids" ]; then
  # shellcheck disable=SC2086
  output=$(larkci workflows invoke --workflow-ids $workflow_ids --wait --timeout "$poll_timeout" 2>&1)
elif [ -n "$workflow_group_id" ]; then
  output=$(larkci workflows invoke --group-id "$workflow_group_id" --wait --timeout "$poll_timeout" 2>&1)
else
  output=$(larkci workflows invoke --all --wait --timeout "$poll_timeout" 2>&1)
fi
rc=$?
set -e

# Escape for JSON.
message=$(printf 'getlark branch validation (%s) exit=%s\n%s' "$branch" "$rc" "$output" | jq -Rs .)

if [ "$rc" -eq 0 ]; then
  printf '{"systemMessage":%s}\n' "$message"
  exit 0
else
  # Non-zero rc: surface output to Claude as a blocking message.
  printf '%s\n' "$output" >&2
  exit 2
fi
