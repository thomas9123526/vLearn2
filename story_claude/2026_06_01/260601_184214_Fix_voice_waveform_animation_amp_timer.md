# Conversation - Fix voice waveform animation using amplitude poll timer

| Field | Value |
|---|---|
| Saved | 2026-06-01 18:42:14 |
| Commit | fix: poll getAmplitude() on 80ms timer to drive voice waveform animation |
| Project | C:\project\vLearn2 |

---

## User

on the chat mode screen of conversation screen in application, when i input voice the animation bar seems not working.

## Assistant

Root cause: the record package streams PCM in variable-sized chunks that arrive infrequently on some Android devices/emulators, so amplitude updates from _rms(chunk) were too rare to produce visible animation.

Fix: replaced PCM-based amplitude with a Timer.periodic(80ms) that calls _recorder.getAmplitude() (dBFS). Maps -60..0 dBFS → 0..1 for the waveform bars. Also removed the unused _rms method, unused dart:math import, and cancelled the new timer in both stop() and cancel().

---

## Prompt

on the chat mode screen of conversation screen in application, when i input voice the animation bar seems not working.
