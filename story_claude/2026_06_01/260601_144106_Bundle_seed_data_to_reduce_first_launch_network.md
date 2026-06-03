# Conversation - Bundle seed data to reduce first-launch network traffic

| Field | Value |
|---|---|
| Saved | 2026-06-01 14:41:06 |
| Commit | Add seed_fetch script and CacheSeeder to pre-bundle scenario/category data |
| Project | C:\project\vLearn2 |

---

## User

If there's many data like scenarios with image in backend api, the app will consume many traffic network amount when the app first launch.
I want prevent this.
So is it possible to wrap the application with the default database?

If so please make a script like tools to execute. If i execute the script then I get necessary information from the backend. then I put those inside application code, the .apk or .exe have those initial data.

## Assistant

Yes — the pattern is called "pre-seeded cache". The app ships with JSON assets bundled inside the APK/EXE; on first launch these are written into the SQLite `api_cache` table before any widget builds, so the scenario/category lists appear instantly.

**Files added/changed:**

`cmds/seed_fetch.ps1` (new tool script):
- `.\cmds\seed_fetch.ps1` — fetches `/api/scenarios` and `/api/categories`, writes to `flutter_app/assets/seed/*.json`
- `.\cmds\seed_fetch.ps1 -BaseUrl http://192.168.1.50:5101` — custom backend URL
- `.\cmds\seed_fetch.ps1 -WithImages` — also downloads scenario images to `assets/seed/images/` and rewrites `image_url`/`background_image_url` fields to `asset:seed/images/filename` so Flutter loads from the bundle

`flutter_app/assets/seed/scenarios.json` + `categories.json` — placeholder empty arrays (`[]`); replaced by real data after running the script.

`flutter_app/lib/core/cache/cache_seeder.dart` (new):
- `CacheSeeder.seedIfEmpty(CacheStore store)` — for each seed entry, checks if the cache key exists; if not, loads the asset JSON and writes it. Skips empty-array placeholders so a dev machine that hasn't run the script behaves normally.

`flutter_app/lib/main.dart` — added `await CacheSeeder.seedIfEmpty(container.read(cacheStoreProvider))` in the existing pre-`runApp` container window (after `appConfigProvider` is warmed, before `runApp`).

`flutter_app/pubspec.yaml` — registered `assets/seed/scenarios.json` and `assets/seed/categories.json`.

`flutter_app/lib/features/scenarios/scenario_brief_screen.dart` — added `_imageProvider()` and `_imageWidget()` helpers that check for `asset:` prefix (written by `-WithImages`) and use `AssetImage`/`Image.asset()` instead of `NetworkImage`/`Image.network()`. Updated `_resolveScenarioImage()` to pass `asset:` URLs through unchanged.

**Workflow:**
1. Run `.\cmds\seed_fetch.ps1 -BaseUrl http://localhost:5101`
2. Rebuild: `cd flutter_app && flutter build apk`
3. The new APK has the scenario list pre-bundled — first launch shows data with no API call

Images are still lazy-loaded from the network by default. Use `-WithImages` to also bundle them (larger APK, zero network on first scenario view).

---

## Prompt

If there's many data like scenarios with image in backend api, the app will consume many traffic network amount when the app first launch.
I want prevent this.
So is it possible to wrap the application with the default database?

If so please make a script like tools to execute. If i execute the script then I get necessary information from the backend. then I put those inside application code, the .apk or .exe have those initial data.
