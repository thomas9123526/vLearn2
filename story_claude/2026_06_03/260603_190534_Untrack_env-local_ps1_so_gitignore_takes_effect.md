# Conversation - Untrack env-local.ps1 so .gitignore takes effect

| Field | Value |
|---|---|
| Saved | 2026-06-03 19:05:34 |
| Commit | auto: stop tracking cmds/env-local.ps1 (already in .gitignore) |
| Project | C:\project\vLearn2 |

---

## User

"i want git ignore for env-local.ps1"

## Assistant

Found the root cause: `.gitignore` line 6 already contained `cmds/env-local.ps1`,
but the file was still tracked — and git ignores `.gitignore` rules for files that
are already in the index. So the rule had no effect and the file kept showing as
modified.

Fix: `git rm --cached cmds/env-local.ps1` to untrack it while keeping the local copy
on disk (still present, 634 bytes). `git check-ignore -v` then confirms it resolves
to `.gitignore:6`, so future edits are ignored. No `.gitignore` change was needed.

Left the unrelated l10n CRLF-vs-LF working-copy churn untouched (separate item).

---

## Prompt

i want git ignore for env-local.ps1
