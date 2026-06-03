# Conversation - Fix TTS voice not changing per tutor

| Field | Value |
|---|---|
| Saved | 2026-06-03 12:05:47 |
| Commit | Fix TTS voice_id mismatch: update seed and add migration for manifest-compatible voice IDs |
| Project | C:\project\vLearn2 |

---

## User

ok tts is some changed.
But when i switch from Leo to Theo, and the tts speaker is female, but Theo is male on the database.
It always say the same voice, not change per tutor specific.

## Assistant

The root cause: the seed data had voice IDs (`en_GB-alan`, `en_AU-james`, etc.) that **don't exist in the manifest** (`en_VCTK-amy`, `en_VCTK-james`). 

The `_pickVoice()` priority-2 check only uses `voice_id` if it's in the manifest. So when the voice_id doesn't match, it falls through to the gender heuristic — which should work. But the actual DB likely had `voice_id = 'en_VCTK-amy'` set for all personas (from before `en_VCTK-james` was added to the manifest), so priority-2 would win and return the female voice for every tutor.

**Fix applied:**

1. Updated `backend/src/database/seeds/seeds/personas.seed.ts`:
   - Female personas (Maya, Sofia): `voice_id = 'en_VCTK-amy'`
   - Male personas (Leo, Theo): `voice_id = 'en_VCTK-james'`

2. Created migration `1782200000000-personas-voice-id-fix.ts` that directly UPDATEs the `vl_personas` table so re-seeding isn't required — run `npm run migration:run` on the backend.

---

## Prompt

ok tts is some changed.
But when i switch from Leo to Theo, and the tts speaker is female, but Theo is male on the database.
It always say the same voice, not change per tutor specific.
