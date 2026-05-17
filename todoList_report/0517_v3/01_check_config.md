# Report — 01 — On-disk app config file

Built the config-file pipeline per the spec. The app now reads (and auto-creates) a JSON file on startup, parses it into an `AppConfig`, and the API client uses the loaded `backendBaseUrl` + `requestTimeout` instead of compile-time defaults.

## Files added / changed

| Path | Change |
|------|--------|
| [flutter_app/lib/core/config/app_config.dart](../../flutter_app/lib/core/config/app_config.dart) | NEW — `AppConfig` immutable model (`backendBaseUrl`, `requestTimeout`, `topicSyncInterval`, `environment`), `ConfigFileService` (path resolution + load-or-initialize + write), `configFileServiceProvider`, `appConfigProvider` (FutureProvider) |
| [flutter_app/lib/core/api/api_client.dart](../../flutter_app/lib/core/api/api_client.dart) | `apiClientProvider` now `ref.watch(appConfigProvider)`; uses `config.backendBaseUrl` for the Dio base URL and `config.requestTimeout` (seconds) for `receiveTimeout`. The `--dart-define=API_BASE_URL=…` override still wins so CI can target a non-default backend |
| [flutter_app/lib/main.dart](../../flutter_app/lib/main.dart) | Now `async`. `WidgetsFlutterBinding.ensureInitialized()` + a manually-constructed `ProviderContainer` + `await container.read(appConfigProvider.future)` happen before `runApp`. App boots with the container via `UncontrolledProviderScope` so the resolved config is read on its first lookup |

## JSON schema

The spec dictated short field names. Implementation matches verbatim:

```json
{
  "baseurl": "http://localhost:3000/api",
  "reqTout": 30,
  "tSync": 60,
  "dev": "dev"
}
```

- `baseurl` → `AppConfig.backendBaseUrl`
- `reqTout` (integer, seconds) → `AppConfig.requestTimeout`
- `tSync` (integer, seconds) → `AppConfig.topicSyncInterval`
- `dev` (`"dev"` or `"prod"`) → `AppConfig.environment`

`AppConfig.isDev` is exposed as sugar for downstream code that wants to gate verbose logging or relaxed throttle policies on the environment.

## Path resolution

| Platform | Path |
|----------|------|
| **Android** | `<storage_root>/룡마/가상외국어회화/config/app_config.json` — `storage_root` is `/storage/emulated/0` when accessible, otherwise the app-scoped external storage from `path_provider.getExternalStorageDirectory()`, otherwise `getApplicationSupportDirectory()` |
| **Windows** | `<exe_dir>/app_config.json` — same folder as the running executable, so the user can hand-edit it without admin rights |
| **Other (Linux/macOS/iOS)** | `<applicationSupport>/app_config.json` — fallback that keeps the file inside the platform's normal app data location |

Intermediate directories are created on demand. The file is read in `loadOrInitialize()`:
- If missing → write defaults → return defaults.
- If unparseable → overwrite with defaults → return defaults (never leaves the app stuck on bad JSON).
- Otherwise → parse and return.

## How startup uses it

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  try {
    await container.read(appConfigProvider.future);  // creates file if missing
  } catch (_) {
    // best-effort; ApiClient falls back to AppConfig.defaults
  }
  runApp(UncontrolledProviderScope(container: container, child: const VLearn2App()));
}
```

By the time `runApp` runs:
- The file exists on disk with sensible defaults (so users can edit it).
- `appConfigProvider` is already resolved, so `apiClientProvider`'s first read sees real values, not "loading".

## Defaults

```dart
const defaults = AppConfig(
  backendBaseUrl: 'http://localhost:3000/api',
  requestTimeout: 30,    // seconds
  topicSyncInterval: 60, // seconds
  environment: 'dev',
);
```

Match the existing hardcoded defaults — flipping the JSON file to `prod` is a single edit, no rebuild.

## Verification

| Scenario | Outcome |
|----------|---------|
| First launch with no file | File is created at the resolved path with the defaults above; app boots normally |
| Edit baseurl in the JSON, relaunch | App's API base URL changes — no need to rebuild |
| Corrupt the JSON | File gets overwritten with defaults on next launch |
| Pass `--dart-define=API_BASE_URL=...` | Overrides the JSON for that build (useful in CI) |

## Honest call-outs

1. **The user mentioned `app_config.dart` "may be useless to separate dev or prod"** — kept the `environment` field anyway because downstream code (logging, throttle ramp, throttling-tolerant retry) often needs to differentiate environments without changing what URL it points at. If the user wants to remove it later, drop one column from the JSON and one field from `AppConfig`.
2. **No live-reload of the config file.** If the user edits the JSON while the app is running, the change doesn't take effect until the next launch. A `Watch` over the file is doable (`Directory.watch` + `Stream`) but adds platform complexity (Android storage permissions, Windows ReadDirectoryChangesW). The current "edit and relaunch" loop matches what most desktop apps do.
3. **The Korean path `룡마/가상외국어회화` is literal Hangul** — works on Android (case-sensitive FAT/ext4 filesystems handle non-ASCII fine). If a future requirement needs an ASCII fallback, change the constant in `resolveConfigFile()`.
4. **Windows path is exe-relative** — when the user runs from a debug build, this is `…/build/windows/x64/runner/Debug/`. That's by spec ("same folder which windows application executable file locates"). Switching to `getApplicationSupportDirectory()` for Windows would put the file in `%APPDATA%/Roaming/<appname>/` instead — better for installed apps, worse for "drop a portable build on a USB stick". Default choice matches the spec.
5. **`topicSyncInterval` is read but not yet wired to a background sync job.** The field is present in `AppConfig` so when a topic-sync feature lands, it consumes `config.topicSyncInterval` without further changes. Today: no consumer.
6. **`requestTimeout` is wired** — fed into `Dio.BaseOptions.receiveTimeout`. `connectTimeout` is still a hardcoded 10s; happy to make that configurable too if the user wants.
