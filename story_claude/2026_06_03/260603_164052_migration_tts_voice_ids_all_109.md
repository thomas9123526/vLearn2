# Conversation - Migration to populate tts.voice_ids with all 109 VCTK voices

| Field | Value |
|---|---|
| Saved | 2026-06-03 16:40:52 |
| Commit | Add migration to update tts.voice_ids to all 109 VCTK voices |
| Project | C:\project\vLearn2 |

---

## User

in admin panel, tutor page. in the TTS voice id fields, i can only view 2 items in dropdown list. i expected above 100 voiceids

## Assistant

Root cause: the seed preserves the existing `value` column for rows that already exist (to protect admin edits). So when the seed was updated to include all 109 voices, the DB row still held the old 2-voice value.

Fix: created migration `1782300000000-tts-voice-ids-all.ts` which force-updates `tts.voice_ids` value and default_value to all 109 VCTK voice IDs. After running `npm run migration:run` on the backend, the admin panel tutor dropdown will show all 109 voices.

---

## Prompt

in admin panel, tutor page. in the TTS voice id fields, i can only view 2 items in dropdown list. i expected above 100 voiceids
