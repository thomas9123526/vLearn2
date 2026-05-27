# sherpa-onnx "Please initialize sherpa-onnx first" crash

## User report

```
│ Exception: Please initialize sherpa-onnx first
├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
│ #0   new OfflineTts (package:sherpa_onnx/src/tts.dart:633:7)
│ #1   SherpaOnnxTtsService.initialize (package:flutter_app/core/speech/sherpa_onnx_tts.dart:102:20)
│ #2   <asynchronous suspension>
│ #3   SherpaOnnxTtsService.speak (package:flutter_app/core/speech/sherpa_onnx_tts.dart:156:24)
│ #4   <asynchronous suspension>
├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
│ :no_entry: TTS: native init failed
```

## Diagnosis

`sherpa_onnx` (^1.10.46) guards every native constructor with a check that
its FFI bindings have already been wired up. The package exposes
`initBindings()` for exactly that — but our code never called it.

The first `SherpaOnnxTtsService.speak()` ran `initialize()`, which then
tried `new so.OfflineTts(...)` and tripped the package's own guard,
producing the message above. Same trap is sitting on the STT side — we
just hadn't hit it yet because TTS fires first in our flow.

## Fix

Add a single call to `sherpa_onnx.initBindings()` in `main.dart`, right
after `WidgetsFlutterBinding.ensureInitialized()` and before any service
gets a chance to spin up. Both STT and TTS benefit; the FFI bindings only
need to be set up once per process.

## Files touched

- `flutter_app/lib/main.dart` — import `sherpa_onnx` and call
  `initBindings()` at the top of `main()`.
