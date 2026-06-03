# I want put animation when voice recog on conversation screen. So if the animatio

Session: `d506161a-a027-47af-a3ba-75104b012999`
Saved: 2026-06-01T05:26:39.492Z

## User

I want put animation when voice recog on conversation screen.
So if the animation shoule be linear by the user voice

## Assistant

Let me check what the audio recorder exposes for amplitude data during recording before designing anything.

## Assistant

The recorder streams raw PCM bytes but has no amplitude signal yet. The plan:

1. **`audio_recorder.dart`** — compute RMS amplitude from each PCM chunk, expose it as `Stream<double>`
2. **`conversation_screen.dart`** — add a `_VoiceWaveform` widget (5 animated bars) that reacts to the stream; swap in place of the text field while recording

## Assistant

Expected — `math` will be used once I add the RMS method. Continuing.

## Assistant

Now update the stream listener to compute RMS from each chunk, and reset amplitude on stop/cancel.

## Assistant

Now add the `_rms` method, reset amplitude on stop/cancel, and close the controller on dispose.

## Assistant

Now reset amplitude to 0.0 when recording stops or is cancelled, and close the controller on dispose.

## Assistant

Now add the `_VoiceWaveform` widget to `conversation_screen.dart` and swap the text field for the waveform while recording.

## Assistant

Now I'll swap the text field for the waveform while recording, and add the `_VoiceWaveform` widget after `_ChatMicButton`.

## Assistant

Now add the `_VoiceWaveform` widget class after `_ChatMicButton`.

## Assistant

Need to add `dart:async` import for `StreamSubscription`.

## Assistant

Also fix the redundant `crossAxisAlignment` default:

## Assistant

Clean. Now commit with the story file.

## Assistant

Done. Here's how it works end-to-end:

**[audio_recorder.dart](flutter_app/lib/core/speech/audio_recorder.dart)** — each PCM chunk received from the mic is now fed through `_rms()` (root-mean-square of the 16-bit samples, normalised to 0–1) and broadcast on `amplitudeStream`. When recording stops, `0.0` is emitted to reset the bars.

**[conversation_screen.dart](flutter_app/lib/features/conversation/conversation_screen.dart)** — `_VoiceWaveform` subscribes to `amplitudeStream` and drives 5 `AnimatedContainer` bars. Each bar has a different multiplier (`0.60 / 0.90 / 1.00 / 0.85 / 0.65`) so they reach different heights at the same amplitude — this gives a natural multi-band equaliser look instead of all bars moving identically. Bars animate with 80 ms easeOut so the motion feels smooth, not jittery.

While recording: text field → waveform. When the user taps stop: waveform → text field returns.
