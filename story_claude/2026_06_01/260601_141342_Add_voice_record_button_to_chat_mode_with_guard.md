# Conversation - Add voice record button to chat mode with content guard

| Field | Value |
|---|---|
| Saved | 2026-06-01 14:13:42 |
| Commit | Add voice record button to chat mode with content guard alert |
| Project | C:\project\vLearn2 |

---

## User

I want put voice record button on chat mode screen like tutor mode screen.
So the user tap the button then voice start.
The user tap the button again to finish voice recognition.
Then the recognition text is sent to server immediately.
Btw if there's illegal words inside recognition text then the app must alert about the illegal words.

also where can i find the illegal words list

## Assistant

**Illegal words list location:** `flutter_app/assets/guard/profanity_{en,ko,zh}.json` — each file has a `"block"` list (hard-blocked words) and a `"warn"` list (mild language).

**Implementation:**

- Converted `_ChatModeBody` from `StatelessWidget` → `ConsumerStatefulWidget` + `_ChatModeBodyState`
- Added `onSendVoiceText: Future<void> Function(String)` parameter; wired to `_send` at the call site
- Added `_recording` / `_transcribing` state
- `_startRecording()`: requests mic permission, starts `audioRecorderProvider`, sets `_recording = true`
- `_stopRecording()`: stops recorder → checks `speechReadyProvider` → transcribes with `sttServiceProvider` → runs `ContentGuard.instance.check(text)`:
  - **`block`**: `AlertDialog` listing the matched terms, message not sent
  - **`warn`**: `AlertDialog` with "Cancel / Send anyway?" choice
  - **`ok`**: calls `widget.onSendVoiceText(text)` immediately
- Added `_ChatMicButton` widget: inline in the input row between the text field and send button; shows `Icons.mic_rounded` when idle, `Icons.stop_rounded` (red) when recording, spinner when transcribing
- Send button disabled while recording or transcribing

---

## Prompt

I want put voice record button on chat mode screen like tutor mode screen.
So the user tap the button then voice start.
The user tap the button again to finish voice recognition.
Then the recognition text is sent to server immediately.
Btw if there's illegal words inside recognition text then the app must alert about the illegal words.

also where can i find the illegal words list
