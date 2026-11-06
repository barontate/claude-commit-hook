#!/usr/bin/env bash
# prepare-commit-msg hook: asks Claude Code to draft a commit message from the
# staged diff. Never blocks a commit — on any problem it exits 0 and leaves the
# message untouched.
#
# Hook args (set via `args:` in .pre-commit-config.yaml):
#   --model <alias>          model alias (default: haiku)
#   --max-bytes <n>          max diff bytes sent to Claude (default: 60000)
#   --prompt-file <path>     prompt file, relative to repo root
#                            (default: .claude-commit-prompt.md if present)
#
# Environment variables override args:
#   CLAUDE_COMMIT_SKIP=1     disable for one commit:  CLAUDE_COMMIT_SKIP=1 git commit
#   CLAUDE_COMMIT_MODEL, CLAUDE_COMMIT_MAX_BYTES, CLAUDE_COMMIT_PROMPT_FILE

model="haiku"
max_bytes="60000"
prompt_file=".claude-commit-prompt.md"

while [ $# -gt 1 ]; do
  case "$1" in
    --model) model="$2"; shift 2 ;;
    --max-bytes) max_bytes="$2"; shift 2 ;;
    --prompt-file) prompt_file="$2"; shift 2 ;;
    *) shift ;;
  esac
done
msg_file="$1"   # pre-commit passes the commit message file last

model="${CLAUDE_COMMIT_MODEL:-$model}"
max_bytes="${CLAUDE_COMMIT_MAX_BYTES:-$max_bytes}"
prompt_file="${CLAUDE_COMMIT_PROMPT_FILE:-$prompt_file}"

[ -z "$msg_file" ] && exit 0
# Skip when a message is already supplied (-m, -F, merge, squash, amend).
[ -n "$PRE_COMMIT_COMMIT_MSG_SOURCE" ] && exit 0
[ -n "$CLAUDE_COMMIT_SKIP" ] && exit 0
# Skip in CI and when Claude Code isn't installed.
[ -n "$CI" ] && exit 0
command -v claude >/dev/null 2>&1 || exit 0

repo_root="$(git rev-parse --show-toplevel)" || exit 0
case "$prompt_file" in /*) ;; *) prompt_file="$repo_root/$prompt_file" ;; esac

diff="$(git diff --cached --no-color)"
[ -z "$diff" ] && exit 0

if [ -f "$prompt_file" ]; then
  prompt="$(cat "$prompt_file")"
else
  prompt="You are writing a git commit message for the staged changes provided.
- Use Conventional Commits: type(scope): summary (feat, fix, docs, refactor, test, chore, ci, build, perf, style).
- Summary line: imperative mood, max 72 characters, no trailing full stop.
- For non-trivial changes add a blank line, then a short body wrapped at 72 chars explaining what and why. Use bullets for multiple changes.
- Do not invent context that isn't in the diff.
- Output ONLY the commit message. No preamble, no code fences."
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

# Strip stray code fences, then trim leading blank lines.
msg="$(printf '%s\n' "$msg" | sed '/^```/d' | sed -e '/./,$!d')"
[ -z "$msg" ] && exit 0

{ printf '%s\n\n' "$msg"; cat "$msg_file"; } > "$msg_file.tmp" && mv "$msg_file.tmp" "$msg_file"
exit 0
