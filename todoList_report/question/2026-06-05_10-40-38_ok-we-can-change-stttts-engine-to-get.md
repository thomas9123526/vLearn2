# ok we can change stt/tts engine to get evalution values from stt engine. If we c

Session: `40c2c32e-4bcc-4826-8449-440738f22ef6`
Saved: 2026-06-05T01:40:38.959Z

## User

ok we can change stt/tts engine to get evalution values from stt engine. If we change engine, then our project handle engine changes without many changes and also our database is all ready to accept these extra evalution values of stt engine?

## Assistant

Let me check the speech service abstraction layer and what the STT currently returns.

## Assistant

Now I have the full picture. Here's the honest answer:

---

## Short answer

**The STT engine is well-abstracted — swapping engines is easy. The database is already fully ready. But the data pipeline (Flutter → backend) to actually deliver STT scores doesn't exist yet.**

---

## What is already good

### 1. STT is behind a clean abstract interface

[speech_service.dart:49-55](flutter_app/lib/core/speech/speech_service.dart#L49-L55)

```dart
abstract class SpeechToTextService {
  SttCapabilities get capabilities;
  bool get isAvailable;
  Future<SttResult> transcribe(Uint8List audioData, {String? language});
  Future<void> initialize();
  Future<void> dispose();
}
```

Swapping to a different engine (Azure Pronunciation Assessment, a GOP model, etc.) = write a new class that extends `SpeechToTextService`, return it from `sttServiceProvider`. Zero changes to the conversation screen.

### 2. `SttResult` already has a `confidence` field

[speech_service.dart:10-21](flutter_app/lib/core/speech/speech_service.dart#L10-L21)

```dart
class SttResult {
  final String text;
  final double confidence;   // ← exists, but always hardcoded to 1.0
  final Duration audioDuration;
  final String? detectedLanguage;
}
```

Right now Sherpa ONNX sets `confidence: 1.0` unconditionally at [sherpa_onnx_stt.dart:197](flutter_app/lib/core/speech/sherpa_onnx_stt.dart#L197) — a real pronunciation engine would put a real score here.

### 3. Database is 100% ready, no migration needed

[conversation.entity.ts:95-114](backend/src/database/entities/conversation.entity.ts#L95-L114)

These columns already exist and are all `nullable`:
```
pronunciation_score     smallint  nullable  ← 0-100 overall
pronunciation_metrics   jsonb     nullable  ← per-phoneme detail
fluency_score           smallint  nullable
listening_score         smallint  nullable
```

---

## What is missing — the data pipeline

The gap is that even if the STT engine produces scores on the Flutter side, **there is no way to send them to the backend right now**.

The end-session call only sends:

[conversation.dto.ts:54-63](backend/src/conversations/dto/conversation.dto.ts#L54-L63)
```ts
export class EndSessionDto {
  status?: 'completed' | 'abandoned';   // ← that's all
}
```

And `triggerEvaluation()` only reads scores from the AI model — it never reads anything from the Flutter client.

---

## What needs to be added (minimal changes)

| Layer | Change needed |
|---|---|
| **Flutter `SttResult`** | Add `pronunciationScore`, `wordScores` fields |
| **Flutter STT engine** | Populate those fields from the new engine's API |
| **Flutter API call** | Include scores in `endSession()` body |
| **Backend `EndSessionDto`** | Add optional `pronunciationScore`, `pronunciationMetrics` |
| **Backend `triggerEvaluation()`** | Merge DTO scores into `fields` before DB save |
| **Backend `getSessionScore()`** | Already returns `pronunciation_score` — no change needed |

That is **5 small, localised changes** across 4 files. Nothing architectural needs to move.

---

## Summary diagram

```
Now:
  STT engine → text only → backend → AI scores only → DB (pronunciation_score always null)

With engine change:
  STT engine → text + scores → Flutter bundles in endSession body
                                      ↓
                              backend merges into triggerEvaluation fields
                                      ↓
                              DB pronunciation_score, pronunciation_metrics filled ✓
```
