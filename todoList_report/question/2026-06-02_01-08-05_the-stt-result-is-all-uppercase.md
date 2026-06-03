# The stt result is all uppercase

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-01T16:08:05.693Z

## User

The stt result is all uppercase

## Assistant

Let me find where the STT result is produced and processed.

## Assistant

The model's token vocabulary is uppercase (common in RNN-T/transducer models) — it returns text like "HELLO HOW ARE YOU". The fix is to lowercase the result at the output layer.

## Assistant

Also apply the same to the Whisper path for consistency:

## Assistant

The transducer/RNN-T model's token vocabulary is all-caps — that's normal for many sherpa-onnx streaming models. Added `.toLowerCase()` after `.trim()` in [sherpa_onnx_stt.dart](flutter_app/lib/core/speech/sherpa_onnx_stt.dart) for both the online and Whisper paths. The result will now come out as plain lowercase text.
