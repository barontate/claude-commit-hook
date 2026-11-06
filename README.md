# claude-commit-hook

A [pre-commit](https://pre-commit.com) hook where
[Claude Code](https://docs.claude.com/en/docs/claude-code) drafts your commit
message from the staged diff. Your editor opens with the draft pre-filled, so
you can edit or accept it.

## Requirements

- `pre-commit` 3.2 or later
- Claude Code CLI installed, on your `PATH`, and logged in (`claude` works in a terminal)
- On Windows, Git for Windows, which provides the bash the hook runs in

## Usage

Add this to your project's `.pre-commit-config.yaml`:

```yaml
default_install_hook_types: [pre-commit, prepare-commit-msg]

repos:
  - repo: https://github.com/barontate/claude-commit-hook
    rev: v1.0.0
    hooks:
      - id: claude-commit-msg
        # Optional:
        # args: [--model, sonnet, --max-bytes, "100000"]
```

Then run:

```bash
pre-commit install
```

Now `git commit` (without `-m`) opens your editor with Claude's draft.
Run `pre-commit autoupdate` to pick up new versions of the hook.

## How it works

The hook runs at the `prepare-commit-msg` stage. It sends the staged diff, plus
a `--stat` summary, to `claude -p` and writes the result into the commit
message file.

It is skipped automatically when:

- you pass a message yourself (`-m`, `-F`), or the commit is a merge, squash or amend
- `CI` is set, or `claude` isn't installed
- nothing is staged

It always exits 0, so a Claude failure never blocks a commit.

## Customising

| What | Hook `args` | Env var (overrides args) | Default |
|---|---|---|---|
| Model | `--model sonnet` | `CLAUDE_COMMIT_MODEL` | `haiku` |
| Diff size cap | `--max-bytes 100000` | `CLAUDE_COMMIT_MAX_BYTES` | `60000` |
| Prompt file | `--prompt-file path.md` | `CLAUDE_COMMIT_PROMPT_FILE` | `.claude-commit-prompt.md` |
| Skip once | — | `CLAUDE_COMMIT_SKIP=1` | — |

To change the message style for one project, add `.claude-commit-prompt.md` to
the root of that project. If the file isn't there, the hook uses a built-in
Conventional Commits prompt. See this repo's `.claude-commit-prompt.md` for an
example.
