# If our custom model response for chat and evalution doesn't not match the expect

Session: `40c2c32e-4bcc-4826-8449-440738f22ef6`
Saved: 2026-06-05T01:28:43.833Z

## User

If our custom model response for chat and evalution doesn't not match the expected pattern or format because some short paragraphs or sentences are inserted, how can we handle this?
Is the project robust to handle these changes? Or I think wrong because pattern or format mismatch never happens?

## Assistant

Let me check the exact parsing logic and any edge case handling already in place.

## Assistant

Good. Here's the honest analysis:

---

## Chat (tutor) — very robust

[conversation.orchestrator.ts:94](backend/src/ai/conversation.orchestrator.ts#L94)

```ts
const text = res.content.trim();
```

The tutor reply has **zero format requirements**. Whatever text the model returns is sent to Flutter as-is. Extra sentences, different phrasing, apologies, anything — it all works. The only failure case is an **empty string**, and even that is caught:

```ts
if (!text) {
  return this.fallbackReply(args.history);  // canned reply, never crashes
}
```

**Chat: no mismatch risk at all.**

---

## Evaluation — partially robust, has real failure points

The parser at [orchestrator.ts:286-299](backend/src/ai/conversation.orchestrator.ts#L286-L299) uses a simple scan, not a strict format match. Here's what each case produces:

| Model output | Result |
|---|---|
| `<think>…</think>` + prose + `{…}` | Works perfectly — designed for this |
| No `<think>`, just prose + `{…}` | Works — `afterThink` = full text, prose becomes `session_feedback` |
| `{…}` only, no prose | Works — `session_feedback` = `''` |
| Extra sentences **after** the JSON `}` | Works — `lastIndexOf('}')` finds the final `}`, extra text ignored |
| Extra sentences **inside** the JSON (malformed) | **BREAKS** — `JSON.parse()` throws, caught, returns `null` |
| No `{` or `}` at all | Returns `null` — evaluation silently not saved |
| Nested `{}` inside a string value | Works — `lastIndexOf('}')` finds the outermost closing brace |
| JSON wrapped in markdown ` ```json … ``` ` | **BREAKS** — `jsonStart` finds `{` inside the backtick block, but if there's also a `}` before the JSON closes from an earlier `{` in prose, it could slice wrong |

---

## The two real failure modes

**1. Markdown code fence wrapping** — Qwen3 sometimes wraps JSON in ` ```json\n{…}\n``` `:

```
Here is the evaluation:
```json
{"overall_cefr_estimate": "A1", ...}
```
```

`indexOf('{')` still finds the right `{`, `lastIndexOf('}')` still finds the right `}` — **this actually works** because the backtick fence is outside the `{}` boundary. So this case is safe.

**2. Malformed JSON** — if the model inserts an unescaped quote, comment, or trailing comma inside the JSON object:

```json
{"scores": {"fluency": 5, // very good}, ...}
```

`JSON.parse()` throws → caught at line 300 → returns `null` → evaluation never saved to DB. Flutter gets 404 forever when polling `/sessions/:id/score`.

---

## What is NOT handled

```ts
// line 298 - no field validation at all
const parsed = JSON.parse(afterThink.slice(jsonStart, jsonEnd + 1));
return { ...parsed, session_feedback: sessionFeedback } as EvaluationResult;
```

The `as EvaluationResult` is a **TypeScript cast, not a runtime check**. If the model returns valid JSON but with wrong field names (e.g. `score` instead of `scores`, or `fluency_score` instead of `fluency`), the code does not crash — but `triggerEvaluation()` then calls `toHundred(s.fluency)` on `undefined`, which produces `NaN`, and `NaN` stored as `smallint` in Postgres becomes `null`.

---

## Recommendation: add a guard in `triggerEvaluation`

The safest fix is one validation check before saving scores. In [conversations.service.ts:437](backend/src/conversations/conversations.service.ts#L437):

```ts
const s = result.scores;
// add this:
if (!s || typeof s.fluency !== 'number') {
  this.logger.warn(`Evaluation scores missing or wrong type for session ${sessionId}`);
  return;
}
```

And for the JSON parser in [orchestrator.ts:298](backend/src/ai/conversation.orchestrator.ts#L298), strip markdown fences defensively:

```ts
let jsonStr = afterThink.slice(jsonStart, jsonEnd + 1);
// strip ```json ... ``` if model wrapped it
jsonStr = jsonStr.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, '');
const parsed = JSON.parse(jsonStr);
```

---

## Summary

| Path | Robust? | Risk |
|---|---|---|
| Tutor chat | Fully robust | None |
| Evaluation — extra prose | Robust | None |
| Evaluation — no JSON at all | Graceful | Returns null, poll 404 forever |
| Evaluation — malformed JSON | Graceful | Same as above |
| Evaluation — valid JSON, wrong field names | Silent data loss | Scores saved as null |

Your instinct is right — the format mismatch **can** happen with a fine-tuned Qwen3 that wasn't trained on this exact JSON schema. The `scores.fluency` field name in particular must match exactly.
