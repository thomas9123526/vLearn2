# you mean I can't get evaluation values from the sherpa onnx nowdays?

Session: `40c2c32e-4bcc-4826-8449-440738f22ef6`
Saved: 2026-06-05T01:03:34.102Z

## User

you mean I can't get evaluation values from the sherpa onnx nowdays?

## Assistant

Correct. Right now you cannot get evaluation values from Sherpa ONNX in this codebase for two reasons:

**1. Sherpa ONNX only does transcription here**

[sherpa_onnx_stt.dart:35](flutter_app/lib/core/speech/sherpa_onnx_stt.dart#L35) — the service only outputs a text string. No scores, no confidence per phoneme, nothing else is extracted from it.

**2. The pronunciation column is a placeholder**

[conversation.entity.ts:96](backend/src/database/entities/conversation.entity.ts#L96) — `pronunciation_score` exists in the schema but `triggerEvaluation()` never writes to it. It is always `null`.

---

## What Sherpa ONNX *could* provide (but doesn't yet)

The sherpa-onnx library itself is capable of more than just transcription:

| Feature | Available in sherpa-onnx library | Used in this project |
|---|---|---|
| Speech → text | Yes | Yes (STT) |
| Word-level timestamps | Yes (streaming models) | No |
| Confidence scores per token | Yes | No |
| Pronunciation scoring (GOP) | Requires separate model | No |

To get real pronunciation scores you would need a **Goodness of Pronunciation (GOP)** model or use word timestamps + confidence from the streaming recognizer — neither is wired up here.

---

## What fills the gap today

All 5 evaluation scores (`fluency`, `accuracy`, `vocabulary`, `interaction`, `topic_adherence`) come entirely from the **AI language model** at [conversation.orchestrator.ts:263-299](backend/src/ai/conversation.orchestrator.ts#L263-L299) — it reads the text transcript and judges it holistically. This means `pronunciation_score` is always `null` and the progress tab's pronunciation bar likely shows 0 or is hidden.
