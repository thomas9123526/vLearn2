# Conversation - Switch tutor avatar from emo_linear to emo_visemes riv

| Field | Value |
|---|---|
| Saved | 2026-06-03 23:17:18 |
| Commit | Switch tutor avatar to emo_visemes.riv with mouth viseme bucketing |
| Project | C:\project\vLearn2 |

---

## User

instead of flutter_app\assets\animations\emoticon_linear, I want use flutter_app\assets\animations\emoticon_visemes.

we implemented emoticon_linear\emo_linear.riv currently. instead i want implement emo_visemes.rive in the tutor mode screen.
you can reference emo_visemes.md.
The main difference is that visemes in emoticon_visemes has specific mouth actions than the one in the emoticon_linear

## Assistant

Switched the tutor avatar from `emo_linear.riv` (amplitude-driven blend mouth) to `emo_visemes.riv` (discrete 6-shape viseme mouth).

**Key difference:** `emo_linear` used a continuous `amplitude` input (0.0–1.0) that blended the mouth open proportionally. `emo_visemes` exposes a `mouth` Number input (0–5) with six distinct mouth shapes: 0 rest, 1 mbp (closed), 2 ai (wide open), 3 e (wide), 4 u (round small), 5 o (round open).

**Changes made:**

1. **`pubspec.yaml`** — added `assets/animations/emoticon_visemes/` asset declaration.

2. **`tutor_avatar.dart`:**
   - `_fileLoader` path: `emoticon_linear/emo_linear.riv` → `emoticon_visemes/emo_visemes.riv`
   - Replaced `_amplitudeInput` field with `_mouthInput` (Number, drives the viseme)
   - Added viseme anti-chatter state: `_currentViseme`, `_lastSwitchMs`, `_holdMs = 70ms`
   - `_onRiveLoaded`: looks up `mouth` input instead of `amplitude`
   - `didUpdateWidget`: calls `_updateMouthFromAmplitude()` instead of writing raw amplitude
   - Added `_updateMouthFromAmplitude(double amp)` — buckets RMS amplitude into viseme index with 70ms debounce, only active while `mood == speaking`
   - Added `_visemeFor(double amp)` — threshold table from emo_visemes.md (ordered by mouth openness, not enum value)
   - `_applyMoodToRive`: resets `_mouthInput?.value = 0.0` (not amplitude) when leaving Speaking state

The parent `TutorModeView` is unchanged — it still passes `amplitude` as a 0.0–1.0 float; `TutorAvatar` now buckets it internally.

---

## Prompt

instead of flutter_app\assets\animations\emoticon_linear, I want use flutter_app\assets\animations\emoticon_visemes.

we implemented emoticon_linear\emo_linear.riv currently. instead i want implement emo_visemes.rive in the tutor mode screen.
you can reference emo_visemes.md.
The main difference is that visemes in emoticon_visemes has specific mouth actions than the one in the emoticon_linear
