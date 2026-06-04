# i have the code for our ai provider. In the  'D:\Upload_HKC\Pending\Conversation

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-04T00:04:01.208Z

## User

i have the code for our ai provider.
In the  'D:\Upload_HKC\Pending\ConversationModel', I have the code.
In this code we can find out system prompt used and evaluation prompt and how they are used.

Can you first analyze the code and have a clean picture what do we have to do on our project so our application can interact with our own model properly

## Assistant

Now let me also read the current vLearn2 AI provider setup to map the gap:

## Assistant

Good picture now. Here's the complete gap analysis:

---

## What vLearn2 already has (no changes needed)

| ✅ Already works | Why |
|---|---|
| OpenAI-compatible HTTP client | `openai-compatible.provider.ts` → `/v1/chat/completions` |
| Qwen3.5 model configured | `.env`: `OPENAI_BASE_URL=http://192.168.135.32:8081/v1`, model `Qwen3.5-4B-UD-Q4_K_XL.gguf` |
| `/no_think` injection | `AI_DISABLE_THINKING=true` already prepends it |
| `<think>` stripping from reply | provider already extracts `reasoning_content` fallback |
| CEFR numeric→label conversion | `CEFR_LABELS[]` in `conversation.orchestrator.ts` |
| Evaluation JSON parsing | already strips `<think>…</think>`, extracts JSON |

---

## What needs to change

### 1. System prompt format (biggest change)

vLearn2's `buildCchPrompt()` generates **section-tag format**:
```
[role] You are Maya...
[learner] Native language: Korean...
[topic] Ordering food...
```

The custom model was **trained on** the ConversationModel's prose format:
```
You are a patient English conversation tutor for Korean adult learners...
Ground every conversation in Korean daily life...
Stay clear of politics, religion...
Scenario Topic: Ordering food at a restaurant
Your Role: Waiter – ...
/no_think
```

`buildCchPrompt()` needs to be rewritten to output the trained format, with `/no_think` at the **end** (not prepended at the top).

---

### 2. `/no_think` placement

The ConversationModel puts `/no_think` at the **end** of the system prompt. vLearn2 currently **prepends** it via `AI_DISABLE_THINKING=true` in the provider. For the trained model to behave correctly, it should come at the end.

Fix: remove the prepend from `openai-compatible.provider.ts`, let `prompt-builder.service.ts` append it to conversation prompts.

---

### 3. Evaluation prompt uses `/think`, not `/no_think`

The ConversationModel's evaluation system prompt ends with `/think` (to enable the `<think>…</think>` reasoning block). But right now `AI_DISABLE_THINKING=true` would suppress thinking for ALL calls including evaluation.

Fix: the evaluation path in `evaluateSession()` needs to bypass the `/no_think` injection and use a system prompt that ends with `/think`.

---

### 4. Locale mapping

vLearn2 has `userNativeLanguage` (e.g. `"ko"`, `"zh"`, `"ja"`). The ConversationModel's prompt builder takes a locale name (`"china"`, `"japan"`, `"italy"`) to fill in locale-grounding text (cities, foods, cultural items).

Need: a small mapping table + a default fallback for unsupported locales.

---

### 5. Model URL (when custom model is deployed)

Currently pointing at LM Studio on `192.168.135.32:8081`. When your custom llama.cpp server is running (via `scripts/start_llama_cpp.sh`), just update `.env`:
```
OPENAI_BASE_URL=http://<host>:<port>/v1
AI_CHAT_MODEL=<your-gguf-filename>
```
No code change needed.

---

## Summary of work

| # | What | Files | Size |
|---|---|---|---|
| 1 | Rewrite `buildCchPrompt()` to match trained prompt format | `prompt-builder.service.ts` | Large |
| 2 | Move `/no_think` from provider-prepend to end of prompt builder | `openai-compatible.provider.ts` + `prompt-builder.service.ts` | Small |
| 3 | Fix evaluation to use `/think` and bypass the disable-thinking flag | `conversation.orchestrator.ts` | Small |
| 4 | Add locale mapping (`userNativeLanguage` → `china/japan/italy`) | `prompt-builder.service.ts` | Small |
| 5 | Update `.env` to point at custom model server | `.env` | Trivial |

Want me to start implementing? I'd do it in that order — #1 is the core that everything else depends on.
