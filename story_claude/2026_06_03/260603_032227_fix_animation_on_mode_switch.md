# Conversation - Fix speaking/listening animation after mode switch mid-TTS

| Field | Value |
|---|---|
| Saved | 2026-06-03 03:22:27 |
| Commit | fix: snapshot isSpeaking at mount so animations work when switching modes mid-TTS |
| Project | C:\project\vLearn2 |

---

## User

when tts is going on and i switch mode to tutor or chat mode then target animation is not working. like character speaking or listening bar at the bottom

## Assistant

Root cause: `isSpeakingStream` is a broadcast stream that only emits on state *changes*. When a mode widget mounts mid-TTS, no event fires and it initialises with idle/false — never catching up. Fixed by reading `tts.isSpeaking` (synchronous getter) in `initState()` before subscribing, so the widget starts with the correct state. Changes: added `isSpeaking` to `TextToSpeechService` abstract class and `PlaceholderTtsService`, then used it in `_TutorModeViewState.initState()` and `_ChatModeBodyState.initState()`.

---

## Prompt

when tts is going on and i switch mode to tutor or chat mode then target animation is not working. like character speaking or listening bar at the bottom
