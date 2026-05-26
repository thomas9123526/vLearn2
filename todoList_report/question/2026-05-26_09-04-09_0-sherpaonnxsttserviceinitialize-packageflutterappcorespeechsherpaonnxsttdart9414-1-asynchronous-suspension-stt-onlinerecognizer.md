# #0   SherpaOnnxSttService.initialize (package:flutter_app/core/speech/sherpa_onn

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-26T00:04:09.859Z

## User

#0   SherpaOnnxSttService.initialize (package:flutter_app/core/speech/sherpa_onnx_stt.dart:94:14)
 #1   <asynchronous suspension>
┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
 💡 STT: OnlineRecognizer ready (streaming).

hi, does this mean , stt working?

## Assistant

**Yes — STT is working.**

That stack trace isn't an error. Line 94 is just an info log:

```dart
_available = true;
_log.i('STT: OnlineRecognizer ready (streaming).');   // ← line 94
return;
```

The lines above ([sherpa_onnx_stt.dart:80-95](flutter_app/lib/core/speech/sherpa_onnx_stt.dart#L80-L95)) successfully constructed `so.OnlineRecognizer` from the encoder/decoder/joiner/tokens, set `_available = true`, and then logged "ready" with a stack snippet so you can see where the message came from (some loggers attach a stack to every `.i()` call). The `<asynchronous suspension>` frames are normal — they just show the async `initialize()` chain that led there.

What it means end-to-end:
- The `.dat` unpacked successfully → models are on disk.
- `ModelRegistry` resolved the speech model root → files were found.
- sherpa-onnx loaded the transducer model files (encoder + decoder + joiner + tokens) → no native error.
- `OnlineRecognizer` is alive → streaming STT is ready to use.

Go ahead and try a conversation — the mic input should now flow through this recognizer.
