# our custom model can interect to the session feedback prompt and grammar analysi

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-04T00:47:54.325Z

## User

our custom model can interect to the session feedback prompt and grammar analysis prompt?

## Assistant

Short answer: **technically yes, but with caveats.**

Here's the breakdown:

---

## 1. CEFR Evaluation prompt ✅ Fully compatible
The ConversationModel was **explicitly trained** on `EVALUATION_GENERATION_PROMPT`. It knows the `<think>…</think>` + JSON output format. This is a first-class use case for the model.

---

## 2. Session Feedback prompt ⚠️ General capability, not trained
The feedback prompt asks for a "2–3 sentence encouragement paragraph." The model was never trained on this task — it works as a general LLM capability. A 4B model can do it, but:
- Output quality may be inconsistent
- It might over-explain or go off-format

---

## 3. Grammar Analysis prompt ⚠️ Two problems

**Problem 1 — Not trained on this task:**  
Same as feedback — the model wasn't trained to score grammar 0–100. It can make a reasonable attempt but accuracy isn't guaranteed.

**Problem 2 — `json_schema` response format:**  
`scoreGrammar` uses `structured()` which sends:
```json
{ "response_format": { "type": "json_schema", "json_schema": {...} } }
```
llama.cpp supports this **only when compiled with grammar support** (`--grammar` or `--json-schema`). If your llama.cpp server doesn't have it enabled, the call will fail or be ignored — the model will return free text instead of JSON.

---

## Recommendation

| Prompt | Use custom model? |
|---|---|
| Conversation reply | ✅ Yes — trained for it |
| CEFR evaluation | ✅ Yes — trained for it |
| Session feedback | ✅ Fine — simple text generation, low stakes |
| Grammar analysis | ⚠️ Test it. If `json_schema` isn't supported by your llama.cpp build, `scoreGrammar` returns `null` gracefully and the session still scores without grammar data |

The grammar and feedback tasks could also be offloaded to a second, lighter model (or just Anthropic as fallback) if quality is a concern. But since `scoreGrammar` already handles `null` returns gracefully, you can just let it fail silently until you've tested the model on those tasks.
