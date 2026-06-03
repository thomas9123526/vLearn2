# where is the code part for build system prompt and where is the part for evaluat

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-03T14:20:11.195Z

## User

where is the code part for build system prompt and where is the part for evaluation prompt?

## Assistant

Two files own all prompt construction — both in the backend:

**System prompt** — [`backend/src/ai/prompt-builder.service.ts`](backend/src/ai/prompt-builder.service.ts)
- `buildSystemPrompt()` line 55 — three-tier priority: per-scenario override → DB full-template → section builder
- `buildCchPrompt()` line 121 — assembles sections `[role]`, `[learner]`, `[topic]`, `[cefr_level]`, `[locale]`, `[guidelines]`, etc.

**Evaluation / grammar / feedback prompts** — same file
- `buildGrammarPrompt()` line 78 — per-turn grammar check prompt
- `buildFeedbackPrompt()` line 93 — end-of-session feedback prompt

**Evaluation execution** — [`backend/src/ai/conversation.orchestrator.ts`](backend/src/ai/conversation.orchestrator.ts)
- `evaluateSession()` line 187 — sends full transcript to the AI with a CEFR scoring schema, parses `<think>…</think>` reasoning, returns scores + per-turn corrections
- `scoreGrammar()` line 94 — calls `buildGrammarPrompt`, fires per-turn
- `generateTutorReply()` line 52 — the normal reply path, calls `buildSystemPrompt` at line 59

**Trigger point** — [`backend/src/conversations/conversations.service.ts`](backend/src/conversations/conversations.service.ts)
- `triggerEvaluation()` line 393 — called at session end, invokes `evaluateSession()`, stores results in DB
