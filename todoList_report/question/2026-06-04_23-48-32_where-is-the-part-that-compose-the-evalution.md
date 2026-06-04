# where is the part that compose the evalution prompt and anylyze

Session: `40c2c32e-4bcc-4826-8449-440738f22ef6`
Saved: 2026-06-04T14:48:32.299Z

## User

where is the part that compose the evalution prompt and anylyze

## Assistant

Let me look at the prompt-builder service and related AI files.

## Assistant

Two files are involved:

**1. Prompt composition — [prompt-builder.service.ts](backend/src/ai/prompt-builder.service.ts)**

- **[`buildEvaluationSystemPrompt()`](backend/src/ai/prompt-builder.service.ts#L128)** (line 128) — builds the system prompt for the examiner. Loads the `evaluation_system` template from DB (`vl_prompt_templates`), falls back to the hardcoded `DEFAULT_EVALUATION_SYSTEM` constant at line 339. Resolves `{country_adjective}`, `{learner_description}`, `{avoid_cultures_phrase}` from `vl_prompt_vars`, then appends `/think`.

- **[`DEFAULT_EVALUATION_SYSTEM`](backend/src/ai/prompt-builder.service.ts#L339)** (line 339) — the fallback examiner system prompt. This is the one that matches the format in the attachment.

**2. Evaluation logic — [conversation.orchestrator.ts](backend/src/ai/conversation.orchestrator.ts)**

- **[`evaluateSession()`](backend/src/ai/conversation.orchestrator.ts#L199)** (line 199) — the full evaluation pipeline:
  - Line 210–218: formats the transcript into `[USER turn N]` / `[TUTOR]` lines
  - Line 225–243: builds the user message (target CEFR level, tutor role, learner role, topic, subtopics, transcript)
  - Line 246: calls `buildEvaluationSystemPrompt()` for the system prompt
  - Line 263–270: sends both to the AI provider (`maxTokens: 1500, temperature: 0.3`)
  - Line 283–299: strips `<think>...</think>`, extracts prose feedback and the JSON block, returns `EvaluationResult`
