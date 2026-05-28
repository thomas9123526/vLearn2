# I think the stt on android is not working, not sure if the emulator is slow so i

Session: `5720bd49-f606-4621-9507-92b65f44e5e5`
Saved: 2026-05-28T16:59:45.539Z

## User

I think the stt on android is not working, not sure if the emulator is slow so i didn't notice or is not work any more

## Assistant

Let me look at the STT implementation in the Flutter app.

## Assistant

Let me read the actual implementation files to spot what might be broken.

## Assistant

Let me check the `speechReadyProvider` and model registry to understand why STT might report not ready.

## Assistant

Let me check recent git changes on this branch that could have affected STT.

## Assistant

Let me check the recent question logs that describe the STT issue.

## Assistant

Let me check what specifically changed on speech files in this branch vs master.

## Assistant

I found two issues:

1. **Double verification**: When you tap the mic, `SherpaOnnxSttService.initialize()` runs `registry.snapshot()` — which re-reads and re-hashes all model files — even though `modelRegistrySnapshotProvider` already did this at startup. On a slow emulator this is very painful.

2. **On x86 LDPlayer, ONNX inference itself is slow** (software x86 vs native ARM) — this causes the "Thinking..." period to feel frozen.

The first issue is fixable: cache the snapshot in `ModelRegistry` so the second call returns instantly. Let me also add a timeout to the transcription so it doesn't silently hang forever.

## Assistant

Now wire up the cache in the `snapshot()` method.

## Assistant

Now add a timeout to the STT transcription so a slow emulator gives the user visible feedback instead of hanging silently:

## Assistant

Two fixes committed:

**1. Snapshot cache** ([model_registry.dart](flutter_app/lib/core/storage/model_registry.dart#L107-L113)) — the first `snapshot()` call (at app startup via `modelRegistrySnapshotProvider`) now caches its result. When `SherpaOnnxSttService.initialize()` calls `registry.snapshot()` a second time on the first mic tap, it returns immediately instead of re-hashing all the ONNX files again.

**2. 60-second timeout** ([sherpa_onnx_stt.dart](flutter_app/lib/core/speech/sherpa_onnx_stt.dart#L181-L196)) — if inference runs longer than 60s (possible on LDPlayer's x86 software emulation), the user now gets a clear snackbar ("Speech recognition timed out") instead of the UI freezing on "Thinking…" forever.

To confirm which situation you're actually hitting, check Logcat filtered to `flutter` after tapping mic and stopping — look for:
- `[stt] mic.stop → N bytes pcm captured` — confirms the mic is capturing (if N is very small or 0, the mic isn't working in LDPlayer)
- `[stt] engine.transcribe peak=X.XXX` — if peak < 0.01, the mic captured silence
- `STT: model registry not ready` — if this appears, the model path in the device's `app_config.json` isn't resolving
