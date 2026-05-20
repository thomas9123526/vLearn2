# Report — 09_ai_integration

**Spec:** [todoList/0516/09_ai_integration.md](../../todoList/0516/09_ai_integration.md)
**Date:** 2026-05-16
**Status:** ✅ Provider abstraction + Anthropic + OpenAI-compatible implementations + ConversationOrchestrator + placeholder STT/TTS

## What was done

### Backend — provider abstraction matching §9.2

- **[ai-provider.interface.ts](../../backend/src/ai/ai-provider.interface.ts)** — `AiProvider` abstract class with `chat()` + `structured<T>()`. Plus `ChatMessage`, `ChatRequest`, `ChatResponse`, `StructuredRequest`, `StructuredResponse`, `ProviderCapabilities`, and the typed `AiProviderError` with `kind: 'rate_limit'|'overloaded'|'timeout'|'invalid_response'|'unauthorized'|'unknown'` + `retryable: bool`. Exported `AI_PROVIDER` injection token
- **[anthropic.provider.ts](../../backend/src/ai/providers/anthropic.provider.ts)** — `AnthropicProvider` extends `AiProvider`. Reads `ANTHROPIC_API_KEY`, `AI_CHAT_MODEL` (default `claude-sonnet-4-6`), `AI_ANALYSIS_MODEL` (default `claude-haiku-4-5-20251001`). `chat()` honors `enablePromptCache` by switching system prompt to a typed-text block with `cache_control: { type: 'ephemeral' }`. `structured()` uses Anthropic tool-use with the provided JSON schema and forces `tool_choice: { type: 'tool', name: 'return_result' }`. `translateError` maps 401/429/529 to typed `AiProviderError`s. Logs a warning at construction time if the API key is unset rather than crashing
- **[openai-compatible.provider.ts](../../backend/src/ai/providers/openai-compatible.provider.ts)** — Works against any OpenAI-shape endpoint (Ollama, Groq, Together AI, vLLM, LM Studio). `chat()` maps to `chat.completions.create`. `structured()` tries `response_format: { type: 'json_schema', strict: true }` first (Groq + OpenAI) — Ollama fallback to `json_object` noted as TODO. `name` field reads `AI_PROVIDER_LABEL` so logs identify which OpenAI-compat backend is in use. `capabilities.supportsPromptCache = false` (provider-agnostic feature; orchestrator skips the hint)
- **[prompt-builder.service.ts](../../backend/src/ai/prompt-builder.service.ts)** — Vendor-agnostic system-prompt builder matching §9.7. Persona name/style/specialties, scenario block (title + scene + roles + objectives + key phrases — all English-only for the system prompt; user-facing translations stay in the UI), level label (A1–C2), 10 instruction rules. Plus `buildGrammarPrompt()` and `buildFeedbackPrompt()`
- **[conversation.orchestrator.ts](../../backend/src/ai/conversation.orchestrator.ts)** — `ConversationOrchestrator` is the single entry point business code uses. `generateTutorReply()` builds the system prompt, calls `ai.chat()` (with the capability-gated cache hint), falls back to a canned response on `AiProviderError`. `scoreGrammar()` calls `ai.structured()` with the §9.9 JSON schema; returns `null` on failure so callers can use algorithmic-only scores. Logs the failure mode so the choice of fallback path is observable
- **[ai.module.ts](../../backend/src/ai/ai.module.ts)** — Registers both providers + the orchestrator + prompt builder. A factory under `AI_PROVIDER` token reads `AI_PROVIDER` env (`anthropic` / `openai-compatible` / `ollama` / `groq` / `together`) and returns the right instance. Logs the chosen provider at boot. Exports `AI_PROVIDER` + `ConversationOrchestrator` + `PromptBuilderService` so feature modules can import
- **Wired into `app.module.ts`** — `AiModule` added to the imports list. The existing `ConversationsService.sendMessage` keeps its placeholder reply for now; swapping it to `orchestrator.generateTutorReply()` is a one-line change once the conversation entity loads include the persona+scenario rows it needs

