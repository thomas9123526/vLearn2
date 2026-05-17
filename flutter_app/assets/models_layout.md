# sherpa-onnx model bundle layout

The app reads its STT / TTS / VAD models from an admin-pre-placed folder. See [todoList/0517_v2/01_stt_tts_sherpa_onnx.md](../../todoList/0517_v2/01_stt_tts_sherpa_onnx.md) for the full plan.

## Where to drop the files

| Platform | Path |
|----------|------|
| Android  | `/sdcard/Android/data/<package>/files/models/` (resolved by `getExternalStorageDirectory()`) |
| Windows  | `%APPDATA%\<app>\models\` (resolved by `getApplicationSupportDirectory()`) |

The actual resolved path is shown in the app under **Settings → Storage → Model folder** and on the "Speech setup" screen.

## Expected tree

```
models/
├── manifest.json
├── stt/
│   ├── encoder.onnx
│   ├── decoder.onnx
│   └── tokens.txt
├── tts/
│   ├── vits.onnx
│   ├── tokens.txt
│   └── voices/                  (optional per-speaker assets)
└── vad/
    └── silero.onnx
```

## Building `manifest.json`

The repo ships a helper at [`tools/build-manifest.py`](../../tools/build-manifest.py). It walks the model folder, SHA-256s every file, and writes a `manifest.json` next to the files.

```
python tools/build-manifest.py /path/to/models
```

The app verifies every entry on first launch (and on **Re-verify all** in Settings → Storage). Hash mismatches surface as ⚠️ rows on the Speech-setup screen.

## Why hashes?

So a partial copy (network blip, ADB push interrupted, MDM rollout that died mid-flight) doesn't silently produce a corrupted model the user can't escape from. The app shows the **exact missing/mismatched file** in the setup screen and refuses to load the native recognizer until the bundle is clean.

## The "ready" path

1. App boots → `ModelRegistry.snapshot()` resolves the model root, reads manifest, verifies every file
2. Status is one of: `ready` / `corrupt` / `manifestMissing` / `notReady`
3. `ready` → `sttServiceProvider` and `ttsServiceProvider` return the sherpa-backed services
4. Otherwise → providers return placeholder no-op services; the conversation screen falls back to keyboard input only

The user can always opt into **Text-only mode** from the "Speech setup" screen and use the app without speech.
