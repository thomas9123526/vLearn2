# on the chat mode screen of conversation screen in application, when i input voic

Session: `90c5c6ba-f941-45bb-8889-37114ea77f9f`
Saved: 2026-06-01T09:42:21.118Z

## User

on the chat mode screen of conversation screen in application, when i input voice the animation bar seems not working.

## Assistant

Let me find the voice input animation code in the conversation/chat screen.

## Assistant

Now let me check the `audioRecorderProvider` and `amplitudeStream` source:

## Assistant

Let me check the `record` package version and see if `getAmplitude()` is available:

## Assistant

Found the issue. The `record` package streams PCM in variable-sized chunks — on some Android devices/emulators these come infrequently (every ~500ms+), so amplitude updates are too slow to drive visible animation. The fix is to poll `_recorder.getAmplitude()` on a short timer instead of deriving amplitude from PCM chunks.

## Assistant

Now wire up the timer — start it in `start()`, cancel it in `stop()` and `cancel()`, and remove the PCM-based `_amplitudeCtrl.add`:

## Assistant

Cancel the timer in `stop()` and `cancel()`, remove unused `_rms`, and fix the tearoff:

## Assistant

Now make all three fixes in one pass:

## Assistant

Now fix the tearoff warning and add `_ampTimer` cancellation to `stop()` and `cancel()`:

## Assistant

No more diagnostics. Now commit:

## Assistant

Done. Here's what changed in [audio_recorder.dart](flutter_app/lib/core/speech/audio_recorder.dart):

- **Removed** `_rms()` and PCM-based amplitude — PCM chunks from the `record` plugin arrive infrequently on many Android devices, making bar updates too slow to see
- **Added** `_ampTimer` — a `Timer.periodic(80ms)` that calls `_recorder.getAmplitude()` (dBFS) and maps `-60..0 dBFS → 0.0..1.0` for the waveform bars
- Timer is properly cancelled in both `stop()` and `cancel()`

The PCM stream itself is still collected into `_buffer` for STT — only the amplitude source changed.
