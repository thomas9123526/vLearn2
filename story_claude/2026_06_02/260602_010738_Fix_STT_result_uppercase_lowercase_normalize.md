# Conversation - Fix STT result uppercase lowercase normalize

| Field | Value |
|---|---|
| Saved | 2026-06-02 01:07:38 |
| Commit | fix: lowercase STT result to fix all-uppercase output from transducer model |
| Project | C:\project\vLearn2 |

---

## User

The stt result is all uppercase

## Assistant

Root cause: RNN-T/transducer models (Zipformer etc.) commonly have uppercase-only token
vocabularies, so the raw model output is all-caps (e.g. "HELLO HOW ARE YOU").

Fix: call `.toLowerCase()` on the trimmed result in `sherpa_onnx_stt.dart` for both the
online (transducer) and offline (whisper) paths before returning `SttResult`.

---

## Prompt

The stt result is all uppercase
