# In chat mode screen, when ai reply with message, I want the tts is playing and s

Session: `90c5c6ba-f941-45bb-8889-37114ea77f9f`
Saved: 2026-06-01T10:07:24.542Z

## User

In chat mode screen, when ai reply with message, I want the tts is playing and show animation that the tts is running and prevent any other actions until tts done.

## Assistant

Let me explore the chat mode and TTS setup before planning anything.

## Assistant

Good — I have a complete picture. Now let me read the key areas before writing code:

## Assistant

Now I have everything I need. Let me implement:

1. **`_ChatModeBodyState`**: add `_ttsSpeaking` state, subscribe to `isSpeakingStream`, detect new assistant messages → auto-speak, include in `busy`
2. **New `_TtsPlayingBar` widget**: sine-wave animated bars replacing the input row while TTS plays

## Assistant

That's expected — `dart:math` will be used by `_TtsPlayingBar` which I'm about to add. Continuing:

## Assistant

Still in progress — now wire `_ttsSpeaking` into `busy` and show the animation bar in the input row:

## Assistant

Now replace the input area to show the TTS bar when speaking:

## Assistant

Now add the `_TtsPlayingBar` widget after `_VoiceWaveform`:

## Assistant

No more errors. Now commit:

## Assistant

Done. Here's what was added to [conversation_screen.dart](flutter_app/lib/features/conversation/conversation_screen.dart):

**`_ChatModeBodyState`:**
- `_ttsSpeaking` / `_lastSpokenId` / `_ttsSub` fields
- `initState` — subscribes to `ttsServiceProvider.isSpeakingStream`
- `didUpdateWidget` — triggers `_maybeSpeakLatestAssistantReply()` when messages list grows
- `dispose` — cancels the stream subscription
- `_maybeSpeakLatestAssistantReply()` — guards on role/id/speechReady, then calls `tts.speak()`
- `busy` now includes `_ttsSpeaking` → send button and mic are disabled during playback

**`_TtsPlayingBar`** — a new `StatefulWidget` with an `AnimationController` (700 ms loop) driving 5 bars via `sin()` with symmetric phase offsets, so the centre bar peaks first and outer bars ripple outward. Uses `colorScheme.secondary` to visually distinguish it from the green mic waveform.
