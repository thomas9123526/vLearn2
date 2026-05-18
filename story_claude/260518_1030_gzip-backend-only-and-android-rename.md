# Backend-only gzip + Android package rename + Windows model path fix

## What this task did

Three independent changes bundled together because they all came from `todoList/0518_v1/manual.txt`:

### 1. Speech models path on Windows (response to user's "Speech models not installed" while files were at `C:\Users\aaa\AppData\Roaming\com.vlearn2\Virtual Foreign Language\models`)

The previous code resolved the model root via `getApplicationSupportDirectory()`, which on Windows depends on Flutter's `package_info_plus` → `path_provider_windows` lookup chain. With the recent VERSIONINFO rename ("Virtual Foreign Language") the resolved path was something like `%APPDATA%\Virtual Foreign Language\` — not at all what the user typed. Worse, it would silently change again if anyone tweaked `Runner.rc`.

Fixed by hardcoding the Windows path to `%APPDATA%\VLearn2\models` (read from `Platform.environment['APPDATA']`). The path is now:
- Stable across rebuilds and VERSIONINFO edits.
- Easy to communicate ("paste `%APPDATA%\VLearn2\` into Explorer").
- Still falls back to `getApplicationSupportDirectory()` on every other desktop platform.

Android is unchanged (still `getExternalStorageDirectory()`).

### 2. Gzip toggle — backend only (manual.txt §3)

The Flutter app used to carry its own "Compress large responses" toggle in Settings → Network. Per the user's spec it should be an admin-side switch and the app simply honors whatever the backend reports.

- Removed `AppSettingsState.compressionEnabled`, the `_kCompression` key, `setCompressionEnabled()`, and `compressionEnabledProvider`.
- Removed the SwitchListTile and "Network" section header from `settings_screen.dart`.
- Added `core/providers/backend_flags_provider.dart`: a `FutureProvider` that calls `GET /app-config` once per session, plus a `backendGzipEnabledProvider` selector that returns `flags['system.gzip_enabled'] ?? true`. Default is `true` so the very first request still benefits from gzip if the server has it on.
- `compression_interceptor.dart` now reads the backend provider instead of the local settings one.
- Bumped `system.gzip_enabled` in [backend/src/database/seeds/seeds/app-config.seed.ts](../backend/src/database/seeds/seeds/app-config.seed.ts) to explicit `is_visible_to_app: true` (the entity column defaults to `true`, but spelling it out keeps the catalog self-documenting).

The provider file lives in `core/providers/` (not `app_apis.dart`) on purpose: the interceptor is wired up inside `apiClientProvider`, so putting the provider in `app_apis.dart` would create an import cycle.

### 3. Android package rename → `com.ryongma.vfls` (manual.txt §4)

- `android/app/build.gradle.kts`: `namespace` and `applicationId` flipped from `com.vlearn2.flutter_app` to `com.ryongma.vfls`.
- `MainActivity.kt` moved from `kotlin/com/vlearn2/flutter_app/` to `kotlin/com/ryongma/vfls/` with a matching `package` declaration. The old directory tree is deleted.
- `AndroidManifest.xml` already uses `.MainActivity` (short form) for the activity name, so it resolves correctly against the new `applicationId` without edits.

⚠️ Side-effects worth knowing about:
- All existing `flutter_secure_storage` entries (auth tokens, the "remember me" password) will be inaccessible — they're keyed to the old `applicationId`. Users will need to sign in again on first run after the rename.
- `SharedPreferences` data is also lost (stored under `/data/data/com.ryongma.vfls/shared_prefs/`).
- Next `flutter run` will install the app as a fresh package alongside any old install; uninstall the old one (`com.vlearn2.flutter_app`) manually if needed.

## Files

| Path | Change |
|------|--------|
| [flutter_app/lib/core/storage/model_registry.dart](../flutter_app/lib/core/storage/model_registry.dart) | Windows model root → `%APPDATA%\VLearn2\models` |
| [flutter_app/lib/core/providers/backend_flags_provider.dart](../flutter_app/lib/core/providers/backend_flags_provider.dart) | NEW — fetches `/app-config` flags, exposes `backendGzipEnabledProvider` |
| [flutter_app/lib/core/providers/settings_provider.dart](../flutter_app/lib/core/providers/settings_provider.dart) | Removed `compressionEnabled` field, key, setter, provider |
| [flutter_app/lib/core/api/interceptors/compression_interceptor.dart](../flutter_app/lib/core/api/interceptors/compression_interceptor.dart) | Reads `backendGzipEnabledProvider` instead of local setting |
| [flutter_app/lib/features/settings/settings_screen.dart](../flutter_app/lib/features/settings/settings_screen.dart) | Deleted Network section + gzip SwitchListTile |
| [backend/src/database/seeds/seeds/app-config.seed.ts](../backend/src/database/seeds/seeds/app-config.seed.ts) | `system.gzip_enabled` explicitly `is_visible_to_app: true` |
| [flutter_app/android/app/build.gradle.kts](../flutter_app/android/app/build.gradle.kts) | `namespace` + `applicationId` → `com.ryongma.vfls` |
| flutter_app/android/app/src/main/kotlin/com/ryongma/vfls/MainActivity.kt | NEW location for `MainActivity` |
| flutter_app/android/app/src/main/kotlin/com/vlearn2/ | DELETED |
| [todoList_report/0518_v1/speech_models_prep.md](../todoList_report/0518_v1/speech_models_prep.md) | Windows path doc updated to `%APPDATA%\VLearn2\models` |

## User prompt (verbatim)

> When i start conversation, I get error lie this "Speech models not installed"
> I put models inside "C:\Users\aaa\AppData\Roaming\com.vlearn2\Virtual Foreign Language\models"

> 3. I found gzip options exists on both application side and backend side. I want put the gzip option on backend side only. So admin can enable or disable gzip on admin panel. And the application reads the gzip option and do the network communication with or without gzip. the default gzip option is enabled.
>
> 4. I want change android package to com.ryongma.vfls
