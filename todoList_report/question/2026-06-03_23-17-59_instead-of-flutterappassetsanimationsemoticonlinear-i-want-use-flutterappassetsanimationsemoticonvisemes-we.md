# instead of flutter_app\assets\animations\emoticon_linear, I want use flutter_app

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-03T14:17:59.755Z

## User

instead of flutter_app\assets\animations\emoticon_linear, I want use flutter_app\assets\animations\emoticon_visemes.

we implemented emoticon_linear\emo_linear.riv currently. instead i want implement emo_visemes.rive in the tutor mode screen.
you can reference emo_visemes.md.
The main difference is that visemes in emoticon_visemes has specific mouth actions than the one in the emoticon_linear

## Assistant

Let me read the reference doc and explore the current implementation first.

## Assistant

Now let me find the current Rive implementation in the tutor mode screen.

## Assistant

Let me read the actual files before touching anything.

## Assistant

Now let me check pubspec assets and the tutor_mode_view for amplitude wiring.

## Assistant

Now update `tutor_avatar.dart`. Four targeted edits:

## Assistant

Now update `_applyMoodToRive` to reset the `mouth` input (not `amplitude`) when leaving Speaking:

## Assistant

Also update the class-level comment that still says `emo_linear.riv`:

## Assistant

Also update the `/// Mochi (emo_linear.riv)` comment at the top:

## Assistant

Good. Let me do a quick sanity check on the final file:

## Assistant

One stale reference in the `onFailed` log — fix it:

## Assistant

Now commit. First get the timestamp:

## Assistant

Done. Here's a summary of what changed:

**`tutor_avatar.dart`**
- Asset: `emoticon_linear/emo_linear.riv` → `emoticon_visemes/emo_visemes.riv`
- Mouth driver: `amplitude` input (continuous 0–1 blend) → `mouth` input (discrete 0–5 viseme)
- Added `_visemeFor(double amp)` that buckets the RMS envelope into the 6 shapes from the md guide (ordered by openness: mbp → rest → u → e → o → ai)
- Added 70ms anti-chatter debounce so the mouth doesn't flicker between visemes faster than a frame
- Mouth resets to `0` (rest) when leaving the Speaking state

**`pubspec.yaml`** — `assets/animations/emoticon_visemes/` declared so Flutter bundles the new `.riv`.

The parent `TutorModeView` is untouched — it still pushes `amplitude` (0–1 float) into the avatar the same way.
