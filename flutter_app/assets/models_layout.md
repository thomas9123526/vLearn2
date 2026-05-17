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
│   ├── encoder.onnx               (streaming: zipformer transducer)
│   ├── decoder.onnx
│   ├── joiner.onnx
│   ├── tokens.txt
│   │                              ──── OR ────
│   ├── whisper-encoder.onnx       (fallback: whisper-tiny multilingual)
│   ├── whisper-decoder.onnx
│   └── tokens.txt
├── tts/
│   ├── model.onnx                 (VITS Piper voice)
│   ├── tokens.txt
│   └── espeak-ng-data/            (Piper requires the espeak-ng data dir)
│       └── ...
├── vad/
│   └── silero.onnx                (optional, for end-of-utterance detection)
└── cache/                         (created at runtime — leave empty)
    └── tts/
```

The app picks the **streaming** STT bundle if `stt/encoder*`, `stt/decoder*`, `stt/joiner*`, and `stt/tokens*` are all present. Otherwise it falls back to the **Whisper** bundle (`stt/whisper-encoder*` + `stt/whisper-decoder*` + tokens).

## manifest.json shape

```json
{
  "version": "2026.05.18-1",
  "stt":   { "name": "zipformer-streaming-en" },
  "tts":   { "name": "vits-piper-en", "voices": ["en_US-amy", "en_GB-jenny"] },
  "vad":   { "name": "silero-v4" },
  "files": [
    { "path": "stt/encoder.onnx",      "sha256": "...", "size": 12345678 },
    { "path": "stt/decoder.onnx",      "sha256": "...", "size":    98765 },
    { "path": "stt/joiner.onnx",       "sha256": "...", "size":   456789 },
    { "path": "stt/tokens.txt",        "sha256": "...", "size":     2048 },
    { "path": "tts/model.onnx",        "sha256": "...", "size": 30000000 },
    { "path": "tts/tokens.txt",        "sha256": "...", "size":     4096 },
    { "path": "tts/espeak-ng-data/phontab", "sha256": "...", "size": 8192 },
    { "path": "vad/silero.onnx",       "sha256": "...", "size":   456789 }
  ]
}
```

- **`version`** — free-form. Surface it in your release notes; the app doesn't enforce it.
- **`stt.name` / `tts.name`** — informational; shown on the setup screen so admins can confirm which bundle is loaded.
- **`tts.voices`** — list in the order the model expects (`sid=0` is index 0). The UI maps personas → voices by index.
- **`files`** — every file the app should hash-check at boot. Files not listed are ignored (e.g. the `cache/` directory).

## Building `manifest.json`

The repo ships a helper at [`tools/build-manifest.py`](../../tools/build-manifest.py). It walks the model folder, SHA-256s every file, and writes a `manifest.json` next to the files.

```
python tools/build-manifest.py --root /path/to/models > /path/to/models/manifest.json
```

The app verifies every entry on first launch (and on **Re-verify all** in Settings → Storage). Hash mismatches surface as ⚠️ rows on the Speech-setup screen.

## Why hashes?

So a partial copy (network blip, ADB push interrupted, MDM rollout that died mid-flight) doesn't silently produce a corrupted model the user can't escape from. The app shows the **exact missing/mismatched file** in the setup screen and refuses to load the native recognizer until the bundle is clean.

## The "ready" path

1. App boots → `ModelRegistry.snapshot()` resolves the model root, reads manifest, verifies every file.
2. Status is one of: `ready` / `corrupt` / `manifestMissing` / `notReady`.
3. `ready` → `sttServiceProvider` and `ttsServiceProvider` return the sherpa-backed services.
4. Otherwise → providers return placeholder no-op services; the conversation screen falls back to keyboard input only, and the router redirects users who try to start a conversation to **Speech setup**.

The user can always opt into **Text-only mode** from the "Speech setup" screen and use the app without speech.
