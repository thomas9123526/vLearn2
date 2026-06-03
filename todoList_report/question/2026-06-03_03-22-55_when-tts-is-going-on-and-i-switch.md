# when tts is going on and i switch mode to tutor or chat mode then target animati

Session: `f56bdf13-4b13-4f2d-9e88-40dba40b3f91`
Saved: 2026-06-02T18:22:55.131Z

## User

when tts is going on and i switch mode to tutor or chat mode then target animation is not working.
like character speaking or listening bar at the bottom

## Assistant

Let me look at how mode switching interacts with TTS and animations:

## Assistant

Let me read the key files directly:

## Assistant

The bug is clear. Both `_TutorModeViewState` and `_ChatModeBodyState` subscribe to `isSpeakingStream` in `initState()` — but that stream is broadcast and only emits on **state changes**. When a mode mounts mid-TTS, no event fires, so the new widget starts with `_mood = idle` / `_ttsSpeaking = false` and never updates.

Fix: snapshot `tts.isSpeaking` synchronously at mount time, before the stream subscription:

## Assistant

`isSpeaking` is only on `SherpaOnnxTtsService`, not on the `TextToSpeechService` abstract class. Add it to the abstract class:

## Assistant

The `PlaceholderTtsService` needs the implementation too. Let me check it:

## Assistant

Now fix `_ChatModeBodyState` the same way:

## Assistant

No more diagnostics errors. Now commit:

## Assistant

Done. Three files changed:

- [speech_service.dart](flutter_app/lib/core/speech/speech_service.dart) — added `bool get isSpeaking` to the abstract class and `PlaceholderTtsService`
- [tutor_mode_view.dart](flutter_app/lib/features/conversation/widgets/tutor_mode_view.dart) — reads `tts.isSpeaking` on mount to set initial `_mood`
- [conversation_screen.dart](flutter_app/lib/features/conversation/conversation_screen.dart) — reads `tts.isSpeaking` on mount to set initial `_ttsSpeaking`

Hot restart and the character/bar will correctly show speaking state even when you switch modes mid-TTS.