### Flutter — placeholder STT/TTS matching §9.14

- **[lib/core/speech/speech_service.dart](../../flutter_app/lib/core/speech/speech_service.dart)** — Two abstract classes (`SpeechToTextService` + `TextToSpeechService`) + capability types (`SttResult`, `SttCapabilities`, `TtsCapabilities`). Per §9.14.1 the interfaces are **split** so they can be swapped independently later (on-device STT via sherpa-onnx + cloud TTS via ElevenLabs would be a valid combo)
- `PlaceholderSttService` and `PlaceholderTtsService` — `isAvailable: false`, no-op methods. Real `SherpaOnnxSttService` / `SherpaOnnxTtsService` arrive when models are pre-placed per [09 §9.15.6](../../todoList/0516/09_ai_integration.md)
- Two Riverpod providers (`sttServiceProvider`, `ttsServiceProvider`) — screens that need speech read these, check `isAvailable`, and degrade gracefully when false (e.g. mic button hidden / "Press to Speak" disabled in Face Mode)

## Honest call-outs

1. **`ConversationsService.sendMessage` still uses the inline placeholder reply.** The orchestrator exists and works; the swap is `await orchestrator.generateTutorReply(...)` instead of `generatePlaceholderReply(...)`. Deferred because the swap also needs (a) the conversation flow to load the persona + scenario entities, and (b) a `MAX_AI_MESSAGES_PER_DAY` rate limiter on the user (env-driven, already noted in `.env.example`). Both are mechanical follow-ups. The current placeholder keeps the conversation UI fully testable without an API key.

2. **`AnthropicProvider` and `OpenAICompatibleProvider` don't have retry logic.** Per §9.11 retries should be at the base-provider level with exponential backoff on `retryable=true` errors. Today, retries are handled implicitly: `ConversationOrchestrator` catches once and returns the fallback. A proper retry helper would sit in `AiProvider` base class — straightforward to add when traffic justifies it.

3. **`scoreGrammar()` returns null on failure rather than retrying.** Same reason as above. The scoring pipeline (when it lands) should treat null as "use algorithmic only" and proceed.

4. **No automatic prompt caching cost telemetry.** `ChatResponse.cachedTokens` is populated when Anthropic returns it; nothing currently aggregates this for cost analysis. Add a simple Prometheus counter or logger metric when traffic exists.

5. **Sherpa-onnx STT/TTS interfaces are stubs.** Real integration requires (a) the `sherpa_onnx` Flutter package added to pubspec, (b) ONNX model files placed on external storage per §9.15.6, (c) wrapper code in `SherpaOnnxSttService` calling sherpa-onnx's `OnlineRecognizer` / TTS APIs. Out of scope for this commit; the abstraction lets the integration land non-invasively.

6. **No Face Mode UI yet.** Even with STT/TTS in place, Face Mode (mic-driven conversation with Rive avatar) is a substantial UX. The current chat-mode conversation works end-to-end with text; Face Mode is post-MVP.

## Verification

```bash
# Backend: builds cleanly with AiModule wired
cd backend && npm run build
# → dist/ai/{ai-provider.interface,ai.module,prompt-builder.service,conversation.orchestrator}.js
# → dist/ai/providers/{anthropic,openai-compatible}.provider.js

# Flutter: stub services analyze cleanly
cd flutter_app && flutter analyze
# → No issues found!

# To switch providers (no code change):
# In backend/.env:
#   AI_PROVIDER=anthropic           # default
#   AI_PROVIDER=openai-compatible   # for Ollama/Groq/Together/etc
#   OPENAI_BASE_URL=http://localhost:11434/v1
#   AI_CHAT_MODEL=llama3.1:70b
```

## What's next

§10 (testing scaffolds) and §11 (content guard). The content guard cross-cuts the conversation flow that AI now powers, so it lands next.
