# I want add option to app_config.json for sherpa model files.  key name can be "s

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-26T00:22:24.434Z

## User

I want add option to app_config.json for sherpa model files.  key name can be "stt" in app_config.json
So On the conversation screen, first check the sdcard path specified on the app_config.json and detect model files and init with it.
If the specified path is not for sherpa model files then unpack the files and point to it.

## Assistant

Let me look at the relevant code — the app config, the STT init, and the model registry — to design this cleanly.

## Assistant

Plan:

1. Add an optional `stt` field to `app_config.json` (key = `"stt"`, value = absolute sdcard path).
2. `ModelRegistry` checks that path first. If it contains a sherpa-onnx layout (`stt/` subdir with `.onnx` files + a `tokens` file), use it directly and **synthesize a manifest** from the on-disk files — no unpack, no hash verification.
3. If the path is missing / empty / doesn't have the layout → fall through to the existing unpack-from-`.dat` flow unchanged.

The override path is the **model root** — same shape as a `.dat`'s unpacked output (the admin's `out_folder`). Admin can just unpack a `.dat` once on PC, copy the result to the sdcard, point `stt` at it.

## Assistant

The diagnostic is stale — the field was added by a later edit. Let me verify and then move on to `model_registry.dart`:

## Assistant

Clean. Now the `model_registry.dart` changes — override path + synthesized manifest:

## Assistant

Clean + tests pass. Committing:

## Assistant

Committed as `8adf61e`.

## How to use it

Add an `"stt"` key to `app_config.json` with the absolute path to a sherpa-onnx model root:

```json
{
  "baseurl": "http://…",
  "reqTout": 30,
  "tSync": 60,
  "dev": "dev",
  "stt": "/storage/emulated/0/룡마/가상외국어회화/data/sherpa-models"
}
```

Expected layout at that path (same as a `.dat`'s unpacked output):

```
<override>/
  stt/
    encoder*.onnx
    decoder*.onnx
    joiner*.onnx          (or whisper-encoder + whisper-decoder)
    tokens*.txt
  manifest.json           ← OPTIONAL
```

Unpack a `.dat` once on a PC, copy that folder to the sdcard, point `stt` at it — done. No runtime unpack.

## Resolution order ([model_registry.dart](flutter_app/lib/core/storage/model_registry.dart))

`resolveModelRoot()` now tries:

1. Test `overrideRoot` (unchanged).
2. **`app_config.json` `stt` path** — used when the dir exists *and* has a `stt/` subdir with at least one `.onnx` file + a `tokens*` file. Logs `[model-registry] using app_config.json stt override → <path>`.
3. **Unpacked `.dat`** — the original flow.

If `stt` is set but missing / empty / wrong shape, it logs `… missing or has no sherpa layout — falling back to unpacked .dat` and continues down to step 3 — your existing pipeline is untouched.

## Manifest handling

- If `manifest.json` sits next to `stt/`, full SHA-256 verification runs as before.
- If no `manifest.json`, the registry **synthesizes one** by scanning the directory (with a new `synthesized: true` flag). `verifyAll` skips the hash check for synthesized manifests — presence + non-zero size is the only verification we have for admin-placed files.

## Backwards compatibility

- Existing `app_config.json` without `"stt"` → null → behaviour identical to before.
- `SherpaOnnxSttService` is **unchanged** — it still calls `_resolveListedFile(manifest, prefix)`, which works against either a real or synthesized manifest.
- Existing tests still pass (`overrideRoot` arg keeps priority).

`flutter analyze` clean, 7/7 datapack tests pass.
