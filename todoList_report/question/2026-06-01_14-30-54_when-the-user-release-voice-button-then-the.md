# when the user release voice button then the voice button should be static and th

Session: `d506161a-a027-47af-a3ba-75104b012999`
Saved: 2026-06-01T05:30:54.249Z

## User

when the user release voice button then the voice button should be static and the send button must be in stay in progress while https on chat screen

## Assistant

Two small, targeted changes:
1. `_ChatMicButton` — drop the transcribing spinner, just go static/disabled
2. Send button — show the spinner whenever `_transcribing || widget.sending`

## Assistant

Done. The behavior is now:

- **Tap stop** → mic button instantly goes static (disabled mic icon, no spinner)
- **Send button** shows a progress spinner from that moment through the entire pipeline: STT transcription → guard check → HTTP `sendMessage` — until the server response lands
