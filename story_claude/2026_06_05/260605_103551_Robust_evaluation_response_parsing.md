# Conversation - Robust evaluation response parsing

| Field | Value |
|---|---|
| Saved | 2026-06-05 10:35:51 |
| Commit | auto: make evaluation response parsing robust to Qwen3 format variations |
| Project | C:\project\vLearn2 |

---

## User

Can you suggest how we can make the Evaluation robust for the real failure points?

## Assistant

Identified two real failure points in the evaluation response pipeline:

1. **Malformed JSON** — `JSON.parse()` throws if the model inserts unescaped quotes, comments, or trailing commas inside the JSON block. Caught by try/catch but returns null silently.
2. **Wrong field names** — Valid JSON but `score` instead of `scores`, or `grammar` instead of `accuracy`. TypeScript cast `as EvaluationResult` doesn't catch this at runtime; scores become NaN then null in Postgres.

**Fix 1 — `conversation.orchestrator.ts`:**

Extracted a `parseEvaluationText(text)` private method replacing the inline 15-line block. It:
- Strips `<think>…</think>`
- Strips markdown code fences (` ```json … ``` `)
- Logs the failing JSON snippet on parse error (not just the exception message)
- Normalises score field aliases: `score` → `scores`, `grammar`/`grammar_score` → `accuracy`, `engagement` → `interaction`, `topic` → `topic_adherence`, etc.
- Uses `toScore(v)` helper that clamps 1–5 and returns 0 for missing/non-numeric (0 = sentinel for "not found")
- Warns (not throws) when all scores resolve to 0
- Fills missing optional fields (`strengths`, `specific_feedback`, `suggested_practice`) with safe defaults instead of crashing

**Fix 2 — `conversations.service.ts` `triggerEvaluation()`:**

- Guards `result.scores` is a non-null object before touching its fields
- `toHundred()` now returns `number | null` — score of 0 (sentinel) stored as null, not 0
- `avgHundred` computed only from non-null scores; null if all missing

---

## Prompt

Can you suggest how we can make the Evaluation robust for the real failure points?
