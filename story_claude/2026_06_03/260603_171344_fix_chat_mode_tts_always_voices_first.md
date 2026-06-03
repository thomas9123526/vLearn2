# Conversation - Fix chat mode TTS always using voices.first instead of persona voice

| Field | Value |
|---|---|
| Saved | 2026-06-03 17:13:44 |
| Commit | Fix chat mode TTS ignoring persona voice_id, always using voices.first |
| Project | C:\project\vLearn2 |

---

## User

on conversation_screen.dart 370 line:
final voiceId = voices.isNotEmpty ? voices.first : '';
why voiceId - voices.first? it would be the value for the tutor tts voice id.
and if tutor tts voice id is null then it must reference age and gender.

## Assistant

Found the root cause: `_ChatModeBody._maybeSpeakLatestAssistantReply` (chat mode) had a separate, simplified copy of the voice-selection logic that always picked `voices.first`. It never read the persona at all.

Tutor mode (`TutorModeView._maybeSpeakLatestAssistantReply`) had the correct `_pickVoice` logic (priority: ttsVoiceSid → voiceId → gender+age heuristic → voices.first), but chat mode was skipping all of that.

Fix:
1. Extracted `_pickVoice` body to a top-level function `pickVoiceForPersona()` in `tutor_mode_view.dart` so both modes share it.
2. Added `personaId` parameter to `_ChatModeBody`.
3. Updated chat mode's `_maybeSpeakLatestAssistantReply` to read the persona via `personaByIdProvider` and call `pickVoiceForPersona()` instead of `voices.first`.

---

## Prompt

on conversation_screen.dart 370 line:
final voiceId = voices.isNotEmpty ? voices.first : '';
why voiceId - voices.first? it would be the value for the tutor tts voice id.
and if tutor tts voice id is null then it must reference age and gender.
