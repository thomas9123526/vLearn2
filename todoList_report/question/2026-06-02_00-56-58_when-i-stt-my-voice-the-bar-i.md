# when i stt my voice, the bar i indicated with red pencil, it never senses for my

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-01T15:56:58.605Z

## User

when i stt my voice, the bar i indicated with red pencil, it never senses for my voice and never represent amplitude of voice

## Assistant

Let me find the waveform/amplitude bar widget in the conversation screen.

## Assistant

The problem is clear: `_recorder.getAmplitude()` from the `record` plugin **doesn't reliably return values in stream mode** — it's designed for file-based recording. Since the PCM chunks already stream in via `_sub`, we should compute RMS amplitude directly from those bytes instead.

## Assistant

Now replace the `_ampTimer` polling with RMS computed from each PCM chunk:

## Assistant

Now remove the dead `_ampTimer` field and its `cancel()` calls since we no longer use it:

## Assistant

No more diagnostics. Now commit.

## Assistant

**Root cause:** `_recorder.getAmplitude()` from the `record` plugin doesn't return real values during `startStream()` mode — it's for file recording. The polled dBFS was always near -160, so the waveform never moved.

**Fix:** dropped the `_ampTimer` entirely. Each PCM chunk that arrives in the stream listener now computes RMS directly from its Int16 samples and emits a normalised 0–1 value on `amplitudeStream`. A mild `pow(x, 0.4)` compression makes quiet voices still visible. The waveform widget subscribes to that same stream and will now animate in real time.
