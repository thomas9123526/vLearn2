# Conversation - Session feedback prose display from eval response

| Field | Value |
|---|---|
| Saved | 2026-06-04 11:36:53 |
| Commit | Extract and display evaluation prose feedback and turn-by-turn specific feedback |
| Project | C:\project\vLearn2 |

---

## User

[shared eval_example_response.txt — real ConversationModel evaluation output]

The model outputs prose text BETWEEN `</think>` and the JSON object. That prose is the session feedback.

On the evaluation result screen, show session feedback first. Then scores. Then turn-specific feedback items.

## Assistant

The model response structure (discovered from the real example):
```
<think>...reasoning...</think>

Prose paragraph(s) — session feedback overview

{
  "overall_cefr_estimate": "A1",
  "scores": { "fluency": 5, "accuracy": 5, ... },
  "specific_feedback": [{ "turn_index": 0, "user_text": "...", "issue": "None", "correction": "None", "severity": "minor" }],
  "strengths": [...],
  "suggested_practice": "..."
}
```

Our parser was discarding the prose between `</think>` and `{`. Fixed.

### Backend changes

**`conversation.orchestrator.ts`**
- Added `session_feedback: string` to `EvaluationResult` interface
- Parser now captures prose between `</think>` and `{` as `sessionFeedback`, merges it into the returned object

**`conversations.service.ts`**
- `ai_feedback` ← `result.session_feedback` (the prose paragraph shown first)
- `fluency_metrics` JSONB ← `{ specific_feedback: [...], suggested_practice: "..." }` (both stored)
- `improvements` now filtered — only items where `issue != "None"` are stored
- `getSessionScore()` now returns `sessionFeedback`, `specificFeedback`, `suggestedPractice`

### Flutter changes

**`session_report_screen.dart`**
- `_ScoreCard` reads `sessionFeedback` and `specificFeedback` from score map
- Shows session feedback prose first (styled card with border)
- Adds "Turn feedback" section with `_TurnFeedbackItem` widget — only shows turns where issue != "None"
- `_TurnFeedbackItem`: colored left border by severity (major=error, moderate=orange, minor=muted), shows turn index, severity badge, quoted user text, issue, and correction arrow

---

## Prompt

and i have the real example for the evaluation result from our custom model.
From this response you can ignore <think> --------- </think>.
On the evaluation result screen on the application, you need to show session feedback first.
This content is below the '<think> --------- </think>' in the response. ...
I want you visualize these evaluation result and show on the application screen.
