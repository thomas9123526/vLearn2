# 02_chat_propose — Current Conversation Flow

> **Ask**: Describe in detail what information is sent to the AI server when the user enters the conversation screen, what comes back, and how tips/recommendations are generated.

This is a read-only documentation task — no code was changed. The document is intended to inform future conversation format planning.

---

## 1. Entering the conversation screen

The `ConversationScreen` receives a `sessionId` (UUID) created when the user taps **Start speaking** on the scenario brief screen (or directly from the scenario tile in free-conversation mode).

On mount, Flutter fires two parallel fetches:

| Request | Endpoint | What comes back |
|---------|----------|-----------------|
| Session + messages | `GET /conversations/sessions/:id` | Session metadata + full message array (ascending by `sequence`) |
| Active persona | `GET /personas/:personaId` | Name, style, specialties, avatar URL, voice ID |

The session metadata includes: `id`, `scenarioId`, `personaId`, `mode` (`'chat'`/`'face'`), `status`, `startedAt`, `turnCount`, `wordCount`, `xpEarned`.

Each message in the history has: `id`, `role` (`'user'`/`'assistant'`), `content`, `sequence`, `createdAt`.

Nothing is sent to the AI on entry — the AI is only called when the user sends a message.

---

## 2. Sending a message

### Flutter → Backend

`POST /conversations/sessions/:id/messages`
```json
{
  "content": "I would like to order a coffee please.",
  "audioUrl": null
}
```
`audioUrl` is populated only when STT produces a recording URL (not yet wired for the sherpa-onnx local STT path — currently always null).

### Backend processing (`ConversationsService.sendMessage`)

1. **Loads full history** from DB (ascending sequence order).
2. **Saves the user's message** to the `conversation_messages` table and assigns the next sequence number.
3. **Loads supporting context** from DB: persona entity, scenario entity (if any), user entity.
4. **Calls `ConversationOrchestrator.generateTutorReply`** with:
   - `persona` — full entity (name, style, specialties list)
   - `scenario` — full entity or `null` for free conversation (title, scene description, tutor role, user role, objectives array, key phrases array)
   - `userLevel` — integer 1–6 mapping to CEFR A1–C2
   - `userNativeLanguage` — e.g. `'ko'` or `'zh'`
   - `history` — all prior messages **plus the current user message** as `[{role, content}]` pairs

### System prompt built by `PromptBuilderService.buildSystemPrompt`

```
You are {persona.name}, an English language tutor with a {persona.style} teaching style.
Your specialties include: {specialties joined by ", "}.

CURRENT SCENARIO:
Title: {scenario.title.en}
Setting: {scenario.scene_description.en}
Your role: {scenario.tutor_role.en}
User's role: {scenario.user_role.en}
Objectives: {objectives joined by ", "}
Key phrases to encourage: {key_phrases joined by ", "}

USER PROFILE:
- English level: B1 (3/6)
- Native language: ko

INSTRUCTIONS:
1. Stay in character as {persona.name} throughout.
2. Adjust vocabulary and sentence complexity to level 3/6.
3. Respond naturally and conversationally (2-4 sentences usually).
4. Correct grammar errors GENTLY and IMPLICITLY by modeling correct usage.
5. Celebrate good English with encouragement appropriate to your personality.
6. If objectives exist, naturally guide conversation toward them.
7. Encourage use of the key phrases when appropriate.
8. Do NOT explicitly state you are an AI unless directly asked.
9. Do NOT break character.
10. If the user writes in their native language, gently encourage English with a translation hint.
```

For free conversation (no scenario), the `CURRENT SCENARIO` block becomes:
```
Free conversation practice - no specific scenario.
```

### AI provider call

```
ai.chat({
  systemPrompt: <built above>,
  messages: [{role: "user"|"assistant", content: "..."}],   // full history
  maxTokens: 300,
  temperature: 0.8,
  enablePromptCache: true   // if provider supports it (Claude does)
})
```

The backend uses a vendor-agnostic `AiProvider` interface. The concrete implementation may be Claude (`anthropic`) or OpenAI (`openai`) — configured via env vars. When prompt caching is enabled, the static system prompt is cached across turns, significantly reducing latency and cost after the first turn.

### Response to Flutter

```json
{
  "userMessage":    { "id": "...", "role": "user",      "content": "...", "sequence": 5, "createdAt": "..." },
  "assistantMessage":{ "id": "...", "role": "assistant","content": "...", "sequence": 6, "createdAt": "..." },
  "turnCount": 3
}
```

Flutter receives both messages, updates `turnCount` in the AppBar, and refreshes the message list by invalidating `_sessionProvider`.

---

## 3. Idle suggestion (tutor mode)

