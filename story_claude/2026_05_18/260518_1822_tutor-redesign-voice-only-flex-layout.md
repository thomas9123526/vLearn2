# Tutor mode redesign: flexible layout, voice-only

## What this task did

Fixed overflow stripes and redesigned tutor mode:

- **No fixed 62% stage** — avatar uses `Expanded` + `LayoutBuilder` sizing.
- **Top bar** is its own row (no stack overlap with avatar).
- **Compact speech cards** (max 3 lines, ellipsis) instead of full `ChatBubble`.
- **Voice-only dock** — large hold-to-talk mic; removed text field and "Type" toggle.
- Link: "Need to type? Switch to chat" opens chat mode.

## User prompt (verbatim)

> I get urgly screen, I will not constrain to AVATAR area to have 62% height.
> Please redesign to looks good and professional and functional for recording.
> remove the option to type text on tutor mode
