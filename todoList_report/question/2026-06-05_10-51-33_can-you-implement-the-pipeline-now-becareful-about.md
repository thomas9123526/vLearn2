# can you implement the pipeline now?  becareful about the situation that our curr

Session: `40c2c32e-4bcc-4826-8449-440738f22ef6`
Saved: 2026-06-05T01:51:33.061Z

## User

can you implement the pipeline now?  becareful about the situation that our current sherpa onnx doesn't provide the evaluation scroes and so the application or backend api crash because of null or value not set.

## Assistant

Let me understand how Flutter collects STT results during a session before implementing.

## Assistant

Let me read the exact callback signatures and state structure before implementing.

## Assistant

Now I have everything. I'll implement all 7 layers in order. Let me start with the Flutter side, then the backend.

## Assistant

Now update `PlaceholderSttService` capabilities (already uses named args, just needs the new field):

## Assistant

Now update `sherpa_onnx_stt.dart` — capabilities flag + return `pronunciationScore: null` in both transcribe paths:

## Assistant

Good — `supportsPronunciationScoring` defaults to `false` so no explicit value needed for engines that don't support it. Now add `pronunciationScore: null` to the two `SttResult` returns in `sherpa_onnx_stt.dart`:

## Assistant

Now add `onSttScore` callback to `TutorModeView` and call it after `transcribe()`:

## Assistant

Now call `onSttScore` right after `transcribe()` in `_TutorModeViewState._stopRecording()`:

## Assistant

Now update `conversation_screen.dart` — accumulator, `_end()`, and both child widgets:

## Assistant

That warning will clear once I wire it to the child widgets. Continuing — update `_end()` to compute and send the aggregate:

## Assistant

Need to update `app_apis.dart` first to add the parameter:

## Assistant

Now pass `onSttScore` to `_TutorModeWrapper` and `_ChatModeBody` in `conversation_screen.dart`:

## Assistant

Need to add `onSttScore` to `_TutorModeWrapper` and thread it through to `TutorModeView`:

## Assistant

Now thread it through to `TutorModeView` inside `_TutorModeWrapper.build`:

## Assistant

Now add `onSttScore` to `_ChatModeBody` and call it in `_stopRecording`:

## Assistant

Need to add the field declaration to `_ChatModeBody`:

## Assistant

Now pass `onSttScore` when constructing `_ChatModeBody` in `build`, and call it in `_stopRecording`:

## Assistant

Now call `onSttScore` in `_ChatModeBodyState._stopRecording()` after `transcribe()`:

## Assistant

Now the backend — `EndSessionDto`, `conversations.service.ts`:

## Assistant

Now thread `pronunciationScore` from `dto` through `endSession` → `triggerEvaluation` → DB fields:

## Assistant

Need to update `triggerEvaluation`'s signature and use the data in the fields object:

## Assistant

Need to use `sttData` in the `fields` object:

## Assistant

Now verify both sides compile cleanly:

## Assistant

Both clean. Now commit with story file:

## Assistant

Done. Here's the complete picture of what was built and why nothing crashes with the current sherpa-onnx:

---

## Data flow end-to-end

```
sherpa-onnx transcribe()
  └─ SttResult.pronunciationScore = null   (hardcoded, engine doesn't score)

tutor_mode_view / chat _stopRecording
  └─ widget.onSttScore?.call(null)         (safe, ?. skips if no listener)

_ConversationScreenState._addSttScore(null)
  └─ _turnPronunciationScores = [null, null, ...]

_end()
  └─ validScores = [].whereType<double>()  (empty — all nulls filtered out)
  └─ avgPronunciation = null               (no valid scores)

endSession(pronunciationScore: null)
  └─ body = {'status': 'completed'}        (pronunciationScore omitted from body)

backend EndSessionDto.pronunciationScore   → undefined
triggerEvaluation sttData.pronunciationScore → null
DB pronunciation_score column              → NULL  ✓ (was already NULL before)
```

## Adding a real pronunciation engine later

Only **3 steps** needed — everything else is already wired:

```dart
// 1. New engine class
class AzureSttService extends SpeechToTextService {
  SttCapabilities get capabilities => const SttCapabilities(
    supportsPronunciationScoring: true, ...
  );
  Future<SttResult> transcribe(...) async {
    // ... call Azure SDK ...
    return SttResult(text: text, pronunciationScore: 0.87, ...);
  }
}

// 2. Swap provider
final sttServiceProvider = Provider((_) => AzureSttService());

// 3. Done — scores flow to DB automatically
```
