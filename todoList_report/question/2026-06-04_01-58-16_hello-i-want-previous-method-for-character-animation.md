# hello , i want previous method for character animation. So I want emoticon_linea

Session: `10e65b1d-4afb-4146-8130-782b3c1583d6`
Saved: 2026-06-03T16:58:16.705Z

## User

hello , i want previous method for character animation. So I want emoticon_linear again.
 emoticon_visemes is not suitable now.

## Assistant

Let me check the current state of the avatar and visemes code.

## Assistant

The current `tutor_avatar.dart` was switched to `emo_visemes.riv`. Let me read it fully to understand what needs reverting.

## Assistant

Clear picture. The current file uses `emo_visemes.riv` with viseme bucketing (`_mouthInput`, `_visemeFor`, anti-chatter). Reverting to `emo_linear.riv` means going back to direct `_amplitudeInput` (0.0–1.0), dropping all the viseme logic.

## Assistant

Now commit with a story file.

## Assistant

Done. [tutor_avatar.dart](flutter_app/lib/features/conversation/widgets/tutor_avatar.dart) is back to `emo_linear.riv` with direct `amplitude` input (0.0–1.0). All the viseme bucketing code (`_visemeFor`, `_updateMouthFromAmplitude`, anti-chatter state) has been removed. The `RiveRenderConfig` platform guard (Flutter renderer on Windows) is kept as-is.
