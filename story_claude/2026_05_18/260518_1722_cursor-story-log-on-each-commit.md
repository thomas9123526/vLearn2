# Cursor: save conversation to story_claude on each task commit

## What this task did

Extended the project Cursor rule [`.cursor/rules/auto-commit-after-task.mdc`](../.cursor/rules/auto-commit-after-task.mdc) so that every small-task git commit also creates a markdown conversation log under `story_claude/`. The rule specifies filename format (`yymmdd_HHmm_shorttitle.md`, shorttitle ≤ 50 chars), a content template (what was done, conversation summary, decisions, user prompt verbatim at the end), and requires staging the story file in the same commit as the code changes.

This mirrors the existing `story_claude/` convention already used in the repo (dozens of prior logs from Claude Code sessions).

## Conversation summary

- **User** (earlier in session) asked to configure Cursor to commit after every small task with a work report — rule `auto-commit-after-task.mdc` was added and committed as `6e12fc6`.
- **User** now wants the same workflow extended: on each task commit, save the conversation as markdown in `story_claude/`, append their prompt at the end, filename `datetime_shorttitle.md` where datetime is `yymmdd_hhss` and shorttitle is ≤ 50 letters.
- **Assistant** updated the Cursor rule with the full story-log template and workflow; noted that existing repo files use `HHmm` (hour+minute) rather than literal `hhss`, aligned with that convention; created this story file as the first example under the new rule.

## Decisions / call-outs

- **HHmm vs hhss**: User wrote `hhss`; all existing `story_claude/` filenames use 4-digit `HHmm` (e.g. `260518_1450`). Rule documents `HHmm` and explains the mapping so new logs stay consistent.
- **Agent-written logs, not git hooks**: Conversation text lives in the agent session; only the agent can faithfully summarize and append the user prompt. No hook added.
- **Uncommitted Flutter work** from earlier session (signup polite errors, `app_config` host) remains unstaged — out of scope for this config-only task.

## User prompt (verbatim)

> I want you to configure cursor that save our conversation as md file to "story_claude" directory  when you do git commit for each task. Also append my prompt at the end.
> Md filename can be datetime_shorttitle.md. 
> datetime means current time as yymmdd_hhss. shorttitle means abstraction title for our conversation. shorttitle length should not more than 50 letters.
