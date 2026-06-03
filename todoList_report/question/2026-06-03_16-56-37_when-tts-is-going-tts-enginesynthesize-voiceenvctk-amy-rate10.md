# when tts is going,  [tts] engine.synthesize voice=en_VCTK-amy rate=1.0 len=66 wa

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-03T07:56:37.275Z

## User

when tts is going, 
[tts] engine.synthesize voice=en_VCTK-amy rate=1.0 len=66 wav=136748B in 10ms

the voice doen't fetch from the tutor table. I select tutor as Maya and in the admin panel, i have set en_VCTK-p273-m for Maya tutor.

## Assistant

The TTS is falling through to `voices.first` (`en_VCTK-amy`) instead of using Maya's configured voice. Let me trace the full path from tutor data to voice selection.

## Assistant

Now let me check `Persona.fromJson` and the backend teacher response to find where `voice_id` is getting lost.

## Assistant

Now let me check the public teachers controller to see if `voice_id` is included in the response.

## Assistant

The entity has `voice_id` and `fromJson` maps it. The issue is likely elsewhere — let me check the personas provider for any local caching that might return stale data without `voice_id`.

## Assistant

No local cache — it fetches fresh from the API each time. The issue must be in how `_pickVoice` gets its `voices` list. Let me check exactly how it's called.

## Assistant

`tts.capabilities.availableVoices` is populated from `manifest.voices` at init time. If that list doesn't contain `en_VCTK-p273-m`, step 2 is silently skipped and the female heuristic picks `en_VCTK-amy`. Let me check how the manifest loads voices.

## Assistant

Let me read the actual manifest file the app is using to check if it really has 109 voices.

## Assistant

The manifest has `en_VCTK-p273-m`. So `voices.contains()` would be true — meaning `persona.voiceId` must be null when reaching step 2. Let me check the admin panel edit page to see if `voice_id` is actually being sent in the PATCH.

## Assistant

Everything on the write side looks correct. Let me read the tutor mode view to see exactly when `_pickVoice` is called and whether the persona has been fully loaded at that point.

## Assistant

The whole chain is correct — the bug must be that `persona.voiceId` is null by the time `_pickVoice` sees it. Let me add a temporary debug print to confirm exactly what arrives, which will tell us whether the problem is on the Flutter side (API response not mapping) or the backend side (DB not persisted).

## Assistant

Run the app again and look for the new `[tts] persona=` line in the log. It will show exactly what `voiceId` and `ttsVoiceSid` the Flutter app received for Maya. Then:

- If `voiceId=null` → the DB doesn't have `en_VCTK-p273-m` saved (admin panel save didn't persist, or migration reset it). Check the Preview panel on the admin tutor page — it shows `Voice id:` on the right side.
- If `voiceId=en_VCTK-p273-m` but voices is small (e.g. `voices=2`) → the manifest on the device only has 2 voices; the model root isn't pointing to the updated manifest.
- If `voiceId=en_VCTK-p273-m` and `voices=109` → there's a string comparison issue and I'll dig deeper.

Paste the `[tts] persona=` line here and I'll know exactly which case it is.
