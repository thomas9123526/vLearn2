# And I have put .riv assets.    tutor_hiro.riv. It has the following features: Wh

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-26T00:47:24.804Z

## User

And I have put .riv assets.   
tutor_hiro.riv.

It has the following features:

What you have vs. what's missing
✅ Working in this file:

blink trigger → character blinks (both eyes squash/release)
emotion input → when set to 1, character smiles (mouth_softSmile)
mouth_shape input → when set to 1, character shows "A" mouth shape

❌ Not built yet:

emotion 2-7 (other emotions like sad, surprised, angry, etc.)
mouth_shape 2-5 (E, I, O, U visemes)
nod, shake triggers (head animations)
attention boolean (listening pose)

Your Flutter code can call blink, set emotion to 1, and set mouth_shape to 1, and those will work. Everything else will just do nothing (no error, just no reaction).

Test it in Flutter
Drop tutor_hiro.riv into your Flutter assets/ folder, load it with the Rive package, and try:

Firing the blink trigger → Hiro blinks
Setting emotion to 1 → Hiro smiles
Setting mouth_shape to 1 → mouth opens to "A"

Once you confirm it works, you can either:

Come back and finish the other emotions/visemes (same pattern you just learned)
Or duplicate this entire rig to Mei/Jun/Lin first, then fill in all 4 characters' animations together

So can you implement this .riv for all character animations for tutor mode conversation screen with various status when interacting with the app user.

## Assistant

Let me first explore the existing tutor mode setup and check what's already in place.

## Assistant

Now I have the picture. The current `TutorAvatar` plays the `.riv` file but doesn't touch the state-machine inputs — so blink/emotion/mouth_shape never fire. I'll wire them up.

Mapping plan:
- **blink trigger** — periodic random fire (3.5–7 s) regardless of mood, like natural blinking.
- **emotion input** — `1` (smile) on `praising` / `speaking` / `encouraging`; `2` (sad, no-op until built) on `disappointed`; `0` on idle/listening.
- **mouth_shape input** — cycle while `speaking` (only viseme 1 ships today, so alternate `1↔0` ≈ 160 ms = open/close talking mouth; trivial to swap to `1..5` cycle when more visemes ship).
- **attention bool** — `true` on `listening`, `false` otherwise.
- **nod / shake triggers** — fired on `praising` / `disappointed` (no-op until built).
- Missing inputs are detected by `findInput` returning null — calls become no-ops, so the same code drives Mei/Jun/Lin's stub `.riv`s without crashing.

## Assistant

Real warning — I keep `_smController` but never read it after init (the input handles are stored directly). Dropping the field:

## Assistant

Those diagnostics are stale — `flutter analyze` just reported **No issues found**. Committing:

## Assistant

Committed as `55ef782`.

## What now drives Hiro's face

`TutorAvatar` no longer just plays the `.riv` — it grabs a `StateMachineController` on init, resolves the inputs by name (`is`-checking the runtime subtype so missing inputs no-op cleanly), and reacts to every `TutorMood` change:

| Mood          | `emotion` | `attention` | trigger      | mouth     |
|---------------|-----------|-------------|--------------|-----------|
| idle          | 0         | false       | —            | stopped   |
| speaking      | 1 (smile) | false       | —            | cycling   |
| listening     | 0         | true        | —            | stopped   |
| praising      | 1         | false       | `nod`        | stopped   |
| disappointed  | 2 (sad)*  | false       | `shake`      | stopped   |
| encouraging   | 1         | false       | —            | stopped   |

`*` `emotion=2`, `nod`, `shake`, `attention` are wired but no-op on `tutor_hiro.riv` today — the moment those animations ship in the Rive editor, the app picks them up with **zero Dart change**.

Plus:
- **Random natural-blink timer** — 3.5–7 s intervals regardless of mood, mimics real blinking.
- **Mouth-viseme cycler** — alternates `mouth_shape 1↔0` every 160 ms while `_mood == speaking` (driven by `TtsService.isSpeakingStream`). One-line swap in `_visemeAt` switches to a full `1..5` cycle once you build E/I/O/U.

## What you'll see after `flutter run`

1. Open a scenario → Face mode → Hiro renders, breathing.
2. Wait ~5 s → Hiro blinks. Repeats forever.
3. Send a message; AI replies → mouth opens/closes through the whole TTS playback, emotion stays on smile.
4. Tap mic to record → `attention=true` fires (no visible change yet — log line at init shows whether each input was resolved).

## Other personas

Mei / Jun / Lin currently fall through to `CartoonFace` (no `.riv` shipped). When you copy Hiro's rig to them, just keep the same input names — this code finds them automatically. The init log in logcat shows exactly which inputs are present per persona, so you'll see at-a-glance which stubs are missing.

`flutter analyze` clean.
