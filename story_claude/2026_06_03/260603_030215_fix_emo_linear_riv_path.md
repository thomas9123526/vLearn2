# Conversation - Fix emo_linear.riv path in tutor_avatar.dart

| Field | Value |
|---|---|
| Saved | 2026-06-03 03:02:15 |
| Commit | fix: correct emo_linear.riv asset path and declare emoticon_linear/ in pubspec |
| Project | C:\project\vLearn2 |

---

## User

btw, the character in chat screen is not the one for emo_linear.riv, I only put emo_linear.riv in assets/animations/emoticon_linear/emo_linear.riv, but where did the character come on the conversation tutor screen?

## Assistant

Two bugs: (1) `tutor_avatar.dart:122` loaded `assets/animations/emo_linear.riv` but the file is at `assets/animations/emoticon_linear/emo_linear.riv`. (2) Flutter's asset system doesn't recurse into subdirectories — `assets/animations/` in pubspec.yaml doesn't include `emoticon_linear/`. Fixed both: updated the path in code and added `assets/animations/emoticon_linear/` to pubspec.yaml.

---

## Prompt

btw, the character in chat screen is not the one for emo_linear.riv, I only put emo_linear.riv in assets/animations/emoticon_linear/emo_linear.riv, but where did the character come on the conversation tutor screen?
