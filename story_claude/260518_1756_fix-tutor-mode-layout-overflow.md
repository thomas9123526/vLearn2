# Fix tutor mode yellow/black overflow stripes

## What this task did

The yellow-and-black diagonal pattern was Flutter's **debug overflow indicator** (`BOTTOM OVERFLOWED BY 121 PIXELS`). Tutor mode stacked a 300px avatar, long idle suggestion, text field, and mic in a fixed `Column` that could not shrink on phone screens.

**Fix** in [tutor_mode_view.dart](../flutter_app/lib/features/conversation/widgets/tutor_mode_view.dart):
- Scrollable top area (`SingleChildScrollView`) for avatar + caption
- Smaller avatar on short viewports (`LayoutBuilder`, 176 vs 240)
- Suggestion chip moved above the input bar with `maxLines: 3` + ellipsis
- Bottom controls in `SafeArea` only (matches chat mode)

## Conversation summary

- **User** shared a screenshot of tutor mode with yellow/black stripes and asked why the screen looks ugly.
- **Assistant** explained it is a layout overflow (debug-only in debug builds) and fixed the tutor mode layout.

## User prompt (verbatim)

> And why I get this urgly screen, yellow black pattern
