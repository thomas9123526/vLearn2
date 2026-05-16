# 09 – AI Integration (Provider-Agnostic)

## 9.1 Overview & Provider Strategy

The backend talks to an LLM through a **provider-abstraction layer**, not directly to any vendor.
This lets the MVP ship on Anthropic Claude (best pedagogical quality) while keeping the door open
to swap in Llama (Ollama / Groq / Together / vLLM) for cost, self-hosting, or experimentation —
without touching business logic.

| Layer | Concern | Vendor-aware? |
|-------|---------|---------------|
| Controllers / Services | Business logic, scoring, sessions | No |
| `AiProvider` interface | Contract for chat + structured calls | No |
| `AnthropicProvider` | Implementation #1 (MVP default) | Yes |
| `OpenAICompatibleProvider` | Implementation #2 (Llama via Ollama/Groq/Together/vLLM/LM Studio) | Yes |
| `AiProviderFactory` | Picks impl from `AI_PROVIDER` env var | Yes |

**Default models (MVP):**
- **Conversation replies:** `claude-sonnet-4-6` (high quality, conversational)
- **Scoring analysis:** `claude-haiku-4-5-20251001` (fast, cheap, structured)
- **Prompt caching:** Anthropic-only optimization (gated by provider capability flag)

**Switchable via env:**
```
AI_PROVIDER=anthropic          # default
# or
AI_PROVIDER=openai-compatible  # for Ollama, Groq, Together, vLLM, LM Studio
OPENAI_BASE_URL=http://localhost:11434/v1   # Ollama example
OPENAI_API_KEY=ollama                       # any value for local
AI_CHAT_MODEL=llama3.1:70b
AI_ANALYSIS_MODEL=llama3.1:8b
```

---

## 9.2 AiProvider Interface (Abstract)

**File:** `src/ai/ai-provider.interface.ts`

```typescript
export interface ChatMessage {
  role: 'user' | 'assistant';
  content: string;
}

export interface ChatRequest {
  systemPrompt: string;
  messages: ChatMessage[];
  maxTokens?: number;
  temperature?: number;
  /** Hint for the provider; ignored if unsupported. */
  enablePromptCache?: boolean;
}

export interface ChatResponse {
  content: string;
  inputTokens: number;
  outputTokens: number;
  cachedTokens?: number;     // anthropic-specific
  modelUsed: string;
  latencyMs: number;
}

export interface StructuredRequest<T> {
  systemPrompt: string;
  userPrompt: string;
  jsonSchema: object;        // JSON Schema describing T
  maxTokens?: number;
}

export interface StructuredResponse<T> {
  data: T;
  inputTokens: number;
  outputTokens: number;
  modelUsed: string;
}

export interface ProviderCapabilities {
  supportsPromptCache: boolean;
  supportsStructuredOutput: boolean;   // native JSON mode
  supportsStreaming: boolean;
  contextWindowTokens: number;
}

export abstract class AiProvider {
  abstract readonly name: string;
  abstract readonly capabilities: ProviderCapabilities;

  /** Conversational reply for the tutor. */
  abstract chat(req: ChatRequest): Promise<ChatResponse>;

  /** Structured JSON output for scoring/analysis. Must validate against schema. */
  abstract structured<T>(req: StructuredRequest<T>): Promise<StructuredResponse<T>>;

  /** Optional streaming variant — default impl wraps chat() as a single chunk. */
  async *chatStream(req: ChatRequest): AsyncIterable<string> {
    const result = await this.chat(req);
    yield result.content;
  }
}
```

- [ ] **9.2.1** Define `ChatMessage`, `ChatRequest`, `ChatResponse`, `StructuredRequest`, `StructuredResponse`, `ProviderCapabilities`
- [ ] **9.2.2** Define `AiProvider` abstract class
- [ ] **9.2.3** All business code depends ONLY on this interface — never on Anthropic SDK directly

---

## 9.3 AnthropicProvider (Implementation #1)

**File:** `src/ai/providers/anthropic.provider.ts`

```typescript
@Injectable()
export class AnthropicProvider extends AiProvider {
  readonly name = 'anthropic';
  readonly capabilities: ProviderCapabilities = {
    supportsPromptCache: true,
    supportsStructuredOutput: true,
    supportsStreaming: true,
    contextWindowTokens: 200_000,
  };
  
  private client: Anthropic;
  private chatModel: string;
  private analysisModel: string;
  
  constructor(private config: ConfigService) {
    super();
    this.client = new Anthropic({ apiKey: config.get('ANTHROPIC_API_KEY') });
    this.chatModel = config.get('AI_CHAT_MODEL') ?? 'claude-sonnet-4-6';
    this.analysisModel = config.get('AI_ANALYSIS_MODEL') ?? 'claude-haiku-4-5-20251001';
  }
  
  async chat(req: ChatRequest): Promise<ChatResponse> { /* uses messages.create */ }
  async structured<T>(req: StructuredRequest<T>): Promise<StructuredResponse<T>> { /* tool use with JSON schema */ }
}
```

- [ ] **9.3.1** Wrap `@anthropic-ai/sdk` calls
- [ ] **9.3.2** Map `enablePromptCache: true` → inject `cache_control: { type: 'ephemeral' }` on system block
- [ ] **9.3.3** Implement structured output via Anthropic tool use (native JSON validation)
- [ ] **9.3.4** Translate Anthropic-specific errors → provider-agnostic `AiProviderError`
- [ ] **9.3.5** Token usage extracted from `response.usage` (input/output/cache_read)

