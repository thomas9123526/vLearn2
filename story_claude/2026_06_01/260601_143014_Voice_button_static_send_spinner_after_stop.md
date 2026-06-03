# Conversation - Voice button static, send spinner after stop

| Field | Value |
|---|---|
| Saved | 2026-06-01 14:30:14 |
| Commit | Keep mic button static after stop; show send button spinner during transcribe+send |
| Project | C:\project\vLearn2 |

---

## User

when the user release voice button then the voice button should be static and the send button must be in stay in progress while https on chat screen

## Assistant

Two changes to `_ChatModeBodyState` and `_ChatMicButton` in conversation_screen.dart:

1. Removed `transcribing` parameter from `_ChatMicButton` entirely — dropped the spinner branch. The mic button now just shows the static mic icon (disabled) after recording stops, never a spinner.

2. Send button icon condition changed from `widget.sending` to `widget.sending || _transcribing` — so it shows a progress indicator during both the STT transcription phase and the HTTP send phase, giving continuous feedback from the moment the user taps stop until the server reply lands.

---

## Prompt

when the user release voice button then the voice button should be static and the send button must be in stay in progress while https on chat screen
