# Conversation - Populate mock server with pre-canned conversations

| Field | Value |
|---|---|
| Saved | 2026-06-04 23:32:35 |
| Commit | auto: populate AI mock server with pre-canned language_redirect conversation dataset |
| Project | C:\project\vLearn2 |

---

## User

populate mock conversation with this data but ai mock server must follow llama rule for input and response format.

*(Attached 4 JSON files: language_redirect_A1_passed.json, language_redirect_A2_passed.json, language_redirect_B2_passed.json, language_redirect_C1_passed.json — quality-pipeline-passed examples across A1/A2/B2/C1 CEFR levels, China locale, family/health/shopping scenarios)*

## Assistant

Created `ai_model_mock/data/conversations.js` with 6 pre-canned conversation examples embedded verbatim from the quality-pipeline JSON files:

- A1: Mom / calling a parent (Chinese locale)
- A2 ×2: doctor / health_and_wellbeing; Sales Assistant / Shopping for clothes
- B2 ×2: Cousin Liu / Sibling responsibilities (speaks_l1 + requests_l1 variants)
- C1: Uncle Wei / intergenerational bonds

Each example is indexed by its exact `systemPrompt`. The `findPreCannedResponse(requestMessages)` function matches by system prompt, counts user-turn depth in the incoming request, and returns the corresponding pre-canned assistant message.

Updated `ai_model_mock/index.js` to:
1. Import `findPreCannedResponse` from the data module.
2. For non-eval (conversation) requests: attempt dataset lookup first; on a hit, return the pre-canned reply wrapped in the llama.cpp-compatible OpenAI `chat.completion` response format (same `openAiResponse()` helper already used for Claude responses).
3. Log `CHAT → dataset hit` or `CHAT → no dataset match, falling back to Claude` so it's easy to see what path was taken.
4. Evaluation requests (JSON schema / EvaluationOutput) always bypass the dataset and go straight to Claude — the evaluation logic is scenario-specific and not in the dataset.

The response envelope is unchanged (`{ id, object: 'chat.completion', created, model, choices, usage }`) which is exactly what llama.cpp server returns.

---

## Prompt

populate mock conversation with this data but ai mock server must follow llama rule for input and response format.
