# android app get model path from app_config.json from this line. "model": "/stora

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-27T09:59:47.997Z

## User

android app get model path from app_config.json from this line.
"model": "/storage/emulated/0/룡마/가상외국어회화/data/sherpa_2023"

I want put value for "model" the relative path inside 가상외국어회화 , so it will be like "data/sherpa_2023".
Because 룡마/가상외국어회화 can be inside external storage or inside tcard or inside other media like otg.
The android app already checks the path for 룡마/가상외국어회화 through all types of storages

## Assistant

Let me look at the config file and how the Android app reads the model path.

## Assistant

Now let me read the key files to understand exactly what needs to change.

## Assistant

The fix is straightforward: when `model` is a relative path, resolve it against the directory where `app_config.json` was found (which is already the detected `룡마/가상외국어회화` base). I need to change two things:

1. `AppConfig.fromJson()` — accept the config dir, resolve relative paths
2. `ConfigFileService.loadOrInitialize()` — pass `file.parent.path` as the base
3. Update `app_config_vfls.json`

## Assistant

Now update `loadOrInitialize()` to pass the config file's parent directory:

## Assistant

Now update the doc comment on `modelPath` and update `app_config_vfls.json`:

## Assistant

Now update the template config file:

## Assistant

Now commit:

## Assistant

Done. Here's what changed:

**[app_config.dart](flutter_app/lib/core/config/app_config.dart)**
- `AppConfig.fromJson()` now takes an optional `configDir` parameter. If `model` is a relative path and `configDir` is provided, it calls `p.join(configDir, model)` to produce an absolute path. Absolute paths pass through unchanged.
- `loadOrInitialize()` passes `file.parent.path` (the `룡마/가상외국어회화` directory, wherever it was found) as `configDir`.

**[app_config_vfls.json](flutter_app/app_config_vfls.json)**
- Changed `"model"` from `"E:/Upload_HKC/sherpa_2023"` to `"data/sherpa_2023"`.

So `"data/sherpa_2023"` will resolve to `<whatever storage>/룡마/가상외국어회화/data/sherpa_2023` automatically — no changes needed to the storage scanning logic.
