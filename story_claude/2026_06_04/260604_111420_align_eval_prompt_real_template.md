# Conversation - Align evaluation prompt with real ConversationModel template

| Field | Value |
|---|---|
| Saved | 2026-06-04 11:14:20 |
| Commit | Align evaluation prompt with ConversationModel: real template format, prompt vars in system prompt, rich user message |
| Project | C:\project\vLearn2 |

---

## User

good news. I have real template for evaluation prompt
[shared eval_template.txt and eval_example.txt]

## Assistant

Four gaps found vs our implementation, all fixed:

### 1. Evaluation system prompt uses prompt vars
Real template: `You are an English examiner assessing the CEFR level of {country_adjective} {learner_description}...`
Fix: `buildEvaluationSystemPrompt(scenario)` now resolves `{key}` placeholders from `vl_prompt_vars` (with scenario overrides), then appends `/think`.

### 2. Evaluation user message format completely different
Old format: `Target CEFR: B1\n\nTranscript:\n...\n\nScore the LEARNER's USER turns.`
Real format:
```
Target CEFR level: B1
Tutor role: cousin -- his younger cousin who is currently living in Shanghai...
Learner role: a twenty-eight-year-old professional who recently moved back...

Assigned topic: Navigating generational gaps regarding marriage and childcare

Assigned subtopics:
- the pressure of early marriage in Chengdu
...

Transcript:
[USER turn 0] ...
[TUTOR] ...
```
Fix: `evaluateSession()` now accepts `persona` and `scenario`; `triggerEvaluation()` loads persona and passes it through.

### 3. `session_feedback` removed — not in the real schema
The ConversationModel schema is: `overall_cefr_estimate, scores, specific_feedback, strengths, suggested_practice` — no `session_feedback`. Removed from `EvaluationResult` interface and `DEFAULT_EVALUATION_SYSTEM`. `ai_feedback` in DB now maps back to `result.suggested_practice`.

### 4. `learner_audience` renamed to `learner_description`
Migration `1782700000000` seed data updated to use key `learner_description` (matching the template variable name `{learner_description}`). `buildCchPrompt()` updated accordingly.

### Files changed
- `prompt-builder.service.ts` — real `DEFAULT_EVALUATION_SYSTEM`, `buildEvaluationSystemPrompt(scenario)` resolves prompt vars
- `conversation.orchestrator.ts` — removed `session_feedback`, new `evaluateSession()` signature with `persona`+`scenario`, rich user message
- `conversations.service.ts` — `triggerEvaluation()` loads persona, passes it; `ai_feedback` = `result.suggested_practice`
- `migrations/1782600000000` — updated seeded evaluation_system template text + description
- `migrations/1782700000000` — `learner_audience` → `learner_description` key

---

## Prompt

good news. I have real template for evaluation prompt
[eval_template.txt and eval_example.txt shared — ConversationModel's real evaluation system prompt and user message format]