When the user has been silent for ~20 seconds in Face (tutor) mode, Flutter calls:

`POST /conversations/sessions/:id/suggest` (no body)

Backend calls `ConversationOrchestrator.suggestNextLine` with the same context (persona, scenario, level, language, history). The system prompt is the same as above **plus an appended instruction**:

```
The student has gone quiet. Reply ONLY with a single short English sentence (8–15 words)
the student could say next to continue the conversation.
Do not introduce yourself, do not explain, do not use quotation marks.
```

AI call parameters: `maxTokens: 60`, `temperature: 0.7`.

The backend strips surrounding quotes from the result and collapses whitespace, then returns:
```json
{ "suggestion": "Could you tell me more about what you enjoy doing on weekends?" }
```

Flutter displays this as a suggestion chip below the tutor face. Tapping it auto-sends the suggestion as the user's next message.

**Fallback (AI offline)**: If the AI provider throws, the suggestion is canned — either `"I'm not sure — could you give me an example?"` or `"That sounds interesting — could you tell me more?"` depending on whether the last assistant message ended in a question mark.

---

## 4. Ending a session

`POST /conversations/sessions/:id/end`  with `{ "status": "completed" }`.

The backend:
- Sets `status = 'completed'`, records `ended_at`, computes `duration_seconds`.
- Calculates `xp_earned = min(wordCount, 200)`, capped further at `scenario.xp_reward` when a scenario is set.
- Returns the updated session DTO.

Flutter navigates to `SessionReportScreen`. On mount, the report screen fire-and-forgets `ProgressApi.submitSnapshot()` with heuristic scores:
- `fluency` — derived from `turnCount` (more turns → higher fluency score, up to 85)
- `vocabulary` — derived from `wordCount / turnCount` (words per turn)
- `grammar` — derived from `wordCount` (longer responses proxy for better grammar)

These are blended 0.7×old + 0.3×new into the existing daily snapshot on the backend.

---

## 5. What is NOT currently AI-generated

| Feature | Current state |
|---------|--------------|
| Grammar feedback paragraph | `buildGrammarPrompt` / `buildFeedbackPrompt` exist in `PromptBuilderService` but are **not yet called** — no report evaluation endpoint wired |
| Score breakdown on report screen | Heuristic only (word count / turn count math) |
| Strengths / improvements lists | Not yet populated |
| Pronunciation score | Not evaluated (STT is local, no accent scoring) |
| XP calculation | Deterministic (word count formula) — no AI |

All AI interaction today flows through the **real-time conversation only**. The evaluation pipeline is partially scaffolded but not yet connected.

---

## 6. Data flow diagram

```
Flutter                         Backend                         AI Provider
  │                               │                               │
  │── GET /sessions/:id ─────────►│                               │
  │◄─ {session, messages} ────────│                               │
  │                               │                               │
  │── POST /messages ────────────►│                               │
  │   {content}                   │── buildSystemPrompt ─────────►│
  │                               │   history + persona/scenario  │
  │                               │◄─ tutorReply (≤300 tokens) ───│
  │◄─ {userMsg, assistantMsg} ────│                               │
  │                               │                               │
  │── POST /suggest ─────────────►│                               │
  │   (20s idle)                  │── buildSystemPrompt + append ►│
  │                               │◄─ suggestion (≤60 tokens) ────│
  │◄─ {suggestion} ───────────────│                               │
  │                               │                               │
  │── POST /end ─────────────────►│                               │
  │◄─ {session, xpEarned} ────────│                               │
  │                               │                               │
  │── POST /progress/snapshots ──►│                               │
  │   (heuristic scores)          │                               │
```

---

## Files referenced

| File | Role |
|------|------|
| [flutter_app/lib/features/conversation/conversation_screen.dart](../../flutter_app/lib/features/conversation/conversation_screen.dart) | Screen orchestration, send/end |
| [flutter_app/lib/features/conversation/widgets/tutor_mode_view.dart](../../flutter_app/lib/features/conversation/widgets/tutor_mode_view.dart) | Face mode UI, 20s idle timer |
| [flutter_app/lib/core/api/app_apis.dart](../../flutter_app/lib/core/api/app_apis.dart) | `ConversationsApi` client methods |
| [backend/src/conversations/conversations.service.ts](../../backend/src/conversations/conversations.service.ts) | Session/message persistence + orchestrator call |
| [backend/src/ai/conversation.orchestrator.ts](../../backend/src/ai/conversation.orchestrator.ts) | Provider-agnostic AI calls, fallbacks |
| [backend/src/ai/prompt-builder.service.ts](../../backend/src/ai/prompt-builder.service.ts) | System prompt / grammar prompt / feedback prompt construction |
