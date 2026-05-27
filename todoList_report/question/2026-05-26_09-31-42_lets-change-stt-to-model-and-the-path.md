# Let's change "stt" to "model" and the path specified by "model" in app_config.js

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-26T00:31:42.114Z

## User

Let's change "stt" to "model" and the path specified by "model" in app_config.json include stt,tts,vad folders, manifest.json file and each folder has necessary files in it.

## Assistant

Verifying real state and continuing with `model_registry.dart`:

## Assistant

Clean + all tests pass. Committing:

## Assistant

Done — committed as `11d8ff7`.

## What changed

The JSON key `"stt"` is now **`"model"`** — the override path represents the whole on-device speech model root, not just STT.

```json
{
  "baseurl": "http://…",
  "reqTout": 30,
  "tSync": 60,
  "dev": "dev",
  "model": "/storage/emulated/0/룡마/가상외국어회화/data/models"
}
```

Expected layout at that path:

```
<modelPath>/
  manifest.json
  stt/   encoder*.onnx  decoder*.onnx  joiner*.onnx  tokens.*
  tts/   …
  vad/   …
```

Internal renames: `AppConfig.sttModelPath` → `modelPath`, `ModelRegistry(sttOverridePath:)` → `modelOverridePath`, `_sttOverridePath` → `_modelOverridePath`. The fallback log now spells out the expected layout so the admin sees exactly what's missing.

The "usable layout" gate (`_hasSherpaLayout`) still requires only `stt/` with `.onnx` + `tokens*` — `tts/` and `vad/` aren't strictly required by the gate (the synthesized manifest just lists whatever's on disk; each service tolerates missing files). If you'd rather have it strictly require all three, say the word.

**Note:** an old `app_config.json` with `"stt": …` is no longer recognised — admins should rename their key to `"model"`. `flutter analyze` clean, 7/7 datapack tests pass.
