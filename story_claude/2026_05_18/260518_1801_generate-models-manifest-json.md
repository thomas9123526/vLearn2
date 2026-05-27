# Generate manifest.json for local models bundle

## What this task did

Ran `python tools/build-manifest.py --root C:\project\vLearn2\models` to create [models/manifest.json](../models/manifest.json) covering **362 files** (stt Zipformer transducer, tts Piper + espeak-ng-data, vad silero).

## Conversation summary

- **User** placed sherpa-onnx models under `C:\project\vLearn2\models` and asked to generate `manifest.json`.
- **Assistant** verified folder layout (`stt/`, `tts/`, `vad/`) and ran the repo manifest builder.

## Next step for user

Copy the entire `models/` folder (including `manifest.json`) to the Android path shown in Settings → Storage, then **Re-verify all**.

```powershell
adb push "C:\project\vLearn2\models\." /storage/emulated/0/Android/data/com.ryongma.vfls/files/models/
```

## User prompt (verbatim)

> I put models to C:\project\vLearn2\models folder.
> make me manifest.json
