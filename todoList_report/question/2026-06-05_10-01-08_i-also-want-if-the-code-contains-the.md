# I also want if the code contains the part to get evalution values from sherpa on

Session: `40c2c32e-4bcc-4826-8449-440738f22ef6`
Saved: 2026-06-05T01:01:08.721Z

## User

I also want if the code contains the part to get evalution values from sherpa onnx like fluency, etc. If yes, describe me with code lines.

## Assistant

That's enough to give a definitive answer.

---

## Short answer: No — Sherpa ONNX does NOT provide evaluation scores

Sherpa ONNX in this project is **STT only** (Speech-to-Text). It converts the user's voice audio → text transcript. It does not score fluency, pronunciation, or anything else.

---

## What Sherpa ONNX does

[flutter_app/lib/core/speech/sherpa_onnx_stt.dart:35](flutter_app/lib/core/speech/sherpa_onnx_stt.dart#L35)

```dart
class SherpaOnnxSttService extends SpeechToTextService {
  // Supports two model flavours:
  // • Online  → streaming transducer (Zipformer/RNN-T) — streams partial text
  // • Offline → Whisper encoder/decoder — single-shot push-to-talk
  //
  // Input:  mono 16-bit PCM at 16 kHz (from AudioRecorderService)
  // Output: plain text transcript string
}
```

Its only job: audio → text. The transcript is then sent to the AI tutor as a user message.

---

## The `pronunciation_score` column exists but is never written

[conversation.entity.ts:95-96](backend/src/database/entities/conversation.entity.ts#L95-L96)

```ts
@Column({ type: 'smallint', nullable: true })
pronunciation_score!: number | null;   // ← nullable, never populated
```

[conversation.entity.ts:113-114](backend/src/database/entities/conversation.entity.ts#L113-L114)

```ts
@Column({ type: 'jsonb', nullable: true })
pronunciation_metrics!: Record<string, unknown> | null;  // ← always null
```

The `triggerEvaluation()` method at [conversations.service.ts:443-457](backend/src/conversations/conversations.service.ts#L443-L457) **never sets** `pronunciation_score` — it only sets the 5 AI scores. So this column is always `null` in the DB right now.

---

## Summary table

| Score | Source | Currently working? |
|---|---|---|
| `fluency_score` | AI evaluation response | Yes |
| `grammar_score` | AI evaluation response (`accuracy`) | Yes |
| `vocabulary_score` | AI evaluation response | Yes |
| `engagement_score` | AI evaluation response (`interaction`) | Yes |
| `topic_adherence_score` | AI evaluation response | Yes |
| `pronunciation_score` | Intended for Sherpa ONNX | **Always null — not implemented** |

Sherpa ONNX was likely planned as a future pronunciation scorer (comparing recognized phonemes against reference), but that pipeline was never built. Right now it is only a transcriber.
