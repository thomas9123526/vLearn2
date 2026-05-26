# Tutor mode: 65% stage + transcript + dock

## What this task did

Redesigned [tutor_mode_view.dart](../flutter_app/lib/features/conversation/widgets/tutor_mode_view.dart):

- **Stage (~65% height):** large `TutorAvatar` (scales with stage), persona name, status chip (Listening / Speaking / etc.) — no duplicate caption under avatar.
- **Transcript (scrollable):** labeled tutor / you turns using `ChatBubble`, highlight + EQ icon on the line being spoken, separate **Suggested reply** card (not a chat bubble).
- **Dock:** hold-to-talk mic + optional “Type instead” bar; mic hidden when keyboard is open.

## Conversation summary

- **User** asked to enlarge the stage to ~60–70% for a bigger avatar after the earlier UI composition suggestions.
- **Assistant** implemented the full stage + transcript + dock layout with `_stageHeightFraction = 0.65`.

## User prompt (verbatim)

> can u modify to "STAGE (~30–35% height, fixed)" area occupy some more height? about 60-70%, because Avatar can be some big
