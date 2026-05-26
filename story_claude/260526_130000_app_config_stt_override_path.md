# `app_config.json` `stt` override — pre-placed sherpa models

## Goal

Let the admin pre-place sherpa-onnx model files on the device and
have the app use them directly, skipping the `.dat` unpack entirely.
Falls back to the unpack pipeline if the override path is missing or
empty.

## How to use it

Add an `"stt"` key to `app_config.json` whose value is the absolute
path to a sherpa-onnx model root (same layout as a `.dat`'s unpacked
output):

```json
{
  "baseurl": "http://…",
  "reqTout": 30,
  "tSync": 60,
  "dev": "dev",
  "stt": "/storage/emulated/0/룡마/가상외국어회화/data/sherpa-models"
}
```

Expected layout at that path:

```
<override>/
  stt/
    encoder*.onnx
    decoder*.onnx
    joiner*.onnx       (or whisper-encoder.onnx + whisper-decoder.onnx)
    tokens*.txt
  manifest.json        (OPTIONAL — see "manifest" below)
```

The admin can unpack a `.dat` once on a PC, copy the resulting
folder to the device sdcard, and point `stt` at it — done.

## Flow at runtime

`ModelRegistry.resolveModelRoot()` resolution order:

1. **Test override** (`@visibleForTesting overrideRoot`) — unchanged.
2. **`app_config.json` `stt` path** — used when the directory exists
   AND contains a usable sherpa layout (a `stt/` subdir with at
   least one `.onnx` file and a `tokens*` file). Logs:
   `[model-registry] using app_config.json stt override → <path>`
3. **Unpacked `.dat`** — the original flow (via
   `unpackedRootForGroup(paths, "speech")`).

If the `stt` path is set but missing / empty / wrong shape, it logs:
`[model-registry] stt override path "<…>" missing or has no sherpa
layout — falling back to unpacked .dat` and continues down to step 3.

## Manifest

- If `manifest.json` sits next to `stt/`, it's loaded normally and
  full SHA-256 verification runs (same code path as a `.dat`-unpacked
  root).
- If there's no `manifest.json`, the registry **synthesizes one** by
  walking the directory. The synthesized manifest carries every
  on-disk file as a `ModelFile` entry (with size, no hash), and a new
  `synthesized: true` flag.
- `verifyAll` skips the SHA-256 check on synthesized manifests —
  presence + non-zero size is the only verification we have for
  admin-placed files.

The STT service (`SherpaOnnxSttService.initialize`) is **unchanged** —
it still looks up files via `_resolveListedFile(manifest, prefix)`,
which now matches against either a real manifest or a synthesized one.

## Files changed

- `flutter_app/lib/core/config/app_config.dart` — `AppConfig` gains
  `String? sttModelPath` (JSON key `"stt"`). Written only when set
  (keeps the file compact when no override is in play). Trim+empty
  → null on read.
- `flutter_app/lib/core/storage/model_registry.dart` —
  - `ModelRegistry` ctor: new `sttOverridePath` arg.
  - `resolveModelRoot`: 3-tier order, `_resolvedFromOverride` flag.
  - `_hasSherpaLayout`: cheap directory probe.
  - `loadManifest`: falls back to `_synthesizeManifest` when the
    override is in use and no `manifest.json` exists.
  - `ModelManifest`: new `synthesized` flag.
  - `verifyAll`: skip hash check on synthesized manifests.
  - `modelRegistryProvider`: now `ref.watch(appConfigProvider)` and
    passes `cfg?.sttModelPath` through.

## Backwards compatibility

- Existing `app_config.json` files without `"stt"` → `sttModelPath`
  is null → behaviour identical to before (unpack from `.dat`).
- Existing `manifest.json`-based unpacked roots → unchanged path.
- Existing tests: `overrideRoot` arg still wins over the new
  `sttOverridePath` arg, so test fixtures don't need to change.

## Verification

```text
flutter analyze lib/core/storage/ lib/core/config/  → No issues found
flutter test test/datapack/                          → 7/7 pass
```

## User prompt (verbatim)

> I want add option to app_config.json for sherpa model files. key
> name can be "stt" in app_config.json
> So On the conversation screen, first check the sdcard path
> specified on the app_config.json and detect model files and init
> with it.
> If the specified path is not for sherpa model files then unpack
> the files and point to it.
