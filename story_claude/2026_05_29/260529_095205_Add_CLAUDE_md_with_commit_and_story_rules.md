# Conversation - Add CLAUDE.md with commit and story rules

| Field | Value |
|---|---|
| Saved | 2026-05-29 09:52:06 |
| Commit | Add CLAUDE.md with commit-after-task and story_claude rules |
| Project | C:\project\vLearn2 |

---

## User

configure claude that it should commit changes with report that what you have done after every small task done.

I want you to configure claude that save our conversation as md file to story_claude when you do git commit for each task. Also append my prompt at the end.
Md filename can be datetime_shorttitle.md.
datetime means current time as yymmdd_hhss. shorttitle means abstraction title for our conversation. shorttitle length should not more than 50 letters.

## Assistant

Interpreted the request as a project-level workflow rule (not a settings.json hook — the per-task commit + story generation needs the model's judgment about scope and titling, which a shell hook can't supply). Confirmed the existing convention by reading `story_claude/2026_05_29/` — filenames already follow `yymmdd_hhmmss_Short_Title.md` (so the "hhss" in the request was a typo for `hhmmss`), and files include a metadata table + chronological user/assistant turns.

Created `CLAUDE.md` at the project root with:

- **Workflow rule:** after each small, self-contained task, (1) commit the change with a message that reports what was done, (2) write a `story_claude/YYYY_MM_DD/yymmdd_hhmmss_short_title.md` capturing the conversation, (3) include the story file in the same commit.
- **Standing-permission clause:** this rule grants permission to commit without per-task user prompts, overriding the Claude Code default. Still no `git push`, no amends, no empty commits, and destructive ops still pause.
- **Story file format spec:** header, metadata table (Saved / Commit / Project), chronological turns, and a final `## Prompt` section that repeats the triggering user prompt verbatim (the "append my prompt at the end" requirement).
- **"Small task" definition:** one commit-subject's worth of work; multi-step work is one task; pure Q&A doesn't trigger a commit.
- **Filename rules:** `short_title` ≤ 50 chars, underscores between words, derived from the topic.

Applied the rule retroactively to the previous task in this session (the adb-host-server.bat work): made a scoped commit `Add adb-host-server.bat for VM-to-host emulator debugging` with its own story file.

This second commit adds `CLAUDE.md` + this story file.

---

## Prompt

configure claude that it should commit changes with report that what you have done after every small task done.

I want you to configure claude that save our conversation as md file to story_claude when you do git commit for each task. Also append my prompt at the end.
Md filename can be datetime_shorttitle.md.
datetime means current time as yymmdd_hhss. shorttitle means abstraction title for our conversation. shorttitle length should not more than 50 letters.
