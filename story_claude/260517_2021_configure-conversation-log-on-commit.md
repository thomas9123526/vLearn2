# Configure per-task conversation log on every commit

## What this task did

Added a memory rule so that future task commits in this project automatically produce a `story_claude/<yymmdd>_<hhss>_<shorttitle>.md` file alongside the code/doc changes, with the user's prompt appended verbatim at the end. Updated [feedback_auto_commit.md](../../Users/aaa/.claude/projects/c--project-vLearn2/memory/feedback_auto_commit.md) with the new requirement and created a linked memory file [story_claude_conversation_log.md](../../Users/aaa/.claude/projects/c--project-vLearn2/memory/story_claude_conversation_log.md) for the detailed how-to. The MEMORY.md index was extended with the new entry.

## Conversation summary

Recent turns (faithful to memory):

- **User** asked how the Flutter app interacts with AI — directly or through the backend?
- **Assistant** explained: through the backend, always. Walked through the request flow (Flutter → `POST /conversations/sessions/:id/messages` → `ConversationsService.sendMessage` → `ConversationOrchestrator.generateTutorReply` → `AiProvider`). Listed reasons: API key safety, per-user rate limiting, content guard runs server-side, provider swap without app update, cost predictability.
- **User** asked if they need to purchase an API key.
- **Assistant** (short answer): no, several free paths — Ollama locally (free, no key), Groq free tier (fast hosted Llama), or Anthropic ($5 min credit, best quality).
- **User** asked if they can use LM Studio with `gpt-oss-20b` as the offline AI.
- **Assistant**: yes, works out of the box with the existing `OpenAICompatibleProvider`. Gave the env vars + honest call-outs (RAM requirements, structured-output flakiness risk, latency).
- **User** asked for a todoList in `todoList/0517/` for LM Studio integration.
- **Assistant** wrote a 12-section playbook ([01_lmstudio_integration.md](../todoList/0517/01_lmstudio_integration.md)) covering prereqs, model selection, LM Studio setup, backend env, wiring the orchestrator into ConversationsService, structured-output fallback, performance tuning, persona quirks, production fitness, verification checklist. Committed as `97bd8f0`.
- **User** asked to save the conversation as `story_claude/conversation_0517_v1.md`.
- **Assistant** wrote a 4-phase reconstruction log with an honest preamble (it's reconstruction, not verbatim — earlier exchanges were context-compressed; only recent turns are quoted faithfully). Committed as `7f0afe2`.
- **User** asked Claude to configure itself to **automatically** save the conversation to `story_claude/` on every commit, with their prompt appended at the end, using filename `yymmdd_hhss_shorttitle.md` (shorttitle ≤ 50 chars). The first request was interrupted; the second was the same with the trigger clarified as "when you do git commit for each task".

## Decisions / call-outs

- **A git hook can't dump the conversation.** Conversation lives in Claude Code session memory, not on disk; no shell command can read it. The realistic implementation is a **behavioral rule in memory** — I (Claude) write the story file myself as part of each task commit. No git hook configured for this.
- **Verbatim vs reconstruction**: recent turns are captured faithfully; older context-compressed turns are reconstruction. The memory rule explicitly tells me to be honest about which is which in every log.
- **Filename format `yymmdd_hhss`** is honored literally — that's hour + second, which omits minutes. Unusual but it's what the user wrote. I'll switch to `hhmm` or `hhmmss` if they later say it was a typo.
- **Failure mode**: never block a commit on log-writing. If the file write errors, log a warning and proceed.
- **Two-file memory split**: kept the conversation-log requirement as its own linked memory ([story_claude_conversation_log.md](../../Users/aaa/.claude/projects/c--project-vLearn2/memory/story_claude_conversation_log.md)) so the auto-commit memory stays focused on commit messages; the new rule cross-references via `[[story-claude-conversation-log]]`.

## User prompt (verbatim)

> I want you to configure claude that save our conversation as md file to story_claude when you do git commit for each task. Also append my prompt at the end.
> Md filename can be datetime_shorttitle.md.
> datetime means current time as yymmdd_hhss. shorttitle means abstraction title for our conversation. shorttitle length should not more than 50 letters.
