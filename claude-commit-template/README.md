# claude-commit-template

A GitHub template repo with a [pre-commit](https://pre-commit.com) setup where
[Claude Code](https://docs.claude.com/en/docs/claude-code) drafts your commit
message from the staged diff. Your editor opens with the draft pre-filled, so
you can edit or accept it.

## Requirements

- `pre-commit` (`pipx install pre-commit` or `pip install pre-commit`)
- Claude Code CLI installed, on your `PATH`, and logged in (`claude` works in a terminal)

## Setup (after creating a repo from this template)

```bash
pre-commit install --hook-type pre-commit --hook-type prepare-commit-msg
```

Then just `git commit` (no `-m`) and the draft appears in your editor.

## How it works

`scripts/claude-commit-msg.sh` runs at the `prepare-commit-msg` stage. It sends
the staged diff (plus a `--stat` summary) to `claude -p` and writes the result
into the commit message file.

It is skipped automatically when:

- you pass a message yourself (`-m`, `-F`), or it's a merge, squash or amend
- `CI` is set, or `claude` isn't installed
- nothing is staged

It always exits 0, so a Claude failure never blocks a commit.

## Customising

| What | How |
|---|---|
| Message style | Edit `.claude-commit-prompt.md` |
| Model | `CLAUDE_COMMIT_MODEL=sonnet` (default `haiku`) |
| Diff size cap | `CLAUDE_COMMIT_MAX_BYTES=100000` (default `60000`) |
| Skip once | `CLAUDE_COMMIT_SKIP=1 git commit` |

Set env vars in your shell profile to make them stick.

## Other hooks

`.pre-commit-config.yaml` also includes the standard hygiene hooks
(trailing whitespace, end-of-file, YAML check, large files). Remove or extend
them per project.
