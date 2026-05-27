# And I ask you to replace animation character with tutor_hiro.riv that i have exp

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-26T01:25:43.852Z

## User

And I ask you to replace animation character with tutor_hiro.riv that i have exported from Rive Editor.
But Conversation screen still shows old one.
I want you ignore assets for tutor in database and replace with tutor_hiro.riv

## Assistant

I'll hardcode `tutor_hiro.riv` in `TutorAvatar.build()` so it ignores `persona.riveAsset` from the database.

## Assistant

Done. The conversation screen's big tutor avatar will now always load `assets/animations/tutor_hiro.riv` regardless of what `personas.rive_asset` says in the database. Gradient colours and the letter fallback still come from the DB, so each tutor's circle stays visually distinct.

To revert later (when per-tutor .riv files exist), change [tutor_avatar.dart:288](flutter_app/lib/features/conversation/widgets/tutor_avatar.dart#L288):

```dart
const asset = _forcedRiveAsset;   // pinned
// →
final asset = widget.persona.riveAsset;  // per-tutor
```

Rebuild and the screenshot's empty circle should now show the Hiro character.
