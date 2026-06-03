# Conversation - Fix Int16List alignment crash in amplitude RMS

| Field | Value |
|---|---|
| Saved | 2026-06-02 01:03:21 |
| Commit | fix: copy PCM chunk to aligned buffer before asInt16List to avoid RangeError |
| Project | C:\project\vLearn2 |

---

## User

```
RangeError: Offset (5) must be a multiple of BYTES_PER_ELEMENT (2)
#2      AudioRecorderService.start.<anonymous closure> (audio_recorder.dart:130)
```

## Assistant

The PCM `chunk` from the stream is a sub-view of a larger native buffer. Its
`offsetInBytes` can be odd (e.g. 5), which violates the 2-byte alignment
requirement of `asInt16List`.

Fix: copy the chunk with `Uint8List.fromList(chunk)` before calling
`asInt16List(0, ...)`. The copy always starts at offset 0, so alignment is
guaranteed.

---

## Prompt

RangeError: Offset (5) must be a multiple of BYTES_PER_ELEMENT (2) crash in audio_recorder.dart
