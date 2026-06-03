# Conversation - Fix TTS UI block and male+young→female voice bug

| Field | Value |
|---|---|
| Saved | 2026-06-03 13:36:10 |
| Commit | Fix TTS UI freeze on screen entry and male+young voice falling back to female |
| Project | C:\project\vLearn2 |

---

## User

When i enter conversation screen, it starts tts and the screen ui seems like block.
Can you handle this?
Also I when i change tutor for leo, it is male young in the database.
But the tts is like female voice.

## Assistant

Two root causes found and fixed:

**Fix 1 — UI freeze on entry (`speech_service.dart`)**
`so.OfflineTts(...)` loads the 38 MB ONNX model synchronously on the main Dart isolate when `speak()` is first called (lazy init). This blocks the UI. Fix: call `svc.initialize()` immediately when the `ttsServiceProvider` creates the service (model registry is ready). The engine warms up in the background before the user ever enters a conversation.

**Fix 2 — male+young → female voice (`tutor_mode_view.dart` `_pickVoice`)**
The heuristic narrowed `maleHints ∩ youngHints = ['ryan']`. No VCTK voice name contains "ryan", so the match returned `''` and fell all the way through to `voices.first` (= `en_VCTK-amy`, female). Fix: when the age-narrowed hints yield no match, retry with gender-only hints before falling back to `voices.first`.

---

## Prompt

When i enter conversation screen, it starts tts and the screen ui seems like block.
Can you handle this?
Also I when i change tutor for leo, it is male young in the database.
But the tts is like female voice.
