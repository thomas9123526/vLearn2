# can  you put those TTS_VOICE_IDS in the databases?

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-03T04:07:42.177Z

## User

can  you put those TTS_VOICE_IDS in the databases?

## Assistant

Let me check if there's already an app config / settings table in the backend.

## Assistant

There's already a `vl_app_config` key-value table — perfect for this. Let me check how it's used.

## Assistant

The `vl_app_config` table already supports `array` type and has a seed + admin API. I'll store `tts.voice_ids` there. Let me check which module registers the admin personas controller.

## Assistant

Now I have everything I need. The plan:
1. Add `tts.voice_ids` entry to the app-config seed
2. Inject `AppConfigEntity` repo into `AdminPersonasController` and read from DB
3. Add `AppConfigEntity` to admin module's TypeORM feature list

## Assistant

Now I'll make all three changes in parallel:

## Assistant

Now update the admin module to include `AppConfigEntity`:

## Assistant

Now update `AdminPersonasController` to inject the repo and read from DB:

## Assistant

Now find the constructor and inject the AppConfigEntity repo:

## Assistant

Now commit everything:

## Assistant

Done. Here's what changed and how to use it:

**How it works now:**
- Voice IDs are stored in `vl_app_config` under key `tts.voice_ids` (array type)
- The admin panel dropdown fetches from `GET /admin/teachers/tts/voices` which reads that DB row
- No more env var needed

**To add voices after running the seed**, use the existing admin config API:
```
PATCH /admin/config/tts.voice_ids
{ "value": ["en_VCTK-amy", "en_VCTK-james", "en_VCTK-p227-male", ...] }
```

Or the admin panel already has a Config page at `/admin/config` where you can edit `tts.voice_ids` directly through the UI.
