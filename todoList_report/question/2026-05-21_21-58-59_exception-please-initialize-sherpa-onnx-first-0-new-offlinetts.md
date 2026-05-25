# │ Exception: Please initialize sherpa-onnx first ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-21T12:58:59.711Z

## User

│ Exception: Please initialize sherpa-onnx first
├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
│ #0   new OfflineTts (package:sherpa_onnx/src/tts.dart:633:7)
│ #1   SherpaOnnxTtsService.initialize (package:flutter_app/core/speech/sherpa_onnx_tts.dart:102:20)
│ #2   <asynchronous suspension>
│ #3   SherpaOnnxTtsService.speak (package:flutter_app/core/speech/sherpa_onnx_tts.dart:156:24)
│ #4   <asynchronous suspension>
├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
│ :no_entry: TTS: native init failed

## Assistant

The error comes from sherpa_onnx's own guard — the package requires `sherpa_onnx.initBindings()` to be called once before any native object (OfflineTts, OnlineRecognizer, etc.) is constructed. Your code never calls it. Let me find a good place to add it.

## Assistant

The fix: add `sherpa_onnx.initBindings()` once at app startup before any service tries to construct `OfflineTts`/`OnlineRecognizer`. I'll add it in [main.dart](flutter_app/lib/main.dart).

## Assistant

That's expected — I haven't added the call yet. Let me add it now.

## Assistant

Now let me commit this fix per your auto-commit preference.

## Assistant

Fixed. The root cause: `sherpa_onnx` package (^1.10.46) guards every native constructor with a "bindings initialized?" check, and `initBindings()` was never called.

**Change:** [flutter_app/lib/main.dart](flutter_app/lib/main.dart) — call `sherpa_onnx.initBindings()` once at startup right after `WidgetsFlutterBinding.ensureInitialized()`. Both STT and TTS now share the same FFI setup, so the first `speak()` no longer crashes.

Rebuild and try TTS again:
```powershell
flutter run
```
