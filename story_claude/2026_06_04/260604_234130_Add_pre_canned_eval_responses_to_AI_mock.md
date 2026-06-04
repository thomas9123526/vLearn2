# Conversation - Add pre-canned eval responses to AI mock

| Field | Value |
|---|---|
| Saved | 2026-06-04 23:41:30 |
| Commit | auto: add pre-canned evaluation responses to AI mock server |
| Project | C:\project\vLearn2 |

---

## User

make mock data for evalution response with this attachment.
in the content of attachment, pipeline part is no necessary

this is the evalution response example.

{"role":"assistant","content": "<think>...</think>\n\n{...json...}"}

(Attachment: A1_passed.json — 13 JSONL records of A1 CEFR evaluation examples with pipeline-passed filter results)

## Assistant

Created `ai_model_mock/data/evaluations.js` with 13 pre-canned evaluation responses extracted from the A1_passed.json attachment. Each entry stores:
- `id` — example identifier
- `cefrLevel` — e.g. `"A1"`
- `turn0Snippet` — the first `[USER turn 0]` text, used as match key
- `response` — clean JSON string (EvaluationOutput schema, no `<think>` block or markdown fences)

The pipeline section from the attachment was omitted as requested.

Updated `ai_model_mock/index.js` to:
1. Import `findPreCannedEvaluation` from the new file
2. For eval requests: look up by matching the `[USER turn 0]` text in the incoming user message; return the pre-canned JSON on hit, fall back to Claude on miss
3. For chat requests: unchanged (still uses `findPreCannedResponse` from `conversations.js`)

---

## Prompt

make mock data for evalution response with this attachment.
in the content of attachment, pipeline part is no necessary