---

## 9.4 OpenAICompatibleProvider (Implementation #2 — Llama & friends)

**File:** `src/ai/providers/openai-compatible.provider.ts`

Targets any backend that speaks the OpenAI Chat Completions API shape:
- **Ollama** (`http://localhost:11434/v1`) — local Llama, Qwen, Mistral
- **Groq** (`https://api.groq.com/openai/v1`) — fastest hosted Llama
- **Together AI** (`https://api.together.xyz/v1`) — broad model catalog
- **vLLM** / **LM Studio** / **Fireworks** — self-hosted or hosted

```typescript
@Injectable()
export class OpenAICompatibleProvider extends AiProvider {
  readonly name: string;       // 'ollama' | 'groq' | 'together' | etc.
  readonly capabilities: ProviderCapabilities = {
    supportsPromptCache: false,           // not a vendor-agnostic feature
    supportsStructuredOutput: true,       // via response_format: json_schema (Groq/OpenAI) or json_object (Ollama)
    supportsStreaming: true,
    contextWindowTokens: 128_000,         // configurable per backend
  };
  
  private client: OpenAI;                 // openai SDK with custom baseURL
  
  constructor(private config: ConfigService) {
    super();
    this.client = new OpenAI({
      baseURL: config.get('OPENAI_BASE_URL'),
      apiKey: config.get('OPENAI_API_KEY') ?? 'not-needed',
    });
    this.name = config.get('AI_PROVIDER_LABEL') ?? 'openai-compatible';
  }
  
  async chat(req: ChatRequest): Promise<ChatResponse> { /* chat.completions.create */ }
  async structured<T>(req: StructuredRequest<T>): Promise<StructuredResponse<T>> {
    // Try response_format: { type: 'json_schema', json_schema: ... } first
    // Fall back to { type: 'json_object' } + retry on parse failure
  }
}
```

- [ ] **9.4.1** Use the official `openai` npm SDK with overridden `baseURL`
- [ ] **9.4.2** Convert `ChatRequest` → OpenAI message array (system + user/assistant roles)
- [ ] **9.4.3** Implement `structured()` with `response_format: { type: 'json_schema', json_schema: { name, schema, strict: true } }` for Groq/OpenAI-compatible servers that support it
- [ ] **9.4.4** Fallback: `response_format: { type: 'json_object' }` + manual schema validation + 1 retry on parse failure (Ollama and older endpoints)
- [ ] **9.4.5** Map errors (429, 5xx, timeouts) → `AiProviderError`
- [ ] **9.4.6** No prompt cache — `enablePromptCache` hint is silently ignored

---

## 9.5 Provider Factory & Configuration

**File:** `src/ai/ai-provider.factory.ts`

```typescript
@Injectable()
export class AiProviderFactory {
  constructor(
    private config: ConfigService,
    private anthropic: AnthropicProvider,
    private openai: OpenAICompatibleProvider,
  ) {}
  
  create(): AiProvider {
    const kind = this.config.get<string>('AI_PROVIDER') ?? 'anthropic';
    switch (kind) {
      case 'anthropic': return this.anthropic;
      case 'openai-compatible':
      case 'ollama':
      case 'groq':
      case 'together':
        return this.openai;
      default: throw new Error(`Unknown AI_PROVIDER: ${kind}`);
    }
  }
}
```

**NestJS DI binding** (`src/ai/ai.module.ts`):
```typescript
@Module({
  providers: [
    AnthropicProvider,
    OpenAICompatibleProvider,
    AiProviderFactory,
    {
      provide: 'AI_PROVIDER',
      useFactory: (factory: AiProviderFactory) => factory.create(),
      inject: [AiProviderFactory],
    },
  ],
  exports: ['AI_PROVIDER'],
})
export class AiModule {}
```

Then consumers inject the interface:
```typescript
constructor(@Inject('AI_PROVIDER') private ai: AiProvider) {}
```

- [ ] **9.5.1** Factory reads `AI_PROVIDER` at startup
- [ ] **9.5.2** Both providers registered, only the selected one is exported as `AI_PROVIDER` token
- [ ] **9.5.3** Health check endpoint `/health/ai` calls a minimal completion to verify provider works
- [ ] **9.5.4** Log selected provider + model on boot

---

## 9.6 ConversationOrchestrator (Provider-Agnostic)

**File:** `src/conversations/conversation.orchestrator.ts`

```typescript
@Injectable()
export class ConversationOrchestrator {
  constructor(
    @Inject('AI_PROVIDER') private ai: AiProvider,
    private prompts: PromptBuilderService,
  ) {}
  
  async generateTutorReply(session: Session, history: ChatMessage[]): Promise<string> {
    const systemPrompt = this.prompts.buildSystemPrompt(session.persona, session.scenario, session.user.level);
    const result = await this.ai.chat({
      systemPrompt,
      messages: history,
      maxTokens: 300,
      temperature: 0.8,
      enablePromptCache: this.ai.capabilities.supportsPromptCache,
    });
    return result.content;
  }
  
  async scoreGrammar(userMessages: string[], level: number): Promise<GrammarAnalysis> {
    const { data } = await this.ai.structured<GrammarAnalysis>({
      systemPrompt: 'You are an expert English grammar evaluator.',
      userPrompt: this.prompts.buildGrammarPrompt(userMessages, level),
      jsonSchema: GRAMMAR_ANALYSIS_SCHEMA,
      maxTokens: 500,
    });
    return data;
  }
  
  async generateFeedback(summary: SessionSummary): Promise<string> {
    const result = await this.ai.chat({
      systemPrompt: 'You are an encouraging English tutor.',
      messages: [{ role: 'user', content: this.prompts.buildFeedbackPrompt(summary) }],
      maxTokens: 150,
      temperature: 0.7,
    });
    return result.content;
  }
}
```

