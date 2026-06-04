# Don's speak at first when user enter the conversation screen

Session: `ec7e9529-1399-4642-b1c1-753f53834cc7`
Saved: 2026-06-04T09:14:20.669Z

## User

Don's speak at first when user enter the conversation screen

## Assistant

Let me find where the auto-speak on entry is triggered.

## Assistant

There are exactly 4 auto-speak triggers to remove — the two `initState` post-frame callbacks and the two `speechReadyProvider` listeners, both in `conversation_screen.dart` and `tutor_mode_view.dart`. The `didUpdateWidget` speaks (which fire when the AI replies after a user turn) stay untouched.

## Assistant

Four targeted removals:

## Assistant

Now commit and story:

## Assistant

Done. Removed all four auto-speak triggers — the two in [conversation_screen.dart](flutter_app/lib/features/conversation/conversation_screen.dart) and the two in [tutor_mode_view.dart](flutter_app/lib/features/conversation/widgets/tutor_mode_view.dart). The tutor is now silent on entry; TTS only fires when the AI replies after the user sends a message.
