# Conversation - Merge session feedback into evaluation prompt

| Field | Value |
|---|---|
| Saved | 2026-06-04 10:17:10 |
| Commit | Merge session feedback into evaluation prompt; remove standalone feedback template |
| Project | C:\project\vLearn2 |

---

## User

you separate session feedback prompt and evaluation prompt.
But our system accept one prompt and produce evaluation and session feedback at once.
So We need to combine two prompt and make into one prompt.

## Assistant

The two prompts were already partially merged: `buildFeedbackPrompt()` existed but was never called — `ai_feedback` in the DB was already just `result.suggested_practice` from the evaluation JSON. The feedback template card in admin was dead weight.

Fix: added `session_feedback` directly into the evaluation JSON schema so the model produces both scores and the warm feedback paragraph in one response. Removed the standalone `feedback` template entirely.

### Changes

- **`EvaluationResult` interface** (`conversation.orchestrator.ts`) — added `session_feedback: string` field
- **`conversations.service.ts`** — `ai_feedback` now uses `result.session_feedback || result.suggested_practice` (graceful fallback)
- **`prompt-builder.service.ts`** — updated `DEFAULT_EVALUATION_SYSTEM` JSON schema to include `session_feedback` field with instructions; removed `buildFeedbackPrompt()` method and `DEFAULT_FEEDBACK` constant
- **`prompt-template.entity.ts`** — `PromptKind` is now `'tutor_system' | 'evaluation_system'` (no more `'feedback'`)
- **Migration `1782600000000`** — deletes `feedback` row from `vl_prompt_templates`; updates `evaluation_system` template body to include `session_feedback` field + updates description
- **Admin panel `prompt-templates/page.tsx`** — removed `feedback` kind and its placeholder buttons; `PLACEHOLDERS` type now matches the two remaining kinds

### session_feedback prompt instruction added to evaluation template

```
session_feedback: A warm, encouraging paragraph (2-3 sentences, max 60 words) addressed directly
to the learner in second person ("You showed…", "Try to…"). Mention one specific strength from
the session, acknowledge one area to improve, and close with a motivating note.
```

### Run on backend
```bash
npm run migration:run
```
Applies migration `1782600000000` (delete feedback row, update evaluation_system template).

---

## Prompt

you separate session feedback prompt and evaluation prompt.
But our system accept one prompt and produce evaluation and session feedback at once.
So We need to combine two prompt and make into one prompt.
