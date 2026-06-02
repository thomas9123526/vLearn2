# btw, the chracter in chat screen is not the one for emo_linear.riv, I only put e

Session: `f56bdf13-4b13-4f2d-9e88-40dba40b3f91`
Saved: 2026-06-02T18:02:39.232Z

## User

btw, the chracter in chat screen is not the one for emo_linear.riv, I only put emo_linear.riv in assets/animations/emoticon_linear/emo_linear.riv, but where did the character come on the conversation tutor screen?

## Assistant

Found it. The code loads `assets/animations/emo_linear.riv` (line 122 in `tutor_avatar.dart`) but your file is at `assets/animations/emoticon_linear/emo_linear.riv` — wrong path. Let me verify:

## Assistant

Two issues:

1. **Wrong path in code** — `tutor_avatar.dart:122` loads `assets/animations/emo_linear.riv` but the file is at `assets/animations/emoticon_linear/emo_linear.riv`
2. **Subdirectory not declared** — `pubspec.yaml` only has `assets/animations/` which doesn't include subdirectories in Flutter

Fix both:

## Assistant

Now commit:

## Assistant

Done. Two fixes:

- [tutor_avatar.dart:122](flutter_app/lib/features/conversation/widgets/tutor_avatar.dart#L122) — path updated to `assets/animations/emoticon_linear/emo_linear.riv`
- [pubspec.yaml](flutter_app/pubspec.yaml) — added `- assets/animations/emoticon_linear/` (Flutter doesn't recurse into subdirectories automatically)

Hot restart the app and the tutor screen should now show your `emo_linear.riv` character.
