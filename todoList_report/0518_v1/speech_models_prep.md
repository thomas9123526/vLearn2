# Speech models — what to prepare to make STT/TTS work

The app is "Mode B" by design: it **never downloads** model files. An admin (you) drops the bundle onto the device once, the app verifies SHA-256 hashes against a `manifest.json`, and from then on the conversation screen has speech.

The "No manifest.json was found in the expected folder" error means the registry resolved the folder fine but didn't find any models in it.

## TL;DR — the minimum bundle

You need these files in one directory on the device:

```
models/
├── manifest.json
├── stt/
│   ├── encoder.onnx
│   ├── decoder.onnx
│   ├── joiner.onnx
│   └── tokens.txt
├── tts/
│   ├── model.onnx
│   ├── tokens.txt
│   └── espeak-ng-data/
│       └── ...               (whole directory; Piper requires it)
└── vad/
    └── silero.onnx           (optional — improves end-of-utterance detection)
```

Then run the manifest builder, copy everything to the device, and the app picks it up.

## Step 1 — Where the folder is

Path resolution is per-platform. Open the app once, navigate to **Settings → Storage → Model folder** to see the literal path. The setup screen ("Speech setup") also shows it under "Expected location".

| Platform | Path |
|----------|------|
| Android  | `/storage/emulated/0/룡마/가상외국어회화/models/` (or app-scoped external storage as fallback) |
| Windows  | `%APPDATA%\VLearn2\models\` (literally `C:\Users\<you>\AppData\Roaming\VLearn2\models`) |

For Android you might need to use ADB or a file-manager app (Files by Google works) — the app's own `getExternalStorageDirectory()` path is in the public-ish `/sdcard/Android/data/...` zone, not the system root.

## Step 2 — Download the models

The reference model bundles are at [github.com/k2-fsa/sherpa-onnx/releases](https://github.com/k2-fsa/sherpa-onnx/releases). Pick one STT + one TTS + (optional) one VAD.

### STT — speech-to-text

**Recommended for English: streaming Zipformer transducer.**

Download one of these from sherpa-onnx releases:

- `sherpa-onnx-streaming-zipformer-en-2023-06-26.tar.bz2` (~80 MB, English-only, low-latency)
- `sherpa-onnx-whisper-tiny.tar.bz2` (~75 MB, multilingual, slightly higher latency)

Both contain `encoder.onnx`, `decoder.onnx`, `tokens.txt`. Zipformer adds `joiner.onnx`. Unpack into `models/stt/`.

The app's [model_registry.dart](../../flutter_app/lib/core/storage/model_registry.dart) doesn't care which one — it just verifies what's in the manifest matches what's on disk.

### TTS — text-to-speech

**Recommended for English: VITS Piper (small, natural-sounding voice).**

From sherpa-onnx releases, grab a Piper bundle, e.g.:

- `vits-piper-en_US-amy-low.tar.bz2` (~20 MB)
- `vits-piper-en_US-libritts_r-medium.tar.bz2` (~80 MB, multi-speaker)

Each contains:
- `model.onnx` — the voice
- `tokens.txt` — phoneme vocab
- `espeak-ng-data/` — the espeak-ng data dir Piper needs for text-to-phoneme conversion

Unpack into `models/tts/`.

### VAD — voice activity detection (optional)

`silero_vad.onnx` (~1 MB) from [github.com/snakers4/silero-vad](https://github.com/snakers4/silero-vad). Drop into `models/vad/`. Improves end-of-utterance detection — the app still works without it.

## Step 3 — Build the `manifest.json`

The repo ships [tools/build-manifest.py](../../tools/build-manifest.py). After you have all files in place under one directory:

```bash
python tools/build-manifest.py --root /path/to/models
```

This walks the directory, computes SHA-256 for every file, and writes `manifest.json` next to them. Optional flags:

```
--tts-voices en_US-amy en_GB-jenny   # in the order Piper expects (sid 0 first)
--stt-name zipformer-streaming-en    # informational, shown on the setup screen
--tts-name vits-piper-en
--vad-name silero-v4
```

A minimal manifest looks like this:

```json
{
  "version": "2026.05.18-1",
  "stt":   { "name": "zipformer-streaming-en" },
  "tts":   { "name": "vits-piper-en", "voices": ["en_US-amy"] },
  "vad":   { "name": "silero-v4" },
  "files": [
    { "path": "stt/encoder.onnx", "sha256": "...", "size": 12345678 },
    { "path": "stt/decoder.onnx", "sha256": "...", "size": 98765 },
    ...
  ]
}
```

## Step 4 — Get the files onto the device

### Android

Use ADB or a file-manager. ADB is the most reliable:

```bash
adb push models/ /sdcard/룡마/가상외국어회화/
# or, app-scoped:
adb push models/ /sdcard/Android/data/<package_name>/files/models/
```

The package name is `com.vlearn2.flutter_app` based on the current Android config.

If `/sdcard/` rejects the Korean folder name due to your shell encoding, run `adb shell` first and `mkdir` the path interactively, then `adb push` into it.

### Windows

Easiest: open Explorer, paste `%APPDATA%\VLearn2\` into the address bar, create a `models` folder if it doesn't exist, and copy the files in. The resolved path is hardcoded by [model_registry.dart](../../flutter_app/lib/core/storage/model_registry.dart) on Windows — it doesn't depend on Flutter's `package_info_plus` lookup, so this path is stable.

The Settings → Storage → Model folder tile shows the exact path the app is using; if Explorer reports a different path, that one wins.

## Step 5 — Verify

Open the app:

1. Restart it (or navigate to **Settings → Storage**).
2. Tap **Re-verify all**. The status switches from `manifest.json not found` → `<N>/<N> files verified`.
3. Tap into a scenario — conversation screen should now boot in Tutor mode without the "Speech models not installed" message.

If you see ⚠️ rows on the setup screen for individual files, the SHA-256 doesn't match the manifest. Either re-copy the file (partial copy is the usual cause) or re-run `python tools/build-manifest.py --root /path/to/models` if you've replaced files since generating the manifest.

## Common gotchas

| Symptom | Cause | Fix |
|---------|-------|-----|
| "manifest.json not found" | The folder is empty or has the wrong name | Verify exact path from Settings → Storage |
| "Bundle corrupted (N/M ok)" | At least one SHA-256 mismatch | Re-copy the flagged files; rebuild manifest if you changed any |
| "Files: X.onnx — Not found" | Manifest lists a file you didn't copy | Either copy the missing file or regenerate the manifest with `--root` pointing at the actual files |
| App still doesn't get speech after verify says "ok" | The `sherpa_onnx` package may not be installed yet | Check `flutter_app/pubspec.yaml` — the `sherpa_onnx` line is commented out by default per [todoList_report/0517_v2/01_stt_tts_sherpa_onnx.md](../0517_v2/01_stt_tts_sherpa_onnx.md). Uncomment it, `flutter pub get`, rebuild |
| Korean path fails on Android | Older Android filesystem encoding | Use the app-scoped fallback path (`/sdcard/Android/data/...`) shown in Settings → Storage |
| TTS plays but voice is wrong | `tts.voices[]` order in manifest doesn't match what Piper exposes | Reorder the array — sid 0 is the index-0 voice |

## What's required vs optional

| Component | Required? | Bundle size | Notes |
|-----------|-----------|-------------|-------|
| `manifest.json` | yes | <1 KB | Must list every file you want hash-checked |
| STT (encoder + decoder + tokens) | yes for STT | 30–80 MB | Without this, the mic button doesn't appear |
| Zipformer `joiner.onnx` | yes if using zipformer | ~5 MB | Whisper doesn't need it |
| TTS (model + tokens + espeak-ng-data) | yes for TTS | 20–80 MB | Without this, the tutor doesn't speak; chat text still works |
| VAD `silero.onnx` | optional | 1 MB | Improves end-of-utterance detection |

Minimum useful bundle: ~50 MB (zipformer + small Piper voice). Comfortable: ~120 MB (whisper-base + medium Piper + Silero VAD).

## A word on the `sherpa_onnx` Flutter package

The wiring in [flutter_app/lib/core/speech/sherpa_onnx_stt.dart](../../flutter_app/lib/core/speech/sherpa_onnx_stt.dart) and [sherpa_onnx_tts.dart](../../flutter_app/lib/core/speech/sherpa_onnx_tts.dart) is in place but the `sherpa_onnx: ^1.10.0` dep in `pubspec.yaml` is **commented out by default** to let the app build without the native plugin while everything else stabilises. Once your models are on the device:

1. Open `flutter_app/pubspec.yaml`
2. Uncomment the line that reads `# sherpa_onnx: ^1.10.0` (and `# permission_handler: ^11.3.1`)
3. `flutter pub get` (on the same machine — the native plugin downloads its prebuilt libraries)
4. `flutter clean && flutter run -d windows` or `flutter run -d <android device>`

The conversation screen lights up STT/TTS on the next launch. The Settings → Storage tile already shows the bundle as `ready`.

## tl;dr

1. Open Settings → Storage in the app, note the **Model folder** path.
2. Download an STT + TTS bundle from [sherpa-onnx releases](https://github.com/k2-fsa/sherpa-onnx/releases).
3. Unpack into the model folder (per the tree at the top).
4. `python tools/build-manifest.py --root <that folder>` → writes `manifest.json`.
5. Open Settings → Storage → **Re-verify all** in the app.
6. Uncomment `sherpa_onnx:` in `pubspec.yaml`, `flutter pub get`, rebuild.

That's it. The conversation screen will stop showing the "not installed" message.
