# what values can i get for English Level Evaluation from sherpa-onnx

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-02T01:32:58.206Z

## User

what values can i get for English Level Evaluation from sherpa-onnx

## Assistant

## What sherpa-onnx can give you for English evaluation

### From STT only (what your app currently uses)

The `OfflineRecognizer` / streaming recognizer returns only:

| Field | Type | Notes |
|---|---|---|
| `text` | String | The transcript |
| `confidence` | double | Always `1.0` in your Zipformer/Whisper setup — not meaningful |
| `audioDuration` | Duration | Length of audio processed |
| `detectedLanguage` | String? | Only if the model supports lang-id |

This is not enough to evaluate English level on its own.

---

### From Pronunciation Assessment (not yet integrated in your app)

sherpa-onnx has a separate `OfflinePronunciationAssessment` class that requires a specific pronunciation model (not the same as Zipformer/Whisper). It returns:

**Overall scores (0–100):**
| Score | What it measures |
|---|---|
| `accuracy_score` | How correctly each word/phoneme is pronounced |
| `fluency_score` | Naturalness of speech flow, pauses, hesitations |
| `completeness_score` | Fraction of expected words that were actually said |
| `prosody_score` | Rhythm, stress, and intonation |
| `pronunciation_score` | Weighted composite of the above |

**Per-word breakdown:**
| Field | Values |
|---|---|
| `word` | The word text |
| `accuracy_score` | 0–100 for that word |
| `error_type` | `None` / `Omission` / `Insertion` / `Mispronunciation` |
| `start_time`, `end_time` | Timing in seconds |
| `phonemes[]` | Per-phoneme accuracy scores |

---

### What sherpa-onnx cannot give you

These require your AI backend (GPT/Claude evaluator — your §09 task):

- **Grammar score** — requires understanding sentence structure
- **Vocabulary range** — requires semantic analysis of word choice
- **CEFR level** (A1–C2) — requires holistic assessment across multiple turns
- **Listening comprehension** — requires question-answer evaluation
- **Engagement score** — requires conversational context

---

### Current state in your app

Your app already has the DB schema ready for all these scores (`pronunciation_score`, `fluency_score`, `vocabulary_metrics` JSONB, etc. in `conversation.entity.ts`), and the skill snapshot fields (`pronunciation`, `fluency`, `grammar`, `vocabulary`, `listening`, `confidence` as 0–100 smallints).

The `session_report_screen.dart` currently fills fluency/vocabulary/grammar with simple heuristics (word count formulas) and leaves pronunciation as `—`, waiting for §09. Adding the `OfflinePronunciationAssessment` would give you real per-word accuracy and error types to fill that gap without needing the AI backend for the phoneme-level scores.
