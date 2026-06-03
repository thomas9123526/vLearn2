# on conversation_screen.dart 370 line: final voiceId = voices.isNotEmpty ? voices

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-03T08:14:12.113Z

## User

on conversation_screen.dart 370 line:

final voiceId = voices.isNotEmpty ? voices.first : '';

why voiceId - voices.first? it would be the value for the tutor tts voice id.
and if tutor tts voice id is null then it must reference age and gender.

## Assistant

Let me read the context around that line.

## Assistant

Found the real bug. This is the **chat mode** `_maybeSpeakLatestAssistantReply` — a completely separate copy that always hardcodes `voices.first`. It never reads the persona at all. Let me see what class this is in and what persona data is available.

## Assistant

`_ChatModeBody` has no persona field — that's the bug. I need to find where it's constructed to add the persona, then fix the voice selection.

## Assistant

The fix requires three changes:
1. Extract `_pickVoice` as a top-level function (so both widgets can use it)
2. Pass `personaId` into `_ChatModeBody`
3. Watch the persona inside chat mode and use `_pickVoice` instead of `voices.first`

Let me read the `_ChatModeBodyState.build` first.

## Assistant

Good. Now I have everything I need. Making all three changes:

## Assistant

Now make the changes. First, promote `_pickVoice` to a top-level function in `tutor_mode_view.dart`:

## Assistant

Now I'll move `_pickVoice` to a top-level function and update the call site in the same file:

## Assistant

The edit left the function body dangling. Let me read the current state and fix it properly.

## Assistant

I need to remove the dangling old body and add `pickVoiceForPersona` as a top-level function after the class.

## Assistant

Now find the end of the file to append the top-level function:

## Assistant

Now fix `conversation_screen.dart` — add `personaId` to `_ChatModeBody`, watch the persona, and use `pickVoiceForPersona`:

## Assistant

Good — `personas_provider.dart` and `tutor_mode_view.dart` are already imported. Now make the three changes to `conversation_screen.dart`:

## Assistant

Now add `personaId` to `_ChatModeBody` and fix the `_maybeSpeakLatestAssistantReply`:

## Assistant

Now fix `_maybeSpeakLatestAssistantReply` in chat mode to use the persona:

## Assistant

Now commit and save the story:

## Assistant

That was the bug. There were **two separate** `_maybeSpeakLatestAssistantReply` functions:

- **Tutor mode** (`tutor_mode_view.dart`) — had the correct `_pickVoice` logic
- **Chat mode** (`conversation_screen.dart`) — had a simple `voices.first` that ignored the persona entirely

Now both use `pickVoiceForPersona()` which follows the correct priority: `ttsVoiceSid` → `voiceId` → gender+age heuristic → `voices.first`.
