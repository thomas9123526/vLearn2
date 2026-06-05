# Conversation - Qt sanitize tutor reply (draft/think scaffolding)

| Field | Value |
|---|---|
| Saved | 2026-06-04 17:49:00 |
| Commit | auto: sanitize tutor reply (strip think/draft/markdown) before display + TTS |
| Project | C:\project\vLearn2 |

---

## User

*Draft:* "Hello! Welcome to the airport. I
Above is the message that you showed on the chat screen. I think you parse the
backend reply for ai provider wrongly. That should be in nice format. Please check
about it.

## Assistant

Traced it: the chat showed the raw AI output. The backend orchestrator
(conversation.orchestrator.ts generateTutorReply) returns res.content.trim()
*raw* — it only strips <think> for the evaluation path, not the chat reply. So a
reasoning model that emits "*Draft:* ...", "*Final:* ...", <think>…</think>, or
markdown leaks that into the bubble (and into TTS). The mock replies are clean;
this comes from the real provider.

Proper long-term fix is backend-side (clean generateTutorReply like the eval path,
or AI_DISABLE_THINKING / prompt tweaks), but since the Qt client can't trust the
provider's formatting I added defensive client-side sanitization:

- New util/TextClean.h `sanitizeReply()`:
  1. strip <think>…</think> (keep text after the last </think>),
  2. if a "Final:" label exists, keep only the final answer,
  3. strip a leading Draft/Tutor/Assistant/Reply label,
  4. drop markdown emphasis/code markers,
  5. normalize whitespace,
  6. unwrap one surrounding pair of quotes,
  7. never return empty from non-empty input.
- Applied to assistant content in onSend reply and renderSession (display + TTS);
  user messages untouched.

Unit-tested: "*Draft:* \"Hello! …\"" → clean; Draft+Final → keeps Final; <think>
stripped; plain text unchanged; "final boarding call" NOT truncated (needs a
colon); "**Tutor:** …" cleaned. Builds clean.

---

## Prompt

*Draft:* "Hello! Welcome to the airport. I
Above is the message that you showed on the chat screen. I think you parse the
backend reply for ai provider wrongly. That should be in nice format. Please check
about it.
