# When i first enter at conversation screen, it's like the tutor first says like t

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-04T05:09:48.920Z

## User

When i first enter at conversation screen, it's like the tutor first says like the red pencil.
But I can't hear the tutor voice. Play tts if there's first message of tutor and do charcter animation lipsync according to tts

## Assistant

Let me explore the conversation screen and TTS system to understand the current setup:

## Assistant

Let me read the actual implementation files to see exactly why the first message isn't played:

## Assistant

Now let me read `tutor_mode_view.dart`:

## Assistant

Found the bug. The root cause: both `_ChatModeBodyState` and `_TutorModeViewState` only call `_maybeSpeakLatestAssistantReply()` in `didUpdateWidget()` — which never fires on **first creation**. The opening message arrives with the initial `getSession()` response, so TTS is never triggered for it.

Two fixes per widget:
1. `addPostFrameCallback` in `initState()` → speak on first render
2. `ref.listen(speechReadyProvider)` in `build()` → retry if models load after the screen opens

## Assistant

Now the same fix for chat mode:

## Assistant

Now verify the Dart analyser is happy:

## Assistant

Clean. Committing:

## Assistant

**Done.** The fix is in two places, applied to both tutor mode and chat mode:

| Where | What was added |
|---|---|
| `initState()` | `addPostFrameCallback` → speaks the opening message after the first frame (covers the normal case: models ready on entry) |
| `build()` | `ref.listen(speechReadyProvider)` → retries when TTS models finish loading (covers the race case: models still downloading when screen opens) |

The existing lipsync pipeline (`TutorMood.speaking` → Rive amplitude input) already handles the animation correctly — it kicks in automatically via the `isSpeakingStream` listener that was already in `initState()`. So once TTS starts playing the opening message, Maya's mouth will animate to match.
