# Conversation - Add voice waveform animation to chat recording

| Field | Value |
|---|---|
| Saved | 2026-06-01 14:24:52 |
| Commit | Add voice waveform animation that reacts to mic amplitude during recording |
| Project | C:\project\vLearn2 |

---

## User

I want put animation when voice recog on conversation screen.
So if the animation should be linear by the user voice

## Assistant

**Two files changed:**

`audio_recorder.dart` — added RMS amplitude computation:
- Added `_amplitudeCtrl` (`StreamController<double>.broadcast`)
- Added `amplitudeStream` getter exposing it publicly
- Added `_rms(Uint8List chunk)` method: iterates 16-bit little-endian samples, computes `sqrt(sumOfSquares / count) / 32768.0` → normalised 0.0–1.0
- PCM stream listener now calls `_buffer.add(chunk)` AND `_amplitudeCtrl.add(_rms(chunk))` per chunk
- `stop()` and `cancel()` emit `0.0` to reset the animation
- `dispose()` closes the amplitude controller

`conversation_screen.dart` — added `_VoiceWaveform` widget and integrated it:
- `_VoiceWaveform` is a `StatefulWidget` that subscribes to `amplitudeStream` in `initState` and calls `setState` on each value
- 5 animated bars with per-bar multipliers `[0.60, 0.90, 1.00, 0.85, 0.65]` so they reach different heights at the same amplitude (natural equaliser look)
- Each bar: `AnimatedContainer` 80ms easeOut, width 4px, height = `6 + amplitude × multiplier × 36` px
- In `_ChatModeBodyState.build()`: when `_recording == true`, the `Expanded` slot shows `_VoiceWaveform` instead of the `TextField`; when `_recording == false` the text field returns

---

## Prompt

I want put animation when voice recog on conversation screen.
So if the animation should be linear by the user voice
