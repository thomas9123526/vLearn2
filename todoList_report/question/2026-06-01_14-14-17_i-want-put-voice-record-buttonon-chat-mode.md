# I want put voice record buttonon chat mode screen like tutor mode screen. So the

Session: `d506161a-a027-47af-a3ba-75104b012999`
Saved: 2026-06-01T05:14:17.175Z

## User

I want put voice record buttonon chat mode screen like tutor mode screen.
So the user tap the button then voice start.
The user tap the button again to finish voice recognition.
Then the recognitioin text is sent to server immediately.
Btw if there's illegal words inside recognition text then the app must alert about the illegal words.

also where can i find the illegal words list

## Assistant

Let me explore both screens and the existing voice/illegal-words infrastructure before touching anything.

## Assistant

Good — I have everything I need. Let me read the exact sections before writing code.

## Assistant

Now let me check the current imports in `conversation_screen.dart` and how `ContentGuard` is initialized.

## Assistant

Let me check where `speechModelsStatusMessage` is defined.

## Assistant

Good. Now I have everything. Here's the implementation plan:

- Convert `_ChatModeBody` → `ConsumerStatefulWidget` with recording state
- Add `onSendVoiceText: Future<void> Function(String)` parameter  
- Add mic toggle button in the input row (inline, like the send button)
- `_stopRecording()`: transcribe → guard check → **block**: `AlertDialog` (don't send) → **warn**: `AlertDialog` with "Send anyway?" → **ok**: send immediately
- Pass the callback at the call site in `ConversationScreen`

## Assistant

I have a complete picture. Now I'll implement the changes:

1. Convert `_ChatModeBody` to `ConsumerStatefulWidget` with recording state
2. Add `_startRecording()` / `_stopRecording()` + guard check
3. Add a compact `_MicButton` to the input row
4. Wire up the call site

## Assistant

Expected — those imports will be used once I convert `_ChatModeBody`. Continuing with the main edit now.

## Assistant

Clean. Now commit with story.

## Assistant

Done. Here's what was added:

**Illegal words list:** [assets/guard/profanity_en.json](flutter_app/assets/guard/profanity_en.json), [profanity_ko.json](flutter_app/assets/guard/profanity_ko.json), [profanity_zh.json](flutter_app/assets/guard/profanity_zh.json) — each has a `"block"` array (message blocked) and `"warn"` array (mild language, user can choose to send anyway).

**Voice button behavior in chat mode:**
- Tap mic → recording starts (button turns red with stop icon)
- Tap again → recording stops, STT transcribes
- **Blocked word** → `AlertDialog` listing the terms, message discarded
- **Warn word** → `AlertDialog` "Send anyway?" — Cancel or Send
- **Clean** → text sent to server immediately, bypasses the text field

The input row is now: `[text field] [mic button] [send button]` — send button is disabled while recording or transcribing.
