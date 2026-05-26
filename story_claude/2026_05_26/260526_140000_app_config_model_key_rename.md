# Rename `app_config.json` key `stt` → `model`

## What changed

The override path that lets the admin skip the `.dat` unpack is now
about the whole on-device speech model set, not just STT. Renamed
the JSON key and surrounding code accordingly.

| was               | now                |
|-------------------|--------------------|
| `app_config.json` key `"stt"` | `"model"`          |
| `AppConfig.sttModelPath`      | `AppConfig.modelPath` |
| `ModelRegistry(sttOverridePath:)` | `ModelRegistry(modelOverridePath:)` |
| internal `_sttOverridePath`   | `_modelOverridePath` |

## Expected layout at the override path

The directory pointed to by `"model"` is the on-device model **root**
and should contain the same shape a `.dat` unpacks to:

```
<modelPath>/
  manifest.json
  stt/   encoder*.onnx  decoder*.onnx  joiner*.onnx  tokens.*
  tts/   …
  vad/   …
```

Example `app_config.json`:

```json
{
  "baseurl": "http://…",
  "reqTout": 30,
  "tSync": 60,
  "dev": "dev",
  "model": "/storage/emulated/0/룡마/가상외국어회화/data/models"
}
```

## Acceptance check is unchanged

`ModelRegistry._hasSherpaLayout` still treats the override as
"usable" once it sees a `stt/` subdir with at least one `.onnx` file
and a `tokens*` file. TTS/VAD subfolders aren't strictly required by
this gate — they're listed in the synthesized manifest if present so
their services find them, and absent if not (matching the existing
`SherpaOnnxSttService` shape where missing prefixes are tolerated).
The fallback log was updated to spell out the expected layout:

```
[model-registry] model override path "<…>" missing or has no
expected layout (needs stt/ with .onnx + tokens, plus tts/ and vad/)
— falling back to unpacked .dat
```

## Backwards compatibility

A previous `app_config.json` with `"stt": …` is **no longer
recognised** — that's the rename. Devices that had it set will fall
through to the unpacked-`.dat` flow (same as if no override were
set). Admins should update their config files: `"stt"` → `"model"`.

## Verification

```text
flutter analyze lib/core/storage/ lib/core/config/  → No issues found
flutter test test/datapack/                          → 7/7 pass
```

## User prompt (verbatim)

> Let's change "stt" to "model" and the path specified by "model"
> in app_config.json include stt,tts,vad folders, manifest.json file
> and each folder has necessary files in it.
