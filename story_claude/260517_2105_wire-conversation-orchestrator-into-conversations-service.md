# Wire `ConversationOrchestrator` into `ConversationsService.sendMessage`

## What this task did

Completed §1.5 of the [LM Studio integration playbook](../todoList/0517/01_lmstudio_integration.md). Tutor replies now flow through `ConversationOrchestrator.generateTutorReply` (and from there into whatever `AI_PROVIDER` is configured) instead of the hard-coded `generatePlaceholderReply` rule.

Two files touched:

- **[backend/src/conversations/conversations.module.ts](../backend/src/conversations/conversations.module.ts)** — imported `AiModule` (so `ConversationOrchestrator` is in DI scope) and registered `UserEntity` in `TypeOrmModule.forFeature(...)` so `ConversationsService` can fetch the user's `current_level` + `native_language`.
- **[backend/src/conversations/conversations.service.ts](../backend/src/conversations/conversations.service.ts)** — injected `Repository<UserEntity>` and `ConversationOrchestrator`. Refactored `sendMessage()` to load the full message history (ascending) instead of just the last row, then hand persona/scenario/user/history to the orchestrator. The orchestrator's own try/catch already returns a canned fallback if the AI call fails, so I kept `generatePlaceholderReply` only as a last-resort guard for the (rare) case where persona/user lookups fail.

After both env config + wire-up, the LM Studio flow is end-to-end live:

1. User sends a message in the Flutter chat.
2. `POST /conversations/sessions/:id/messages` → `ConversationsService.sendMessage`.
3. `ConversationOrchestrator.generateTutorReply` builds a system prompt from persona + scenario + user level, hands the history to the configured provider.
4. Provider factory in [ai.module.ts](../backend/src/ai/ai.module.ts) returns `OpenAICompatibleProvider` (because `AI_PROVIDER=openai-compatible` in `.env`).
5. `OpenAICompatibleProvider` hits `http://localhost:1234/v1/chat/completions` against LM Studio.
6. Reply comes back, gets saved as the assistant message, returned to Flutter.

If LM Studio is offline / the call fails, the orchestrator's `catch` block returns a canned fallback — the conversation UI stays functional.

## Conversation summary

- Previous task (commit `ca10662`) configured the env half: `.env.example` defaults, gitignore allowlist, local `.env` with LM Studio config.
- This commit completes the wire-up so changing `AI_PROVIDER` is no longer dead code.
- I confirmed via `npx tsc --noEmit` from `backend/` that the TypeScript compiles cleanly.

## Decisions / call-outs

- **Refactored the sequence-number query into a single `find()` ascending call** instead of leaving the prior `findOne({ order: DESC })` + adding a separate full-history fetch. Saves one round trip and keeps history + nextSeq derived from the same source.
- **Built the history with the NEW user message appended** (not just `priorMessages`), since the orchestrator generates the reply *to* the just-sent message. Without this, the LLM would see all prior turns but not what the user just said.
- **Did NOT remove `generatePlaceholderReply`.** Kept it as a final fallback for the case where the user or persona row doesn't exist (defensive; shouldn't happen, but cheaper than crashing). The orchestrator has its own AI-failure fallback that doesn't need this method.
- **Did NOT wire AI into `start()`'s opening greeting.** The greeting is derived from scenario data and doesn't benefit from an LLM call — also avoids cold-starting LM Studio just to say hi.
- **Did NOT touch `endSession()` to call `scoreGrammar()`.** §1.7 of the playbook flags that as the risky bit (structured-output reliability with smaller local models) and recommends an explicit smoke test first. Saving that for a separate task.
- **`UserEntity` injection feels heavy** for fetching just two columns. A future cleanup could pull `current_level`/`native_language` from the JWT payload if they're added as claims, eliminating the user-row read on every turn. For now: explicit DB read per message is fine at this scale.
- **No tests added.** The existing test suite doesn't have a conversation-flow integration test that exercises `sendMessage`; adding one requires mocking the AI provider, which is more scaffolding than this commit warrants. Manual end-to-end smoke test (per §1.6 of the playbook) is the pragmatic verification.

## How to verify it works

1. Start LM Studio → load `openai/gpt-oss-20b` → Developer tab → Start Server (port 1234).
2. `cd backend && npm run start:dev`. Boot log should include `Using OpenAICompatibleProvider (label=lmstudio)`.
3. From the Flutter app, log in, pick a scenario, send a message. The tutor reply should be a contextual LM Studio response (not one of the three canned strings from `generatePlaceholderReply`).
4. Stop LM Studio mid-session → next message should still get a (canned) reply, with a warning logged in the backend.

## User prompt (verbatim)

> I want offline LM Studio for AI_PROVIDER, can u configure project?
