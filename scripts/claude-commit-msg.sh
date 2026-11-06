#!/usr/bin/env bash
# prepare-commit-msg hook: asks Claude Code to draft a commit message from the
# staged diff. Never blocks a commit — on any problem it exits 0 and leaves the
# message untouched.
#
# Settings (environment variables):
#   CLAUDE_COMMIT_SKIP=1         disable for one commit:  CLAUDE_COMMIT_SKIP=1 git commit
#   CLAUDE_COMMIT_MODEL          model alias (default: haiku)
#   CLAUDE_COMMIT_MAX_BYTES      max diff bytes sent to Claude (default: 60000)
#   CLAUDE_COMMIT_PROMPT_FILE    prompt file (default: .claude-commit-prompt.md)

msg_file="$1"

# Skip when a message is already supplied (-m, -F, merge, squash, amend).
[ -n "$PRE_COMMIT_COMMIT_MSG_SOURCE" ] && exit 0
[ -n "$CLAUDE_COMMIT_SKIP" ] && exit 0
# Skip in CI and when Claude Code isn't installed.
[ -n "$CI" ] && exit 0
command -v claude >/dev/null 2>&1 || exit 0

model="${CLAUDE_COMMIT_MODEL:-haiku}"
max_bytes="${CLAUDE_COMMIT_MAX_BYTES:-60000}"
repo_root="$(git rev-parse --show-toplevel)"
prompt_file="${CLAUDE_COMMIT_PROMPT_FILE:-$repo_root/.claude-commit-prompt.md}"

diff="$(git diff --cached --no-color)"
[ -z "$diff" ] && exit 0

if [ -f "$prompt_file" ]; then
  prompt="$(cat "$prompt_file")"
else
  prompt="Write a concise conventional commit message for this staged diff. Output only the message."
fi

# Always include the file summary; truncate the full diff if it's large.
input="$(
  echo "## Changed files"
  git diff --cached --stat --no-color
  echo
  echo "## Diff"
  printf '%s' "$diff" | head -c "$max_bytes"
  [ "${#diff}" -gt "$max_bytes" ] && printf '\n\n[diff truncated at %s bytes]\n' "$max_bytes"
)"

msg="$(printf '%s' "$input" | claude -p "$prompt" --model "$model" 2>/dev/null)" || exit 0

# Strip stray code fences, then trim leading/trailing blank lines.
msg="$(printf '%s\n' "$msg" | sed '/^```/d' | sed -e '/./,$!d')"
[ -z "$msg" ] && exit 0

{ printf '%s\n\n' "$msg"; cat "$msg_file"; } > "$msg_file.tmp" && mv "$msg_file.tmp" "$msg_file"
exit 0