- [ ] **9.6.1** All conversation/scoring logic goes through the `AiProvider` interface — never the concrete provider
- [ ] **9.6.2** Use `ai.capabilities` to conditionally pass `enablePromptCache`
- [ ] **9.6.3** Orchestrator is the only place that combines prompts + provider calls

---

## 9.7 System Prompt Builder (Provider-Agnostic)

**File:** `src/ai/prompt-builder.service.ts`

Plain string output — no vendor-specific tokens or directives.

### Persona Personalities
| Persona | Personality | Teaching Style |
|---------|------------|----------------|
| Maya | Warm, encouraging, patient | Positive reinforcement, gentle corrections |
| Leo | Energetic, fun, casual | Games, humor, casual language |
| Sofia | Precise, professional | Formal corrections, structured feedback |
| Theo | Intellectual, curious | Socratic method, questions, depth |

### System Prompt Template
```
You are {persona.name}, an English language tutor with a {persona.style} teaching style.
Your specialties include: {persona.specialties.join(', ')}.

CURRENT SCENARIO:
{scenario ? `
Title: {scenario.title.en}
Setting: {scenario.scene_description.en}
Your role: {scenario.tutor_role.en}
User's role: {scenario.user_role.en}
Objectives: {scenario.objectives.en.join(', ')}
Key phrases to encourage: {scenario.key_phrases.map(p=>p.phrase).join(', ')}
` : 'Free conversation practice - no specific scenario.'}

USER PROFILE:
- English level: {levelLabel} ({level}/6 where 1=A1, 6=C2)
- Native language: {user.native_language}

INSTRUCTIONS:
1. Stay in character as {persona.name} throughout
2. Adjust vocabulary and sentence complexity to level {level}/6
3. Respond naturally and conversationally (2-4 sentences usually)
4. Correct grammar errors GENTLY and IMPLICITLY by modeling correct usage in your reply
5. Celebrate good English! Use encouragement appropriate to your personality
6. If objectives exist, naturally guide conversation toward them
7. Encourage use of the key phrases when appropriate
8. Do NOT explicitly state you are an AI unless directly asked
9. Do NOT break character
10. If the user writes in their native language, gently encourage English with a translation hint
```

- [ ] **9.7.1** Build system prompt per session on start
- [ ] **9.7.2** Cache hint is passed through `ChatRequest.enablePromptCache` — provider decides whether to honor it
- [ ] **9.7.3** Level-appropriate vocabulary guidance injected per level
- [ ] **9.7.4** Prompt text is identical across providers (no vendor-specific markers)

---

## 9.8 Conversation Message Format

```typescript
function toChatMessages(messages: DbMessage[]): ChatMessage[] {
  return messages.map(m => ({ role: m.role, content: m.content }));
}
```

- [ ] **9.8.1** First message: tutor greeting (generated by AI on session start) or hardcoded welcome
- [ ] **9.8.2** Keep full history in context (session limited to 50 turns)
- [ ] **9.8.3** Cache hint passed via `enablePromptCache` — provider applies vendor-specific cache markers internally

---

## 9.9 Grammar Analysis (Structured Output)

Used after session ends to compute grammar score. Calls `ai.structured()` so each provider applies its best JSON-mode.

```typescript
const GRAMMAR_ANALYSIS_SCHEMA = {
  type: 'object',
  properties: {
    grammar_score: { type: 'integer', minimum: 0, maximum: 100 },
    errors_found: { type: 'array', items: { type: 'string' } },
    strengths: { type: 'array', items: { type: 'string' } },
  },
  required: ['grammar_score', 'errors_found', 'strengths'],
  additionalProperties: false,
};
```

User prompt:
```
Analyze the grammar quality of these English messages from a level {level}/6 English learner.

Messages:
{userMessages.map((m, i) => `${i+1}. "${m}"`).join('\n')}

Grammar score guidelines:
- 0-30: Many basic errors (wrong tense, subject-verb, articles)
- 31-60: Some errors, mostly understandable
- 61-80: Few errors, good grammatical control
- 81-100: Very few/no errors, sophisticated usage
```

