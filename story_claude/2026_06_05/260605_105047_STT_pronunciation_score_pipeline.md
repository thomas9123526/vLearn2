# Conversation - STT pronunciation score pipeline

| Field | Value |
|---|---|
| Saved | 2026-06-05 10:50:47 |
| Commit | auto: add STT pronunciation score pipeline (Flutter → backend → DB) |
| Project | C:\project\vLearn2 |

---

## User

ok we can change stt/tts engine to get evaluation values from stt engine. If we change engine, then our project handle engine changes without many changes and also our database is all ready to accept these extra evaluation values of stt engine?

(followed by) can you implement the pipeline now? becareful about the situation that our current sherpa onnx doesn't provide the evaluation scores and so the application or backend api crash because of null or value not set.

## Assistant

Implemented the full STT pronunciation score pipeline across 7 layers. All values are nullable throughout — current sherpa-onnx produces null scores everywhere and no code path crashes on null.

### Changes made

**`speech_service.dart`**
- `SttResult` gets optional `pronunciationScore: double?` field (null = engine doesn't support it)
- `SttCapabilities` gets `supportsPronunciationScoring: bool` (defaults false)

**`sherpa_onnx_stt.dart`**
- Both `SttResult` returns (online + offline) leave `pronunciationScore` unset (null)
- Capabilities leave `supportsPronunciationScoring` at default false

**`tutor_mode_view.dart`**
- `TutorModeView` gains optional `onSttScore: void Function(double?)?`
- After each `transcribe()`, calls `widget.onSttScore?.call(result.pronunciationScore)`

**`conversation_screen.dart`**
- `_ConversationScreenState` gains `_turnPronunciationScores: List<double?>` accumulator
- `_addSttScore(double?)` appends each turn's score to the list
- `_end()` filters nulls, averages valid scores, passes to `endSession(pronunciationScore: avg)`
- `_TutorModeWrapper` and `_ChatModeBody` both get `onSttScore` wired to `_addSttScore`
- Chat mode `_stopRecording` calls `widget.onSttScore?.call(result.pronunciationScore)` after transcribe

**`app_apis.dart`**
- `endSession()` gains optional `pronunciationScore: double?`
- If non-null: converts 0.0–1.0 → 0–100 integer and includes in request body
- If null: omitted from body entirely (no field sent)

**`conversation.dto.ts`**
- `EndSessionDto` gains optional `pronunciationScore?: number` (0–100, validated)

**`conversations.service.ts`**
- `triggerEvaluation()` gains `sttData: { pronunciationScore: number | null }` parameter
- `pronunciation_score` column filled from `sttData.pronunciationScore` (null when sherpa-onnx)
- `endSession()` passes `dto.pronunciationScore ?? null` to `triggerEvaluation()`

### Null safety guarantees
- sherpa-onnx → `pronunciationScore: null` in SttResult
- null → not added to accumulator avg → `avgPronunciation = null`
- null → not included in HTTP body → backend receives no field
- missing field → `dto.pronunciationScore` is undefined → `?? null` → stored as SQL NULL
- No crash at any layer

### Adding a real pronunciation engine later
1. Create new class extending `SpeechToTextService` with `supportsPronunciationScoring: true`
2. Return real `pronunciationScore` in `SttResult`
3. Swap in `sttServiceProvider` — everything else is already wired

---

## Prompt

can you implement the pipeline now? becareful about the situation that our current sherpa onnx doesn't provide the evaluation scores and so the application or backend api crash because of null or value not set.
