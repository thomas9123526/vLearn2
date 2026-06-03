# before implement,  I need to tell you this. The process between backend api and 

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-02T05:47:59.867Z

## User

before implement,  I need to tell you this.
The process between backend api and Ai-provider is like the  A1_passed.json.

at the end of the conversation , I get following evaluation values from ai-provider by prompting.

- fluency         : pacing, hesitation, naturalness of phrasing
  - accuracy        : grammar correctness, tense, articles, agreement
  - vocabulary      : range, appropriateness, collocation
  - interaction     : turn-taking, follow-up questions, engagement; judge
                      against what is appropriate for the LEARNER role
  - topic_adherence : did the learner actually engage with the assigned
                      topic and subtopics, or steer to easier ground?
                      Use the LEARNER and TUTOR roles to judge whether a
                      pivot is a natural extension within role (high) or
                      true avoidance (low). AVOIDANCE scores low.

And Show the user about the evaluation.

Let's do for this requirement on flutter and backend side.

And I want put option to swap the stt/tts library with another like whisper or other well know best accuracy engine model.

I will target phone for arm64, ram size is above 6 gb normal.
There can be parameters like fp32 or fp16 but decides for me and let me know where can i configure it.

## Assistant

Let me read the key files before implementing.

## Assistant

Let me read the specific files I need full detail on before implementing.

## Assistant

Now I have everything I need. Let me implement the full pipeline. This is a large change — I'll do it systematically.

## Assistant

Now adding `evaluateSession()` to the orchestrator:

## Assistant

Now update `ConversationsService` — add `SessionScoreEntity` repo, `triggerEvaluation`, `getSessionScore`, and wire `endSession`:

## Assistant

Now add the Logger import at the top:

## Assistant

Now wire evaluation into `endSession` and add the new methods. Let me find the end of `endSession`:

## Assistant

Add the `GET /sessions/:id/score` endpoint and `SessionScoreEntity` to the module's forFeature (it's already there — just add the controller endpoint):

## Assistant

The `getSessionScore` returns `null` when score isn't ready yet — NestJS will send a 200 with empty body which Dio parses as `null`. That's clean for polling. But the module also needs `SessionScoreEntity` to be available for the service injection — it's already in `TypeOrmModule.forFeature`. Good.

## Assistant

Check Dio is imported in app_apis.dart:

## Assistant

Two TypeScript errors to fix. Let me check the scenario `title` type first:

## Assistant

`I18nText = { en: string, ko?: string, zh?: string }`. Now fix both errors in the service:

## Assistant

Now rewrite `session_report_screen.dart` with real scores, polling, and the full evaluation display:

## Assistant

Now the STT engine abstraction and config. The current `sherpa_onnx_stt.dart` already auto-detects streaming vs offline based on which model files are present. I'll add a config layer on top:

## Assistant

Implementing the full evaluation + STT config pipeline. Almost done — fixing two linting issues first.

## Assistant

I accidentally dropped the field declarations. Need to restore them in the right order (all constructors first, then fields):

## Assistant

Now fix the switch exhaustiveness in the getters — Dart requires `switch` on enums to be exhaustive:

## Assistant

The switches are exhaustive — those errors were caused by the missing fields (now restored). Let me proceed to commit.

## Assistant

Everything is done. Here's what was built:

---

## What was implemented

**Backend — evaluation pipeline**

When a session ends, `endSession()` now fire-and-forgets `triggerEvaluation()`. That method:
1. Loads all messages ordered by sequence
2. Formats them as `[USER turn N] text` / `[TUTOR] text`
3. Sends to the AI with the examiner system prompt (matches your `cch_evaluate2.txt` format exactly)
4. Parses the `<think>…</think>` + JSON response
5. Maps 1–5 scores → 0–100 and saves to `vl_session_scores`

New endpoint: `GET /conversations/sessions/:id/score` — returns null while running, returns the full score DTO when ready.

**Flutter — session report screen**

Completely replaced the heuristic placeholders. Now polls every 3 s (up to 36 s). Shows:
- CEFR estimate badge (e.g. "B1")
- 5 dot-bars: Fluency, Accuracy, Vocabulary, Interaction, Topic focus
- Strengths bullets
- Work-on bullets (from specific_feedback issues)
- Suggested practice block

**STT engine config — `speech_config.dart`**

Documents and makes configurable:

| Engine | Quantization | Use case |
|---|---|---|
| Streaming Zipformer | **int8** | Real-time, every frame — recommended default |
| Whisper large-v3-turbo | **fp16** | Batch, ~0.5 s lag, best accuracy |

To swap: replace `.onnx` files in the model bundle. The existing `SherpaOnnxSttService` auto-detects which mode to use based on which manifest keys are present — no code change needed.

**Pending server action:** `npx typeorm migration:run -d src/database/data-source.ts` (adds `cefr_estimate` and `topic_adherence_score` columns).
