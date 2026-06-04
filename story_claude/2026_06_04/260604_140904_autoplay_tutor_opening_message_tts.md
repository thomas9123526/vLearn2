# Conversation - Auto-play tutor opening message with TTS and lipsync

| Field | Value |
|---|---|
| Saved | 2026-06-04 14:09:04 |
| Commit | Auto-play tutor opening message on conversation screen entry |
| Project | C:\project\vLearn2 |

---

## User

[screenshot of conversation screen, "Turn 0", Maya greeting circled in red]
When i first enter at conversation screen, it's like the tutor first says like the red pencil.
But I can't hear the tutor voice. Play tts if there's first message of tutor and do character animation lipsync according to tts

## Assistant

**Root cause:** Both `_ChatModeBodyState` and `_TutorModeViewState` only call `_maybeSpeakLatestAssistantReply()` inside `didUpdateWidget()`. That method fires when the parent rebuilds with new props — but the opening message arrives in the *initial* `getSession()` response (the very first `data:` branch render), so `didUpdateWidget()` never fires for it.

**Fix (two changes per widget):**

1. `WidgetsBinding.instance.addPostFrameCallback` in `initState()` — speaks the opening message after the first frame is painted.
2. `ref.listen<bool>(speechReadyProvider, ...)` in `build()` — retries speaking if TTS models finish loading *after* the screen opens (models load asynchronously from disk).

**Files changed:**
- `flutter_app/lib/features/conversation/widgets/tutor_mode_view.dart` — `_TutorModeViewState`
- `flutter_app/lib/features/conversation/conversation_screen.dart` — `_ChatModeBodyState`

The existing lipsync/mood machinery (`TutorMood.speaking`, amplitude stream → Rive state machine) already works correctly for subsequent turns. No changes needed there — the fix only concerns triggering the first TTS call.

---

## Prompt

When i first enter at conversation screen, it's like the tutor first says like the red pencil.
But I can't hear the tutor voice. Play tts if there's first message of tutor and do character animation lipsync according to tts