- [ ] **9.9.1** Call after session ends (async, doesn't block response)
- [ ] **9.9.2** Use `ai.structured()` — provider handles JSON validation
- [ ] **9.9.3** Use the cheaper analysis model (Haiku on Anthropic; smaller Llama on OpenAI-compatible)
- [ ] **9.9.4** Store in `session_scores.grammar_score` + `strengths[]` + `improvements[]`
- [ ] **9.9.5** On validation failure: retry once, then fall back to grammar_score = 50

---

## 9.10 Session Feedback Prompt

Plain chat call — provider-agnostic.

```
Write a 2-3 sentence encouraging feedback paragraph for an English learner.

Session data:
- Scenario: {summary.scenarioTitle}
- Overall score: {summary.overallScore}/100
- Fluency: {summary.fluencyScore}/100
- Vocabulary: {summary.vocabularyScore}/100
- Grammar: {summary.grammarScore}/100
- Engagement: {summary.engagementScore}/100
- User level: {summary.levelLabel}
- Strongest area: {summary.strongestSkill}
- Area to improve: {summary.weakestSkill}

Write in a warm, motivating tone. Mention 1 specific thing they did well.
Keep it concise — max 60 words.
```

- [ ] **9.10.1** Call with session scores after scoring completes
- [ ] **9.10.2** Store in `session_scores.ai_feedback`

---

## 9.11 Error Handling & Resilience

Provider-agnostic at the orchestrator level; provider-specific retry policies inside each impl.

```typescript
export class AiProviderError extends Error {
  constructor(
    public readonly kind: 'rate_limit' | 'overloaded' | 'timeout' | 'invalid_response' | 'unknown',
    public readonly retryable: boolean,
    message: string,
    public readonly cause?: unknown,
  ) { super(message); }
}
```

- [ ] **9.11.1** Each provider maps native errors → `AiProviderError` with `retryable` flag
- [ ] **9.11.2** Retry on `retryable: true` (max 3 retries, exponential backoff: 1s, 2s, 4s) — implemented in base provider helper
- [ ] **9.11.3** Timeouts: 30s for chat, 15s for structured (configurable per provider)
- [ ] **9.11.4** Graceful fallback in orchestrator if provider unavailable:
  - Conversation: return "I'm having trouble right now, please try again in a moment."
  - Scoring: use algorithm-only scores, skip grammar AI score (set to 50)
- [ ] **9.11.5** Log all provider errors with session context (no user content in logs)
- [ ] **9.11.6** Rate limit guard: `ThrottlerModule` on `/conversations/sessions/:id/messages`

---

## 9.12 Cost Optimization (Per-Provider)

| Optimization | Anthropic | OpenAI-Compatible |
|--------------|-----------|-------------------|
| Prompt caching | ✅ via `cache_control` | ❌ ignored |
| Cheap analysis model | `claude-haiku-4-5-20251001` | `llama-3.1-8b` / `qwen2.5-7b` / configurable |
| Limit `max_tokens: 300` | ✅ applies | ✅ applies |
| Token usage logging | input + output + cached | input + output |
| Daily user limit | `MAX_AI_MESSAGES_PER_DAY` (default 100) | same |

- [ ] **9.12.1** Prompt caching: enabled only when `provider.capabilities.supportsPromptCache === true`
- [ ] **9.12.2** Limit `maxTokens: 300` for conversation across both providers
- [ ] **9.12.3** Track token usage per session in logs (use `ChatResponse.inputTokens` / `outputTokens` / `cachedTokens`)
- [ ] **9.12.4** Daily user limit: 100 AI messages/day (configurable via `MAX_AI_MESSAGES_PER_DAY`)
- [ ] **9.12.5** For Ollama (self-hosted): no per-token cost; instead track GPU time / response latency

---

## 9.13 Provider Selection Notes (Quality Trade-offs)

Honest read for picking a provider:

| Need | Best fit | Notes |
|------|----------|-------|
| MVP quality, pedagogical nuance | **Anthropic Claude** | Best at gentle implicit corrections, level-appropriate vocab, multilingual (ko/zh) |
| Lowest hosted cost | **Groq Llama 3.1 70B** | Very fast, ~10x cheaper than Sonnet; quality close-but-not-equal |
| Fully offline / on-prem | **Ollama + Llama 3.1 70B** | No per-token cost, requires GPU (40GB+ for 70B at decent quality) |
| Best multilingual (ko/zh) | **Anthropic** or **Qwen 2.5 72B** via Ollama | Llama base models weaker at CJK than Qwen |
| Reliable structured JSON | **Anthropic (tool use)** > **Groq (json_schema)** > **Ollama (json_object)** | Open models sometimes need retries |

**Recommended dev workflow:**
1. Build + ship MVP on Anthropic
2. Once stable, add `OpenAICompatibleProvider` and A/B test against Anthropic on real scenarios (compare scoring + feedback quality on a held-out set of sessions)
3. Switch (or route by user tier / cost budget) once parity is acceptable

- [ ] **9.13.1** Document chosen provider + model in README on each release
- [ ] **9.13.2** Keep an A/B harness: `AI_PROVIDER_SHADOW=anthropic` env runs a second provider in parallel on N% of requests for offline quality comparison (optional, post-MVP)

---

## 9.14 STT / TTS Provider Abstraction (Sherpa-ONNX Ready)

STT and TTS use the same provider-abstraction pattern as the AI layer. STT and TTS are **two separate interfaces** so they can be swapped independently — e.g. on-device STT (sherpa-onnx) + cloud TTS (ElevenLabs), or fully on-device for both.

**Planned production impl:** [`sherpa-onnx`](https://github.com/k2-fsa/sherpa-onnx) via the [`sherpa_onnx`](https://pub.dev/packages/sherpa_onnx) Flutter package — on-device, offline, multilingual (en/ko/zh), supports Android + Windows + the rest of Flutter's target platforms.

### 9.14.1 SpeechToTextService Interface

**File:** `lib/core/speech/stt_service.dart`

```dart
class SttResult {
  final String text;
  final double confidence;        // 0.0 - 1.0
  final Duration audioDuration;
  final String? detectedLanguage; // BCP-47 code if auto-detection enabled
  
  SttResult({required this.text, required this.confidence, required this.audioDuration, this.detectedLanguage});
}

class SttCapabilities {
  final bool supportsStreaming;
  final bool supportsLanguageDetection;
  final List<String> supportedLanguages;   // BCP-47 codes
  final bool onDevice;                      // no network required
}

abstract class SpeechToTextService {
  SttCapabilities get capabilities;
  bool get isAvailable;
  
  /// One-shot transcription of a complete audio clip.
  Future<SttResult> transcribe(Uint8List audioData, {String? language});
  
  /// Streaming transcription — yields partial results as audio arrives.
  /// Default impl wraps transcribe() as a single chunk.
  Stream<SttResult> transcribeStream(Stream<Uint8List> audioChunks, {String? language}) async* {
    final chunks = <int>[];
    await for (final chunk in audioChunks) { chunks.addAll(chunk); }
    yield await transcribe(Uint8List.fromList(chunks), language: language);
  }
  
  /// Lifecycle — call once at app start, dispose on signout.
  Future<void> initialize();
  Future<void> dispose();
}
```

### 9.14.2 TextToSpeechService Interface

**File:** `lib/core/speech/tts_service.dart`

```dart
class TtsCapabilities {
  final bool supportsStreaming;        // generate audio as it speaks
  final List<String> supportedLanguages;
  final List<String> availableVoices;  // voice IDs
  final bool onDevice;
}

abstract class TextToSpeechService {
  TtsCapabilities get capabilities;
  bool get isAvailable;
  
  /// Speak text using a specific persona's voice. Returns when playback finishes.
  Future<void> speak(String text, {required String voiceId, String? language, double rate = 1.0});
  
  /// Generate audio bytes without playing (e.g. for caching).
  Future<Uint8List> synthesize(String text, {required String voiceId, String? language, double rate = 1.0});
  
  Future<void> stop();
  Future<void> initialize();
  Future<void> dispose();
}
```

### 9.14.3 Placeholder Implementations (MVP)

**File:** `lib/core/speech/placeholder_speech.dart`

```dart
class PlaceholderSttService extends SpeechToTextService {
  @override
  bool get isAvailable => false;
  @override
  SttCapabilities get capabilities => const SttCapabilities(
    supportsStreaming: false, supportsLanguageDetection: false,
    supportedLanguages: [], onDevice: false,
  );
  @override
  Future<SttResult> transcribe(Uint8List audioData, {String? language}) async =>
    SttResult(text: '', confidence: 0, audioDuration: Duration.zero);
  @override Future<void> initialize() async {}
  @override Future<void> dispose() async {}
}

class PlaceholderTtsService extends TextToSpeechService {
  @override
  bool get isAvailable => false;
  @override
  TtsCapabilities get capabilities => const TtsCapabilities(
    supportsStreaming: false, supportedLanguages: [],
    availableVoices: [], onDevice: false,
  );
  @override
  Future<void> speak(String text, {required String voiceId, String? language, double rate = 1.0}) async {}
  @override
  Future<Uint8List> synthesize(String text, {required String voiceId, String? language, double rate = 1.0}) async =>
    Uint8List(0);
  @override Future<void> stop() async {}
  @override Future<void> initialize() async {}
  @override Future<void> dispose() async {}
}
```

- [ ] **9.14.3.1** Register `PlaceholderSttService` and `PlaceholderTtsService` as default Riverpod providers
- [ ] **9.14.3.2** Conversation screens check `service.isAvailable` before showing mic / speaker UI
- [ ] **9.14.3.3** Face mode "Press to Speak" button: disabled state with tooltip "Coming soon" when STT unavailable
- [ ] **9.14.3.4** Backend: `POST .../messages` accepts optional `audio_url` field (null for now)

### 9.14.4 Future: SherpaOnnxSttService (Stub)

**File (future):** `lib/core/speech/sherpa_onnx_stt.dart`

Wraps `package:sherpa_onnx` ASR models. Recommended model choices:

| Model | Languages | Size | Latency (mid-range Android) | Use case |
|-------|-----------|------|------------------------------|----------|
| **Whisper-tiny** (int8) | 99 langs | ~40 MB | ~400 ms | Default MVP — small, multilingual |
| **Whisper-base** (int8) | 99 langs | ~75 MB | ~700 ms | Higher quality, still acceptable |
| **Streaming Zipformer (multi-zh-en)** | en + zh | ~80 MB | ~150 ms streaming | Best for Face Mode live captions |
| **Paraformer (zh)** | zh | ~70 MB | ~200 ms streaming | If Chinese is primary user base |

- [ ] **9.14.4.1** Add `sherpa_onnx: ^<version>` to pubspec.yaml when implementing
- [ ] **9.14.4.2** Download model on first launch (not bundled) — show progress UI; cache to app document directory
- [ ] **9.14.4.3** Verify ONNX runtime DLLs ship correctly on Windows MSIX bundle (known gotcha)
- [ ] **9.14.4.4** Streaming pipeline: mic → 16 kHz PCM chunks → `OnlineRecognizer` → partial results → UI captions
- [ ] **9.14.4.5** Map sherpa-onnx errors → unified `SttError`
- [ ] **9.14.4.6** Capabilities: `supportsStreaming: true`, `onDevice: true`, `supportedLanguages: ['en', 'ko', 'zh']`

### 9.14.5 Future: SherpaOnnxTtsService (Stub)

**File (future):** `lib/core/speech/sherpa_onnx_tts.dart`

Wraps `package:sherpa_onnx` TTS models. Recommended voice strategy:

| Voice family | Languages | Size per voice | Notes |
|--------------|-----------|----------------|-------|
| **VITS (`vits-piper-*`)** | en, ko, zh + more | ~60–100 MB | High quality, many speaker voices available |
| **MatchaTTS** | en | ~80 MB | Newer, faster inference |
| **Coqui XTTS-v2** (via ONNX) | multilingual + voice cloning | ~1 GB | Optional later — too heavy for MVP |

**Persona → voice mapping** (initial proposal — finalize when implementing):

| Persona | en voice | ko voice | zh voice |
|---------|----------|----------|----------|
| Maya | vits-piper-en_US-amy-medium | vits-piper-ko_KR-rebecca-medium | vits-piper-zh_CN-huayan-medium |
| Leo | vits-piper-en_US-ryan-high | (alternate) | (alternate) |
| Sofia | vits-piper-en_GB-jenny-high | (alternate) | (alternate) |
| Theo | vits-piper-en_US-joe-medium | (alternate) | (alternate) |

(Exact voice IDs depend on what's available in the sherpa-onnx model zoo at implementation time. Custom-trained voices are an option later.)

- [ ] **9.14.5.1** Download persona voice models on first launch (one bundle per language) — show progress UI
- [ ] **9.14.5.2** Cache audio: synthesize once per (text, voiceId) pair, store in app cache dir for replay
- [ ] **9.14.5.3** Streaming synthesis where supported — start playback before full generation completes
- [ ] **9.14.5.4** Coordinate with [Rive animation](07_animation.md): `speak()` → set Rive `isSpeaking = true` → unset when audio ends
- [ ] **9.14.5.5** Capabilities: `supportsStreaming: true`, `onDevice: true`, voices listed in `availableVoices`

### 9.14.6 Provider Factory (Speech)

**File:** `lib/core/speech/speech_factory.dart`

```dart
enum SpeechProvider { placeholder, sherpaOnnx, /* future: whisperApi, elevenLabs */ }

SpeechToTextService createStt(SpeechProvider provider) { /* ... */ }
TextToSpeechService createTts(SpeechProvider provider) { /* ... */ }
```

Toggle via app setting (eventually) or build-time flag:
```dart
const kSttProvider = SpeechProvider.placeholder;   // → SherpaOnnxSttService later
const kTtsProvider = SpeechProvider.placeholder;   // → SherpaOnnxTtsService later
```

- [ ] **9.14.6.1** Riverpod providers `sttServiceProvider` and `ttsServiceProvider` return the factory result
- [ ] **9.14.6.2** Both services initialized on app start (after sign-in), disposed on sign-out
- [ ] **9.14.6.3** Settings screen exposes voice selection per language (when sherpa-onnx is enabled)

---

## 9.15 Offline English-Level Evaluation Stack (Android + Windows)

**Goal:** evaluate all 5 skills on the Progress radar — pronunciation, fluency, vocabulary, grammar, listening — **fully offline on both Android and Windows**. No reliance on cloud APIs in the evaluation hot path.

This section defines the multi-library stack, the cross-platform constraints, and the per-skill computation pipelines.

### 9.15.1 Library Matrix (Cross-Platform Verified)

| Library | Purpose | Android | Windows | Distribution |
|---------|---------|---------|---------|--------------|
| **sherpa-onnx** | STT, TTS, pronunciation (GOP), VAD | ✅ via `sherpa_onnx` Flutter pkg | ✅ via `sherpa_onnx` Flutter pkg | Native bindings + ONNX models |
| **Silero VAD** | Voice activity detection (pause measurement) | ✅ (bundled in sherpa-onnx) | ✅ (bundled) | ONNX model bundled |
| **CEFR-J wordlist** | Word-level CEFR tagging (A1–C2) | ✅ Pure Dart | ✅ Pure Dart | ~1 MB CSV asset |
| **Lexical diversity calc (TTR, MTLD)** | Vocabulary diversity metrics | ✅ Pure Dart | ✅ Pure Dart | <10 KB pure code |
| **ONNX grammar model** (e.g. quantized flan-T5-small or Grammarly-style classifier) | Offline grammar scoring | ✅ via ONNX Runtime | ✅ via ONNX Runtime | ~150 MB downloaded |
| **Sentence-Transformers MiniLM (ONNX)** | Semantic similarity for listening tasks | ✅ via ONNX Runtime | ✅ via ONNX Runtime | ~80 MB downloaded |

**Explicitly NOT used (cross-platform failures):**
- ❌ **LanguageTool** (Java) — would need embedded JVM on Android; tar pit
- ❌ **spaCy / Python NLP** — Python on Android is impractical
- ❌ **Praat / parselmouth** — Python-only, no mobile path

### 9.15.2 Per-Skill Computation Pipelines

#### Pronunciation — `PronunciationScorer`

**File:** `lib/core/evaluation/pronunciation_scorer.dart`

Pipeline (per user utterance):
1. STT transcribes audio → text + word-level timestamps + word-level confidence
2. **sherpa-onnx GOP** aligns audio against expected text → per-phoneme score (0.0–1.0)
3. Aggregate: `pronunciation_score = mean(phoneme_scores) × 100`
4. Identify low-scoring phonemes → return as `mispronounced_phonemes[]`

```dart
class PronunciationResult {
  final int score;                            // 0-100
  final double averagePhonemeScore;
  final List<MispronouncedPhoneme> issues;    // [{phoneme: 'TH', word: 'think', score: 0.42}]
  final double confidence;
}

abstract class PronunciationScorer {
  Future<PronunciationResult> score({
    required Uint8List audioData,
    required String expectedText,
  });
}
```

- [ ] **9.15.2.1** `SherpaOnnxPronunciationScorer` implementation wraps sherpa-onnx GOP recipe via FFI
- [ ] **9.15.2.2** Fallback when GOP model unavailable: use STT word-confidence as coarse proxy (`score = mean(confidence) × 100`)
- [ ] **9.15.2.3** Run in a Dart isolate to keep UI responsive

#### Fluency — `FluencyScorer`

**File:** `lib/core/evaluation/fluency_scorer.dart`

Pipeline (per user utterance):
1. sherpa-onnx STT → word-level timestamps
2. Silero VAD → voiced/silent segments
3. Compute metrics from timestamps:
   - `words_per_minute = words / (total_duration - silence) × 60`
   - `pause_rate = silence_duration / total_duration`
   - `articulation_rate = phonemes / voiced_duration`
   - `filler_count = count of "um|uh|er|like|you know|hmm" in transcript`
4. Score formula (level-adjusted):
   ```
   wpm_target = [80, 100, 120, 140, 160, 180]  // by level 1-6
   wpm_score = clamp(100, (wpm / wpm_target[level-1]) × 100)
   pause_penalty = clamp(0, (pause_rate - 0.3) × 100)   // >30% pause = penalty
   filler_penalty = min(20, filler_count × 2)
   fluency_score = max(0, wpm_score - pause_penalty - filler_penalty)
   ```

```dart
class FluencyResult {
  final int score;
  final double wordsPerMinute;
  final double pauseRate;
  final double articulationRate;
  final int fillerCount;
}
```

- [ ] **9.15.2.4** `SherpaOnnxFluencyScorer` reads STT timing + VAD output
- [ ] **9.15.2.5** Filler-word list configurable per language (en: um/uh/like; ko: 음/어; zh: 嗯/那个)
- [ ] **9.15.2.6** Aggregate across all user utterances in a session for the session-level score

#### Vocabulary — `VocabularyScorer`

**File:** `lib/core/evaluation/vocabulary_scorer.dart`

Pipeline (per session, all user messages combined):
1. Tokenize messages → lowercase, strip punctuation
2. Lookup each token in **CEFR-J wordlist** → CEFR level (A1–C2 or "unknown")
3. Compute distribution: `{ A1: n, A2: n, B1: n, B2: n, C1: n, C2: n, unknown: n }`
4. Compute lexical diversity:
   - `TTR = unique_tokens / total_tokens`
   - `MTLD = ...` (Measure of Textual Lexical Diversity — more robust than TTR)
5. Score formula:
   ```
   level_appropriate_ratio = (words_at_or_above_user_level / total_known_words)
   diversity_score = min(100, MTLD × 1.5)
   keyphrase_bonus = min(20, key_phrases_used × 5)
   vocabulary_score = (level_appropriate_ratio × 50) + (diversity_score × 0.3) + keyphrase_bonus
   ```

```dart
class VocabularyResult {
  final int score;
  final Map<String, int> cefrDistribution;
  final double ttr;
  final double mtld;
  final int uniqueWordCount;
  final int totalWordCount;
  final int keyPhrasesUsed;
}
```

- [ ] **9.15.2.7** Bundle CEFR-J wordlist as Flutter asset (`assets/wordlists/cefr_j_en.csv`)
- [ ] **9.15.2.8** Pre-load wordlist into HashMap at app start, query is O(1)
- [ ] **9.15.2.9** Implement MTLD algorithm per McCarthy & Jarvis (2010)

#### Grammar — `GrammarScorer`

**File:** `lib/core/evaluation/grammar_scorer.dart`

Two-implementation strategy depending on what's installed:

**Default (offline):** ONNX grammar model
- Quantized small grammar model (e.g. `flan-T5-small` fine-tuned for grammar OR a binary classifier "is this sentence grammatical?")
- Per-message inference → grammatical-correctness score 0-100
- Aggregate across messages for session score
- Optionally generate corrections (heavier, T5-base)

**Cloud fallback (optional):** delegate to the existing `AiProvider.structured()` call → reuses §9.9 prompt

```dart
abstract class GrammarScorer {
  Future<GrammarResult> score(List<String> messages, int userLevel);
}
```

- [ ] **9.15.2.10** `OnnxGrammarScorer` — load ONNX model via runtime; inference in isolate
- [ ] **9.15.2.11** `AiProviderGrammarScorer` — wraps existing Claude-based `analyzeGrammar` path
- [ ] **9.15.2.12** Build-time / settings toggle selects which scorer (default: offline ONNX)
- [ ] **9.15.2.13** Both scorers return the same `GrammarResult` shape so callers don't care

**Honest caveat:** offline grammar models (~150 MB quantized) are noticeably less nuanced than Claude. They catch mechanical errors (tense, agreement, articles) well, but miss subtle style/register issues. Acceptable trade-off for offline operation; users with internet can opt into AI-powered grammar feedback in Settings.

#### Listening — `ListeningScorer`

**Two scenario subtypes** in the DB (see §9.15.4 schema additions):

1. **Dictation** — TTS plays sentence, user types or speaks it back
   - Score = `1 - (levenshtein(user_text, expected_text) / max(len_user, len_expected))` × 100
   - Pure Dart, no model needed
2. **Comprehension Q&A** — TTS plays passage, asks 1-3 questions, user answers
   - Use **sentence-transformers MiniLM ONNX** for semantic similarity
   - Score = `cosine_similarity(user_answer_embedding, expected_answer_embedding)` × 100

```dart
abstract class ListeningScorer {
  Future<int> scoreDictation({required String userText, required String expectedText});
  Future<int> scoreComprehension({required String userAnswer, required List<String> acceptableAnswers});
}
```

- [ ] **9.15.2.14** `MiniLMListeningScorer` — load `all-MiniLM-L6-v2` ONNX, run via `onnxruntime`
- [ ] **9.15.2.15** Levenshtein-based dictation scorer in pure Dart
- [ ] **9.15.2.16** Cache embeddings of expected answers at scenario-load time

### 9.15.3 Cross-Platform Concerns

| Concern | Platform | Mitigation |
|---------|----------|------------|
| AVX2 requirement on Windows | Windows | Document min CPU: Intel Haswell (2013+) / AMD Excavator (2015+). Provide non-AVX fallback build only if needed |
| Google Play 200 MB base APK limit | Android | Models downloaded post-install (already planned in §9.14) |
| Native ABI coverage | Android | Verify `arm64-v8a`, `armeabi-v7a`, `x86_64` ABIs in `build.gradle` `splits` block |
| MSIX bundle includes ONNX DLLs | Windows | Verify in release smoke test — sherpa-onnx plugin handles this but confirm |
| UI thread jank on heavy inference | Both | All STT / TTS / grammar / similarity inference runs in Dart isolates |
| Mic permission denied | Both | Graceful fallback: text-only conversation, audio-scored skills marked "—" rather than 0 |
| Model loading time on app start | Both | Lazy load — only load model when feature first used; show 1s loading indicator |
| Storage permission on Android | Android | Use app-internal storage (`getApplicationDocumentsDirectory()`) — no permission needed |
| File path differences | Both | Use `path_provider` package consistently; never hard-code paths |

- [ ] **9.15.3.1** CI smoke test: release-mode build + first-run model download + 1 STT call on Android emulator
- [ ] **9.15.3.2** CI smoke test: release-mode Windows build + first-run model download + 1 STT call
- [ ] **9.15.3.3** Min CPU spec documented in README for Windows
- [ ] **9.15.3.4** All inference paths use `compute()` or explicit `Isolate.spawn()`

### 9.15.4 DB Schema Additions (Cross-Reference)

The granular per-skill metrics need new columns in `session_scores`. Detailed in [todoList/02 §2.1](02_database_schema.md):

- `pronunciation_metrics JSONB` — `{ phoneme_avg, confidence_avg, mispronounced_phonemes: [...] }`
- `fluency_metrics JSONB` — `{ wpm, pause_rate, articulation_rate, filler_count }`
- `vocabulary_metrics JSONB` — `{ cefr_distribution, ttr, mtld, unique_words, total_words, keyphrases_used }`
- `grammar_metrics JSONB` — `{ error_count, error_types: [...], scorer_used }`
- `listening_metrics JSONB` — `{ task_type, similarity_score, dictation_accuracy }` (only when listening task in session)

The simple 0-100 columns (`pronunciation_score`, `fluency_score`, etc.) stay as-is for the radar chart.

### 9.15.5 Phased Rollout (When Each Skill Becomes Real)

| Phase | What works | What's hidden / mocked | Trigger |
|-------|-----------|------------------------|---------|
| **Phase 1 — MVP** | Vocabulary (CEFR-J), Engagement, Grammar (Claude only) | Pronunciation + Listening = "—" in radar; Fluency = text proxy with `?` tooltip | Ship without STT/TTS |
| **Phase 2 — STT integration** | + real Fluency (audio timing), + dictation listening | Pronunciation + comprehension still mocked | sherpa-onnx STT + VAD shipped |
| **Phase 3 — TTS + Pronunciation** | + real Pronunciation, + comprehension listening | None — all 5 skills real ✅ | sherpa-onnx TTS + GOP + MiniLM shipped |
| **Phase 4 — Offline grammar** | Full offline mode (no Claude dependency) | None | ONNX grammar model shipped |

- [ ] **9.15.5.1** Radar chart shows "—" + lock icon for unscored skills in each phase
- [ ] **9.15.5.2** Tooltip on each skill: "Coming in Phase N" with brief explanation
- [ ] **9.15.5.3** Per-phase release notes document which skills are newly real
