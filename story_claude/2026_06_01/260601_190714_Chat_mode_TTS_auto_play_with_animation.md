# Conversation - Chat mode TTS auto-play with animation

| Field | Value |
|---|---|
| Saved | 2026-06-01 19:07:14 |
| Commit | feat: auto-play TTS on AI reply in chat mode with wave animation |
| Project | C:\project\vLearn2 |

---

## User

In chat mode screen, when ai reply with message, I want the tts is playing and show animation that the tts is running and prevent any other actions until tts done.

## Assistant

Added TTS auto-play in chat mode. When a new assistant message arrives (detected via didUpdateWidget), _maybeSpeakLatestAssistantReply() calls tts.speak(). _ttsSpeaking subscribes to isSpeakingStream and blocks all UI (busy flag). A new _TtsPlayingBar widget shows sine-wave animated bars in the input row while TTS is active, replacing the text field. All actions (send, mic) are disabled until TTS completes.

---

## Prompt

In chat mode screen, when ai reply with message, I want the tts is playing and show animation that the tts is running and prevent any other actions until tts done.
