# Conversation - Fix voice amplitude bar compute RMS from PCM

| Field | Value |
|---|---|
| Saved | 2026-06-02 00:56:29 |
| Commit | fix: compute amplitude from PCM chunks instead of getAmplitude() for live waveform |
| Project | C:\project\vLearn2 |

---

## User

(Screenshot showing conversation screen with waveform bar circled)
when i stt my voice, the bar i indicated with red pencil, it never senses for my voice and never represent amplitude of voice

## Assistant

Root cause: `_recorder.getAmplitude()` from the `record` plugin does not return meaningful values
in streaming mode (`startStream()`). It is designed for file-based recording, so the polled dBFS
value was always near -160, giving a flat waveform regardless of microphone input.

Fix: removed the `_ampTimer` polling entirely. Instead, RMS amplitude is computed directly from
each Int16 PCM chunk as it arrives in the stream listener, then normalised with mild `pow(x, 0.4)`
compression so quiet voices show up visually. The result is emitted on `amplitudeStream` which the
`_VoiceWaveform` widget already subscribes to.

---

## Prompt

when i stt my voice, the bar i indicated with red pencil, it never senses for my voice and never represent amplitude of voice
