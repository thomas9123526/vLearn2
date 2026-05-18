# 01 — Text input in Tutor mode

## Ask

> I want enable typing text mode also on conversation tutor mode.

## What changed

Tutor (face-to-face) mode used to be mic-only. Hold-to-talk worked, but a user in a quiet train carriage / with a broken mic / on a build without `sherpa_onnx` was stuck. Now there's a slim text input + send button **above** the mic button — both submit through the same `onSendText` path, so the avatar still animates and the TTS still speaks the reply.

Layout (top → bottom inside the Tutor view):

```
┌────────────────────────────────────┐
│        TutorAvatar (cartoon face)  │
│        Live caption                │
│        Suggestion chip (idle)      │
├────────────────────────────────────┤
│ ┌────────────────────────┐  [➤]   │   ← new
│ │ Or type if you can't…  │        │
│ └────────────────────────┘        │
│                                    │
│              [ 🎤 ]                │   ← unchanged
└────────────────────────────────────┘
```

## Files

| Path | Change |
|------|--------|
| [flutter_app/lib/features/conversation/widgets/tutor_mode_view.dart](../../flutter_app/lib/features/conversation/widgets/tutor_mode_view.dart) | New `_typedInput` controller + `_sendTyped` future, rendered as `TextField` + `IconButton.filledTonal` row above `_MicButton` |

The text path shares `widget.onSendText` with the mic flow, so backend integration, retry/error logic, and post-send refresh all just work.
