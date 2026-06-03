# Conversation - Store TTS voice IDs in app config DB

| Field | Value |
|---|---|
| Saved | 2026-06-03 13:07:17 |
| Commit | Store tts.voice_ids in vl_app_config DB instead of TTS_VOICE_IDS env var |
| Project | C:\project\vLearn2 |

---

## User

can you put those TTS_VOICE_IDS in the databases?

## Assistant

Used the existing `vl_app_config` key-value table (which already supports `array` type) to store the voice IDs.

**Changes:**
1. `app-config.seed.ts` — added `tts.voice_ids` entry (`array`, category `system`, default `['en_VCTK-amy', 'en_VCTK-james']`, not visible to app)
2. `admin.module.ts` — added `AppConfigEntity` to TypeORM feature imports
3. `admin-personas.controller.ts` — injected `Repository<AppConfigEntity>`, `getTtsVoices()` now reads from DB key `tts.voice_ids` instead of `TTS_VOICE_IDS` env var

To update the voice list after running the seed, use the existing admin config endpoint:
```
PATCH /admin/config/tts.voice_ids
{ "value": ["en_VCTK-amy", "en_VCTK-james", "en_VCTK-p227-male", ...] }
```

---

## Prompt

can you put those TTS_VOICE_IDS in the databases?
