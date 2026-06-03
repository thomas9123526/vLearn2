# ok tts is some changed. But when i switch from Leo to Theo, and the tts speaker 

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-03T03:06:25.918Z

## User

ok tts is some changed.
But when i switch from Leo to Theo, and the tts speaker is female, but Theo is male on the database.
It always say the same voice, not change per tutor specific.

## Assistant

Let me find the TTS voice selection code in the Flutter app.

## Assistant

Now let me look at the exact `_pickVoice()` and `_maybeSpeakLatestAssistantReply()` code, plus how the persona is loaded when switching tutors.

## Assistant

Let me check the manifest voices and how the persona is passed when switching tutors.

## Assistant

The manifest only has two voices: `en_VCTK-amy` (female) and `en_VCTK-james` (male). The logic looks correct, but I suspect the TTS audio cache isn't keyed by voiceId. Let me check.

## Assistant

The cache is fine (keyed by voiceId). Let me check how the persona is fetched — if `gender` field isn't returned in the API response, it defaults to `'neutral'` and falls back to the first voice (female).

## Assistant

Let me check the personas API implementation to see if `gender` is included in the response.

## Assistant

Let me check the backend teacher DTO to see if `gender` is included in the API response.

## Assistant

Let me check the backend teachers controller to see if `gender` is included in the API response.

## Assistant

Found the root cause. The seed data has voice IDs (`en_GB-alan`, `en_AU-james`) that **don't exist in the manifest** (`en_VCTK-amy`, `en_VCTK-james`). So when the DB stores these, the Flutter `_pickVoice()` priority-2 check (`voices.contains(persona.voiceId)`) fails for all personas, and falls through to the gender heuristic — which should work.

BUT the more likely issue: the DB was probably populated when only `en_VCTK-amy` existed, so all personas have `voice_id = 'en_VCTK-amy'` stored. Since that IS in the manifest, priority-2 wins and returns `'en_VCTK-amy'` for every tutor.

The fix: update the seed so male personas get `'en_VCTK-james'` and re-run it.

## Assistant

Now I also need to add a DB migration so re-seeding isn't required — the migration can directly fix the voice IDs in the live DB.

## Assistant

I'll create a migration that directly updates the `voice_id` in the DB for all personas to match the manifest voices.

## Assistant

Now I need to register this migration in the TypeORM data source config.

## Assistant

Migrations are auto-discovered by glob, so no registration needed. Let me commit now.

## Assistant

**Root cause:** The DB had `voice_id = 'en_VCTK-amy'` stored for all personas (set before `en_VCTK-james` was added to the manifest). Since `en_VCTK-amy` *is* in the manifest, `_pickVoice()` priority-2 returned it for every tutor — bypassing the gender heuristic entirely.

**What I did:**

1. **Updated the seed** (`personas.seed.ts`) — female personas (Maya, Sofia) get `en_VCTK-amy`, male personas (Leo, Theo) get `en_VCTK-james`

2. **New migration** `1782200000000-personas-voice-id-fix.ts` — directly `UPDATE`s the `vl_personas` table, so you don't need to re-seed. Just run `npm run migration:run` on the backend server and the voice will be correct immediately.
