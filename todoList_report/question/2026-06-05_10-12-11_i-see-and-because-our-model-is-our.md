# I see, and because our model is our own custom model, the server reply will not 

Session: `40c2c32e-4bcc-4826-8449-440738f22ef6`
Saved: 2026-06-05T01:12:11.297Z

## User

I see, and because our model is our own custom model, the server reply will not match exactly with the open-ai like or llama like.
My thinks is correct?  our custom model is based on Qwen 3 4b(student) and 9b(tutor)

## Assistant

Let me check what the backend expects from the AI response format for both chat and evaluation.

## Assistant

Your thinking is correct — and the code already has Qwen3-specific handling built in. Here's the full picture:

---

## The backend uses OpenAI-compatible API format

[openai-compatible.provider.ts:79-87](backend/src/ai/providers/openai-compatible.provider.ts#L79-L87)

```ts
const res = await this.client.chat.completions.create({
  model: this.chatModel,
  messages: [
    { role: 'system', content: systemPrompt },
    ...req.messages.map(m => ({ role: m.role, content: m.content })),
  ],
  max_tokens: req.maxTokens ?? 400,
  temperature: req.temperature ?? 0.8,
});
```

So your custom model just needs to expose an **OpenAI-compatible `/v1/chat/completions` endpoint** — which llama.cpp, Ollama, LM Studio, and vLLM all do. The request format is standard.

---

## The response parsing is the tricky part

Qwen3 reasoning models return output in a non-standard way. The code already handles this at [openai-compatible.provider.ts:191-215](backend/src/ai/providers/openai-compatible.provider.ts#L191-L215):

```ts
private extractAssistantText(message): string {
  const content = message.content?.trim() ?? '';
  if (content) return content;   // ← standard case

  // Qwen3/reasoning models sometimes put reply in reasoning_content
  // instead of content when max_tokens is too low
  const reasoning = message.reasoning_content?.trim();
  ...
}
```

The comment at line 92 is explicit:
> *"Model returned empty assistant content (common with Qwen3 reasoning when max_tokens is too low). Raise max_tokens or disable reasoning in LM Studio."*

---

## The `AI_DISABLE_THINKING` env var

[openai-compatible.provider.ts:44-46](backend/src/ai/providers/openai-compatible.provider.ts#L44-L46)

```ts
// Set AI_DISABLE_THINKING=true for Qwen3/DeepSeek reasoning models to stop
// them spending all tokens inside <think>…</think> with no actual reply.
this.disableThinking = config.get<string>('AI_DISABLE_THINKING') === 'true';
```

This flag exists specifically for Qwen3. However — looking further at the code — **`disableThinking` is read but never applied** to the API call. It was planned but not yet implemented. You would need to either:

- Pass `enable_thinking: false` as an extra body param (llama.cpp style), or
- Rely on the `/no_think` suffix that `PromptBuilderService` appends to conversation system prompts

---

## Summary of what your Qwen3 model needs to produce

| Call type | What backend expects |
|---|---|
| **Chat (tutor)** | Any text in `choices[0].message.content`. Optionally wrapped in `<think>…</think>` — that is stripped by the system prompt's `/no_think` directive |
| **Evaluation** | A JSON block `{...}` somewhere in `content`, with `scores.fluency`, `scores.accuracy`, `scores.vocabulary`, `scores.interaction`, `scores.topic_adherence`. Optional prose before the `{` becomes `session_feedback` |

The API wire format (HTTP request/response JSON) is fully standard OpenAI-compatible — your Qwen3 serving layer (vLLM, llama.cpp, Ollama) handles that translation transparently.
