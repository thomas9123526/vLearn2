# I want know more about how can i use 'think' parameters for our custom model and

Session: `40c2c32e-4bcc-4826-8449-440738f22ef6`
Saved: 2026-06-05T01:19:04.016Z

## User

I want know more about how can i use 'think' parameters for our custom model and the situation of our project where we handle think and how our project manage think for session start system prompt and evalution system prompt

## Assistant

Let me read the prompt builder to see exactly how think directives are applied.

## Assistant

Now I have everything. Here's the complete picture:

---

## How `/think` and `/no_think` work in Qwen3

These are **special tokens** in Qwen3's training. You put them at the end of the system prompt:

| Directive | Effect |
|---|---|
| `/think` | Model shows its internal reasoning inside `<think>…</think>` before replying |
| `/no_think` | Model skips the thinking block and replies directly |

They are not API parameters — just plain text appended to the system prompt.

---

## Situation 1: Tutor (chat) system prompt

**Where thinking is controlled:**

[prompt-builder.service.ts:51-52](backend/src/ai/prompt-builder.service.ts#L51-L52) — the flag is read from `.env`:
```ts
/** When true, appends /no_think at the end of conversation system prompts. */
readonly disableThinking: boolean;
// reads: AI_DISABLE_THINKING=true from .env
```

[prompt-builder.service.ts:245](backend/src/ai/prompt-builder.service.ts#L245) — applied at the end of the section builder:
```ts
return this.disableThinking ? `${sections}\n/no_think` : sections;
```

**But** — this only runs in Priority 3 (section builder). If a DB template or `custom_prompt` is used (Priority 1 or 2), **no `/think` or `/no_think` is appended at all**.

**Conclusion for tutor:** thinking is **OFF by default** (no directive) unless `AI_DISABLE_THINKING=true` explicitly adds `/no_think` via the section builder path.

---

## Situation 2: Evaluation system prompt

[prompt-builder.service.ts:128-139](backend/src/ai/prompt-builder.service.ts#L128-L139)

```ts
async buildEvaluationSystemPrompt(scenario): Promise<string> {
  const tpl = await this.loadTemplate('evaluation_system');
  const base = tpl ?? DEFAULT_EVALUATION_SYSTEM;
  const vars = await this.resolvePromptVars(scenario);
  const rendered = base.replace(/\{(\w+)\}/g, (_m, key) => vars[key] ?? '');

  return `${rendered}\n/think`;   // ← ALWAYS appends /think, unconditionally
}
```

**Conclusion for evaluation:** thinking is **always ON** (`/think` hardcoded) — the model is expected to reason about the scores before producing JSON.

---

## The gap: `AI_DISABLE_THINKING` flag is not applied to evaluation

[openai-compatible.provider.ts:44-46](backend/src/ai/providers/openai-compatible.provider.ts#L44-L46)

```ts
// Set AI_DISABLE_THINKING=true for Qwen3/DeepSeek reasoning models to stop
// them spending all tokens inside <think>…</think> with no actual reply.
this.disableThinking = config.get<string>('AI_DISABLE_THINKING') === 'true';
```

The flag is **read** in the provider but **never used** — no code path in the provider actually passes `enable_thinking: false` to the API call. The only real effect of `AI_DISABLE_THINKING=true` is via the section builder at line 245.

---

## Full map of the two call types

```
┌─────────────────────────────────────────────────────────────────┐
│  TUTOR CHAT  (generateTutorReply)                               │
│  maxTokens: 1024,  temperature: 0.8                             │
│                                                                 │
│  System prompt ending:                                          │
│    AI_DISABLE_THINKING=false (default) → no directive           │
│    AI_DISABLE_THINKING=true            → \n/no_think            │
│                                                                 │
│  Parser: uses res.content directly — no think stripping         │
│  (model reply goes straight to Flutter as tutor text)           │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  EVALUATION  (evaluateSession)                                  │
│  maxTokens: 1500,  temperature: 0.3                             │
│                                                                 │
│  System prompt ending: always \n/think  (hardcoded line 138)    │
│                                                                 │
│  Parser at orchestrator.ts:286-299:                             │
│    1. Strip <think>…</think>                                     │
│    2. Prose before '{' → session_feedback                        │
│    3. JSON block → EvaluationResult scores                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Recommendation for your Qwen3 4B/9B setup

| Env var | Recommended value | Reason |
|---|---|---|
| `AI_DISABLE_THINKING` | `true` | Tutor chat with `/no_think` keeps replies fast; Qwen3 4B doesn't need reasoning for casual conversation |
| Evaluation | Leave as-is | `/think` is hardcoded and the parser strips it — reasoning actually helps produce better scores |
| `AI_CHAT_MODEL` | your Qwen3 4B model name | Fast, conversational |
| `AI_ANALYSIS_MODEL` | your Qwen3 9B model name | Slower, more careful scoring |
