# Conversation - Revert avatar animation to emoticon_linear

| Field | Value |
|---|---|
| Saved | 2026-06-04 01:57:25 |
| Commit | Revert TutorAvatar to emo_linear.riv with direct amplitude input |
| Project | C:\project\vLearn2 |

---

## User

hello , i want previous method for character animation. So I want emoticon_linear again.
 emoticon_visemes is not suitable now.

## Assistant

Reverted `tutor_avatar.dart` from `emo_visemes.riv` (viseme-bucketed mouth) back to `emo_linear.riv` (direct amplitude mouth).

Changes made:
- Asset path: `emoticon_visemes/emo_visemes.riv` → `emoticon_linear/emo_linear.riv`
- Input: `_mouthInput` (Number 0–5 viseme) → `_amplitudeInput` (Number 0.0–1.0)
- Removed: `_visemeFor()`, `_updateMouthFromAmplitude()`, anti-chatter state (`_currentViseme`, `_lastSwitchMs`, `_holdMs`)
- `didUpdateWidget`: direct `_amplitudeInput?.value = widget.amplitude.clamp(0.0, 1.0)` instead of viseme bucketing
- `_applyMoodToRive`: resets `_amplitudeInput` to 0.0 on leaving Speaking
- `RiveRenderConfig.factory` retained (Windows→Flutter renderer, others→native)

---

## Prompt

hello , i want previous method for character animation. So I want emoticon_linear again.
 emoticon_visemes is not suitable now.
