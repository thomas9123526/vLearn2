# If there's many data like scenarios with image in backend api, the app will cons

Session: `d506161a-a027-47af-a3ba-75104b012999`
Saved: 2026-06-01T05:41:54.205Z

## User

If there's many data like scenarios with image in backend api, the app will consume many traffic network amount when the app first launch.
I want prevent this.
So is it possible to wrap the application with the default database?

If so please make a script like tools to execute. If i execute the script then I get necessary information from the backend. then I put those inside application code, the .apk or .exe have those initial data.

## Assistant

Good question. This is a "database bundling" pattern — ship a pre-seeded SQLite/JSON cache inside the APK so the first launch shows data instantly without any network call. Let me read the exact cache key format and the providers before designing this.

## Assistant

Let me read `main.dart` to understand the startup flow before designing the seeder.

## Assistant

I have everything I need. The cache key is `'scenarios'` (global) and `'categories'`. The container is already created in `main()` before `runApp`. Here's the full implementation plan:

1. **`cmds/seed_fetch.ps1`** — tool script that hits the API and writes `assets/seed/*.json` (and optionally downloads images)
2. **`flutter_app/assets/seed/`** — placeholder seed files (empty arrays until the script runs)
3. **`flutter_app/lib/core/cache/cache_seeder.dart`** — reads seed JSON into `api_cache` on first launch
4. **`main.dart`** — call seeder in the existing pre-`runApp` container window
5. **`pubspec.yaml`** — register the seed assets
6. **`scenario_brief_screen.dart`** — handle `asset:` prefix image URLs from bundled images

## Assistant

Now wire it into `main.dart` and update `pubspec.yaml`.

## Assistant

Need to add the actual call in `main()`.

## Assistant

Now add the seed assets to `pubspec.yaml` and handle the `asset:` prefix in the scenario image resolver.

## Assistant

Now fix `scenario_brief_screen.dart` so the `asset:` prefix (written by `-WithImages`) doesn't get mangled by `uploadsOrigin` prepending, and the image widgets use the right loader.

## Assistant

Three edits: update `_resolveScenarioImage` to pass `asset:` through unchanged, swap `Image.network` for a helper, and swap `NetworkImage` for `_imageProvider`.

## Assistant

Now replace the two hardcoded `Image.network` / `NetworkImage` calls with the helpers.

## Assistant

Clean. Now commit with story.

## Assistant

Done. Here's how to use it:

**Run the tool once against your backend:**
```powershell
.\cmds\seed_fetch.ps1 -BaseUrl http://localhost:5101
```
This writes real scenario/category data to [assets/seed/scenarios.json](flutter_app/assets/seed/scenarios.json) and [categories.json](flutter_app/assets/seed/categories.json).

**Then rebuild:**
```powershell
cd flutter_app
flutter build apk   # or flutter build windows
```

**What happens at runtime:**
- Cold start → `CacheSeeder.seedIfEmpty()` runs in `main()` before any widget builds → writes seed JSON into SQLite `api_cache`
- Home/scenario screen shows data instantly (zero network)
- Background network fetch runs as normal, overwrites the cache with fresh data
- Every subsequent launch: cache already exists → seeder skips → no overhead

**For bundling images too** (larger APK, no network even for images):
```powershell
.\cmds\seed_fetch.ps1 -WithImages
```
Images land in `assets/seed/images/` and the JSON gets `asset:seed/images/xxx.png` URLs. Add `assets/seed/images/` to `pubspec.yaml` then rebuild. The `_imageWidget`/`_imageProvider` helpers in [scenario_brief_screen.dart](flutter_app/lib/features/scenarios/scenario_brief_screen.dart) already handle both URL types.
