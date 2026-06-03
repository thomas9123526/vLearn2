# can you check if the tts voice is changed according to the tutor who is selected

Session: `cb14393c-1d33-4891-aee0-276d4c902efe`
Saved: 2026-06-03T01:46:59.221Z

## User

can you check if the tts voice is changed according to the tutor who is selected on setting tab of the application.  I think tts voice is same no matter i switch another tutor on the settings screen.
I asked  you about this before. if the tutor is man, man's voice should be in tts. if the tutor gender is woman then woman voice should be in tts.
Currently I only heard woman like voice.

## Assistant

Let me find the TTS and tutor-related code.

## Assistant

Good findings. Let me check the actual tutor data and the `_pickVoice` method to find the bug.

## Assistant

Found the root cause. The TTS manifest only has **one voice**:

```json
"voices": ["en_US-amy"]
```

`en_US-amy` is a female voice. No matter which tutor gender is selected, `_pickVoice()` tries to match male hints (`alan`, `james`, `john`, etc.) against the available voices list — none match — so it always falls back to the first voice: **`en_US-amy`**.

The logic is correct, but you only have one (female) voice model installed. You need to add a male Piper voice. Let me check the model folder structure:

## Assistant

Now I have the complete picture. Here's what's happening:

**Root cause:** The manifest only has **one voice** — `en_US-amy` (female). When a male tutor is selected, `_pickVoice()` searches for male names like `alan`, `james`, `ryan` in the available voices list, finds nothing, and falls back to `voices.first` = `en_US-amy`. You always hear a female voice.

**The code is correct — the model bundle is missing a male voice.**

The `sid` (speaker ID) passed to the engine is just the voice's index in the manifest list. So to add a male voice you need to:

1. Download a male Piper voice model (e.g. `en_US-ryan`) — a `.onnx` + `.onnx.json` file
2. Put it in `models/tts/` on the device
3. Rebuild the manifest with both voices listed

But first — what does your current `models/tts/` look like on the device? Is the existing model a **single-speaker** (Amy only) or a **multi-speaker** model?

Run this to check:

```powershell
adb shell ls /storage/emulated/0/Android/data/com.ryongma.vfls/files/models/tts/
```

This tells us whether we need to download a new model file or just update the manifest.
