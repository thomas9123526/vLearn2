# Tutor mode: fullscreen, latest tutor/user bubble only

## What this task did

- **Fullscreen:** Tutor mode hides the scaffold `AppBar`; back / turn / chat toggle / end live as an overlay on the stage.
- **No scroll transcript:** Shows only the **latest** assistant message and **latest** user message (one bubble each).
- **Layout:** ~62% stage (large avatar), compact bubble strip, dock unchanged.

Files: [tutor_mode_view.dart](../flutter_app/lib/features/conversation/widgets/tutor_mode_view.dart), [conversation_screen.dart](../flutter_app/lib/features/conversation/conversation_screen.dart).

## User prompt (verbatim)

> I want only one bubble for tutor and one bubble for user at a time. There is no need to scroll transcript. I want tutor mode to be fullscreen to get more spaces.
