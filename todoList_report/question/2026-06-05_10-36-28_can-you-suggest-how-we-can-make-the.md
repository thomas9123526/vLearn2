# Can you suggest how we can make the Evaluation robust for the real failure point

Session: `40c2c32e-4bcc-4826-8449-440738f22ef6`
Saved: 2026-06-05T01:36:28.004Z

## User

Can you suggest how we can make the Evaluation robust for the real failure points?

## Assistant

Let me read the exact lines I'll be editing before making changes.

## Assistant

Good. I have everything I need. Now I'll make both fixes.

**Fix 1:** Extract a `parseEvaluationText()` method in the orchestrator with markdown fence stripping, field-name normalization, and score validation.

**Fix 2:** Guard in `triggerEvaluation()` against bad scores before saving.

## Assistant

Now add the guard in `triggerEvaluation()` before scores are used:

## Assistant

Now fix the `fields` object to accept `null` from `toHundred`:

## Assistant

Now verify the changes compile cleanly:

## Assistant

No type errors. Now commit with the story file.

## Assistant

Here's what changed and why each part matters:

---

## Fix 1 — `parseEvaluationText()` in [conversation.orchestrator.ts](backend/src/ai/conversation.orchestrator.ts)

Replaced the 15-line inline block with a dedicated private method. Step by step:

**Markdown fence stripping** — handles ` ```json … ``` ` wrapping:
```ts
jsonStr = jsonStr.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, '').trim();
```

**JSON parse error logging** — now logs the actual failing snippet, not just the exception:
```ts
this.logger.warn(`evaluateSession: JSON.parse failed — ${e.message}. Snippet: ${jsonStr.slice(0, 200)}`);
```

**Field-name alias normalisation** — handles all common Qwen3 variations:
```ts
scores: {
  fluency:         rawScores['fluency']        ?? rawScores['fluency_score'],
  accuracy:        rawScores['accuracy']       ?? rawScores['grammar'] ?? rawScores['grammar_score'],
  vocabulary:      rawScores['vocabulary']     ?? rawScores['vocabulary_score'],
  interaction:     rawScores['interaction']    ?? rawScores['engagement'] ?? rawScores['engagement_score'],
  topic_adherence: rawScores['topic_adherence']?? rawScores['topic_adherence_score'] ?? rawScores['topic'],
}
```

**`toScore()` helper** — returns `0` as a sentinel for "field not found" instead of `NaN`:
```ts
private toScore(v: unknown): number {
  const n = Number(v);
  if (!isFinite(n) || n === 0) return 0;   // 0 = missing
  return Math.round(Math.max(1, Math.min(5, n)));
}
```

**Missing optional fields** get safe defaults instead of crashing:
```ts
specific_feedback: Array.isArray(raw['specific_feedback']) ? ... : [],
strengths:         Array.isArray(raw['strengths'])         ? ... : [],
suggested_practice: raw['suggested_practice'] ?? '',
```

---

## Fix 2 — guard in `triggerEvaluation()` in [conversations.service.ts](backend/src/conversations/conversations.service.ts)

`toHundred()` now returns `null` when a score is 0 (missing), so Postgres stores `null` instead of `0`. The average is computed only from valid scores:

```ts
const toHundred = (v: number): number | null => (v === 0 ? null : Math.round(...));
const validScores = [s.fluency, ...].map(toHundred).filter(v => v !== null);
const avgHundred  = validScores.length > 0 ? Math.round(sum / count) : null;
```
