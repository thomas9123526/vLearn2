# I have one question. After we send evalution prompt by creating new session to e

Session: `40c2c32e-4bcc-4826-8449-440738f22ef6`
Saved: 2026-06-05T00:45:41.697Z

## User

I have one question. After we send evalution prompt by creating new session to evaluate the conversation between user and ai provider, We get evalution response.
Where is the backend code part that anylyse the evalution response?

## Assistant

Let me read the relevant section of the orchestrator.

## Assistant

Here's the full analysis pipeline in [conversation.orchestrator.ts](backend/src/ai/conversation.orchestrator.ts):

---

### 1. Build the user message (lines 209–243)

Formats the transcript into `[USER turn N]` / `[TUTOR]` lines, then wraps it with metadata:
```
Target CEFR level: A1
Tutor role: Emma -- a friendly teacher
Learner role: an adult English learner

Assigned topic: Shopping at a market
...
Transcript:
[USER turn 0] Hello. I am Li...
[TUTOR] Hello! Welcome to the market...
```

### 2. Build the system prompt (line 246)

```ts
const systemPrompt = await this.prompts.buildEvaluationSystemPrompt(sc);
```
This loads the examiner prompt from the DB (`evaluation_system` template), resolves `{country_adjective}` etc., and appends `/think`.

### 3. Send to AI (lines 263–269)

Single-turn call: `maxTokens: 1500`, `temperature: 0.3`, no prompt cache.

### 4. Parse the response (lines 286–299) — **the analysis step**

```ts
// Strip <think>…</think>
const afterThink = text.includes('</think>')
  ? text.slice(text.indexOf('</think>') + 8).trim()
  : text.trim();

// Find the JSON object boundaries
const jsonStart = afterThink.indexOf('{');
const jsonEnd   = afterThink.lastIndexOf('}');

// Any prose BEFORE the first '{' = session_feedback paragraph
const sessionFeedback = jsonStart > 0
  ? afterThink.slice(0, jsonStart).trim()
  : '';

// Parse the structured JSON (EvaluationOutput schema)
const parsed = JSON.parse(afterThink.slice(jsonStart, jsonEnd + 1));

return { ...parsed, session_feedback: sessionFeedback };
```

The logic expects the model to output:
```
<think>internal reasoning...</think>
[Optional feedback paragraph in prose]
{"overall_cefr_estimate": "A1", "scores": {...}, "strengths": [...], ...}
```

Everything before `{` after stripping `<think>` becomes `session_feedback`. The JSON is parsed into `EvaluationResult`.
