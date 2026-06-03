# ok i want record Overall scores. So record per user's turn and sum up at the end

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-02T04:31:33.547Z

## User

ok i want record Overall scores. So record per user's turn and sum up at the end of result.
Is it implemented in the current project?

Also some other scores will be received by prompting ai-model in the backend api

## Assistant

Let me trace the full scoring pipeline — per-turn storage, session finalization, and the AI evaluator hook.

## Assistant

**Not implemented.** Here's the exact state:

---

## What exists vs what's missing

### Implemented (but wired to nothing)
- `SessionScoreEntity` — the DB table and entity for session-level scores is fully defined with all the right columns
- `ConversationOrchestrator.scoreGrammar()` — makes a real structured LLM call, but is never invoked
- `buildFeedbackPrompt()` — scaffolded for post-session AI feedback, also never called

### Not implemented at all
- Per-turn pronunciation scores — `ConversationMessageEntity` has no score columns
- Anything that writes to `SessionScoreEntity` — it's imported in the module but only used in delete cleanup
- The post-session evaluation pipeline — no service, no trigger, no endpoint
- `OfflinePronunciationAssessment` in Flutter — sherpa-onnx STT is used only for transcription

### Current behavior
Flutter `session_report_screen.dart` computes everything client-side with hardcoded formulas:
```dart
// line 24-40 — explicitly labeled as placeholders
final fluency    = (40 + (wordCount / turnCount) * 1.5).clamp(40, 95);
final vocabulary = (45 + wordCount / 8).clamp(45, 95);
final grammar    = (50 + turnCount).clamp(50, 95);
```
Then submits those to `/progress/snapshots`. The UI shows `—` for all scores with the note "AI-driven scoring arrives when AI integration lands."

---

## What needs to be built

The full pipeline you described (per-turn pronunciation → aggregate at end + AI scores from backend) requires:

1. **Flutter**: Call `OfflinePronunciationAssessment` per user audio turn, accumulate the overall scores, average them at session end
2. **Backend**: A `POST /conversations/:id/score` endpoint that calls `scoreGrammar()` (and new similar methods for fluency/vocabulary) against the session transcript, then writes to `SessionScoreEntity`
3. **Backend**: `endSession()` triggers (or queues) that scoring endpoint
4. **Flutter report**: Read scores from the backend instead of computing locally

Want me to implement this pipeline?
