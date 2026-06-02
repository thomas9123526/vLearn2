# Conversation - Session evaluation AI scores STT config

| Field | Value |
|---|---|
| Saved | 2026-06-02 14:46:27 |
| Commit | feat: end-of-session AI evaluation pipeline + STT engine config |
| Project | C:\project\vLearn2 |

---

## User

ok i want record Overall scores. So record per user's turn and sum up at the end of result.
Is it implemented in the current project?

Also some other scores will be received by prompting ai-model in the backend api

## Assistant

Not implemented — `SessionScoreEntity` exists but nothing ever writes to it. Current `session_report_screen.dart` uses hardcoded heuristics (word-count formulas) and shows "—" for all scores. The `ConversationOrchestrator.scoreGrammar()` method exists but is never called.

Full pipeline implemented:
- Backend: `evaluateSession()` in orchestrator, `triggerEvaluation()` fires async after `endSession()`, `GET /conversations/sessions/:id/score` endpoint
- Flutter: `getSessionScore()` in API, `SessionReportScreen` polls every 3 s until evaluation arrives

---

## User

what values can i get for English Level Evaluation from sherpa-onnx

## Assistant

sherpa-onnx is used only for STT/TTS — not for scoring. For pronunciation assessment it has `OfflinePronunciationAssessment` (accuracy, fluency, completeness, prosody, per-word breakdown) but the current app does not use it.

What the app was tracking (heuristics only, now replaced with AI): fluency, vocabulary, grammar, engagement.

What the AI evaluator returns (now implemented): fluency, accuracy, vocabulary, interaction, topic_adherence (all 1–5) + overall_cefr_estimate + specific_feedback[] + strengths[] + suggested_practice.

---

## User

(attached cch_evaluate2.txt and A1_passed.json showing the evaluation prompt format)

The process between backend api and AI-provider is like the A1_passed.json.

At the end of the conversation I get following evaluation values from ai-provider by prompting:
- fluency: pacing, hesitation, naturalness
- accuracy: grammar correctness, tense, articles
- vocabulary: range, appropriateness, collocation
- interaction: turn-taking, follow-up questions, engagement
- topic_adherence: did learner engage with assigned topic or avoid it

Let's do for this requirement on flutter and backend side.

And I want put option to swap the stt/tts library with another like whisper or other well known best accuracy engine model.

I will target phone for arm64, ram size is above 6 gb normal.

## Assistant

(See user message for requirement details.)

## User

for stt/tts engine, I want real time and best accuracy

## Assistant

**Recommendation: two modes, both via sherpa-onnx (no code swap needed, just model files)**

| Goal | Model | Quantization | Why |
|---|---|---|---|
| Real-time streaming | Zipformer transducer (sherpa-onnx-streaming-zipformer-en-2023-06-26) | **int8** | ARM dot-product instructions, truly frame-by-frame |
| Best accuracy (batch) | Whisper large-v3-turbo ONNX | **fp16** | ARM NEON FP16, 50% memory vs fp32, <0.5% accuracy loss |

The current `SherpaOnnxSttService` already auto-detects which mode to use based on which model files are present in the manifest — no code change needed to swap.

**Quantization for arm64 6 GB RAM:**
- Streaming Zipformer: **int8** — fastest, ~65 MB, real-time on any 2016+ ARM
- Whisper large-v3-turbo: **fp16** — ~1 GB, best accuracy, Cortex-A76+ supports natively
- TTS (VITS): **fp32** — model is small (<100 MB), quality > speed

Configure in `flutter_app/assets/speech_config.json`.

## User

what's going on?

## Assistant

Implementing end-of-session AI evaluation + STT engine config. Summary of all changes made:

**Backend:**
- `conversation.entity.ts` — added `cefr_estimate` (varchar 3) and `topic_adherence_score` (smallint) to `SessionScoreEntity`
- `1782000000000-session-score-cefr.ts` — migration for those columns
- `conversation.orchestrator.ts` — added `evaluateSession()`: sends full transcript to AI as `[USER turn N]` / `[TUTOR]` lines, parses `<think>…</think>` + JSON, returns typed `EvaluationResult`
- `conversations.service.ts` — `endSession()` now fire-and-forgets `triggerEvaluation()` which loads messages + scenario, calls orchestrator, maps 1–5 scores to 0–100, saves to `SessionScoreEntity`; added `getSessionScore()` returning camelCase DTO
- `conversations.module.ts` — added `GET /sessions/:id/score` endpoint

**Flutter:**
- `app_apis.dart` — added `getSessionScore()` that returns null (poll) or the score map; 404 → null
- `session_report_screen.dart` — complete rewrite: polls every 3 s up to 12 times; shows pending spinner, then score card with 5 dot-bars (fluency/accuracy/vocabulary/interaction/topic focus), CEFR badge, strengths, improvements, suggested practice
- `speech_config.dart` — new `SpeechConfig` class + `SttEngine` enum with full documentation on models, quantization, and where to place model files

**Pending on server:** run `npx typeorm migration:run -d src/database/data-source.ts`

---

## Prompt

for stt/tts engine, I want real time and best accuracy
