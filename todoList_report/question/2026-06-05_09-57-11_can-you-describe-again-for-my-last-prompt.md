# can you describe again for my last prompt with the code lines

Session: `40c2c32e-4bcc-4826-8449-440738f22ef6`
Saved: 2026-06-05T00:57:11.429Z

## User

can you describe again for my last prompt with the code lines

## Assistant

Let me read the key files for exact line numbers.

## Assistant

Here is the complete flow with exact code locations:

---

## Step 1 — AI returns the response

[conversation.orchestrator.ts:286-299](backend/src/ai/conversation.orchestrator.ts#L286-L299)

The raw AI text is parsed here:
```ts
// Strip <think>...</think>
const afterThink = text.includes('</think>')
  ? text.slice(text.indexOf('</think>') + 8).trim()
  : text.trim();

// prose before first '{' → session_feedback
const jsonStart = afterThink.indexOf('{');
const sessionFeedback = jsonStart > 0 ? afterThink.slice(0, jsonStart).trim() : '';

// JSON block → parsed into EvaluationResult
const parsed = JSON.parse(afterThink.slice(jsonStart, jsonEnd + 1));
return { ...parsed, session_feedback: sessionFeedback };
```

---

## Step 2 — Type definitions

[conversation.orchestrator.ts:15-39](backend/src/ai/conversation.orchestrator.ts#L15-L39)

```ts
interface EvaluationScores {
  fluency: number;         // 1-5
  accuracy: number;        // 1-5
  vocabulary: number;      // 1-5
  interaction: number;     // 1-5
  topic_adherence: number; // 1-5
}
interface EvaluationResult {
  session_feedback: string;       // prose paragraph
  overall_cefr_estimate: string;  // e.g. "A1"
  scores: EvaluationScores;
  specific_feedback: SpecificFeedbackItem[];
  strengths: string[];
  suggested_practice: string;
}
```

---

## Step 3 — endSession triggers evaluation (fire-and-forget)

[conversations.service.ts:373-376](backend/src/conversations/conversations.service.ts#L373-L376)

```ts
// does NOT block the HTTP response to Flutter
this.triggerEvaluation(session.id).catch(...)
```

---

## Step 4 — Scores saved to DB

[conversations.service.ts:437-461](backend/src/conversations/conversations.service.ts#L437-L461)

```ts
const toHundred = (v) => Math.round(Math.max(1, Math.min(5, v)) * 20);

// AI field (1-5)        →  DB column              →  stored value (0-100)
s.fluency           →  fluency_score          →  toHundred(s.fluency)
s.accuracy          →  grammar_score          →  toHundred(s.accuracy)
s.vocabulary        →  vocabulary_score       →  toHundred(s.vocabulary)
s.interaction       →  engagement_score       →  toHundred(s.interaction)
s.topic_adherence   →  topic_adherence_score  →  toHundred(s.topic_adherence)
average of all 5    →  overall_score

// prose + arrays
result.session_feedback     →  ai_feedback
result.strengths            →  strengths
result.specific_feedback    →  fluency_metrics.specific_feedback  (JSONB)
result.suggested_practice   →  fluency_metrics.suggested_practice (JSONB)
```

Saved to table `vl_session_scores`.

---

## Step 5 — Flutter fetches the score

[conversations.service.ts:381-408](backend/src/conversations/conversations.service.ts#L381-L408)

Endpoint: `GET /conversations/sessions/:id/score` — returns **404** while evaluation is still running, **200** when done. Flutter should poll this.

The response maps DB columns back to camelCase for Flutter:
```ts
fluency_score          → fluencyScore
grammar_score          → accuracyScore
vocabulary_score       → vocabularyScore
engagement_score       → interactionScore
topic_adherence_score  → topicAdherenceScore
overall_score          → overallScore
ai_feedback            → sessionFeedback
cefr_estimate          → cefrEstimate
```

---

## Progress tab (separate flow)

The **Progress tab** does NOT use `vl_session_scores` directly. It reads from `vl_skill_snapshots` via `GET /progress/snapshots` — those are aggregated daily snapshots. Whether and how session scores feed into snapshots depends on a separate aggregation job in the backend.
