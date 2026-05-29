# vLearn2 — Claude Code project rules

## Workflow: commit + story after every small task

After completing each small, self-contained task in this project, do **both** of the following before moving on:

### 1. Commit the change

Stage the relevant files and `git commit` with a message that *reports what you did* — concrete enough that a future reader can tell what changed without opening the diff. Follow the existing log style (short imperative subject; `auto:` prefix is used for routine work).

This rule **grants standing permission to commit** in this project, overriding the global "never commit unless explicitly asked" default. You still must NOT:
- `git push` without being asked.
- Amend or rewrite published commits.
- Make empty commits — if nothing changed, skip.
- Bypass the normal pause-and-confirm rule for destructive or hard-to-reverse actions.

### 2. Save the conversation to `story_claude/`

Write a markdown file in the same commit that captures the user/assistant turns leading to this task.

**Path:** `story_claude/YYYY_MM_DD/yymmdd_hhmmss_short_title.md`

- `YYYY_MM_DD` — today's date as a folder (e.g. `2026_05_29`). Create it if missing.
- `yymmdd_hhmmss` — local time at the moment of saving (e.g. `260529_095032`). Get it from PowerShell: `Get-Date -Format 'yyMMdd_HHmmss'`.
- `short_title` — abstraction of the conversation topic, words joined with `_`, **max 50 characters**. Pick something findable later (e.g. `Run_adb_server_on_host_for_VM_emulator_debugging`).

**File contents:**

```markdown
# Conversation - <short title with spaces>

| Field | Value |
|---|---|
| Saved | YYYY-MM-DD HH:MM:SS |
| Commit | <commit subject line> |
| Project | C:\project\vLearn2 |

---

## User

<user message, verbatim>

## Assistant

<assistant reply — keep substantive reasoning and final answer; drop pure tool-call narration>

... (repeat for each turn) ...

---

## Prompt

<the user's final prompt that triggered this commit, verbatim — even if it's already above, repeat it here for quick search>
```

Include the story file in **the same commit** as the code change.

## What counts as "a small task"

- A discrete fix, feature add, refactor, doc edit, config change, or new script.
- Roughly: anything you'd describe in one commit subject.
- Multi-step work (plan → implement → test) is ONE task. Commit once when it's verifiably done, not after each step.
- Pure conversation (Q&A with no file change) does NOT trigger a commit. No empty commits, no empty story files.

## Other project rules

- Backend (NestJS) and admin panel are NOT run on this VM — Flutter app only. See [memory: vm-environment](../../Users/aaa/.claude/projects/c--project-vLearn2/memory/vm-environment.md) for toolchain layout.
- Match existing `cmds/` script style (header comment block, defensive PowerShell helpers).
- Drift / Riverpod / Freezed `*.g.dart` files are codegen — never edit by hand. Run `dart run build_runner build --delete-conflicting-outputs` in `flutter_app/`.
