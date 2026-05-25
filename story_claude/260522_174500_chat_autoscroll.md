# Chat mode — auto-scroll to the newest message

## The problem

In chat mode, sending a message (or the AI reply landing) did **not**
scroll the list. The user's own bubble and the AI's response appeared
below the fold; you had to scroll by hand to see them.

## Why the old code didn't work

`_send` registered a post-frame callback to scroll right after
`ref.invalidate(_sessionProvider)`. But `invalidate` triggers an
**async refetch** — when that post-frame callback fired, the screen
was showing the loading spinner (`data.when(loading: …)`), the
`ListView` was gone, so `_scroll.hasClients` was false and the scroll
silently no-op'd. By the time the new data rebuilt the list, nothing
re-triggered a scroll.

## The fix — `conversation_screen.dart`

Drive the scroll off the message list *actually growing*, not off the
send action:

- New `_lastMessageCount` field tracks the rendered message count.
- `build()` now has a `ref.listen` on `_sessionProvider`: when a
  refetch resolves with **more** messages than before, it schedules a
  post-frame `_scrollToBottom()`. This fires after the `ListView` has
  rebuilt with the new bubbles — `_scroll.hasClients` is true — so the
  scroll lands. It catches both the user's turn and the AI's reply
  (they arrive together in the post-send refetch).
- New `_scrollToBottom({jump})` helper:
  - First load (`_lastMessageCount == 0`) → `jumpTo` (no animation).
  - Later turns → `animateTo` (250 ms ease-out) so the eye follows
    the new bubble in.
  - Either way a second post-frame pass `jumpTo(maxScrollExtent)`
    corrects for the `ListView.builder` lazy extent estimate once the
    trailing bubbles are laid out — so it lands exactly at the bottom,
    not slightly short.
- The broken post-frame block in `_send` is removed; `_send` just
  invalidates and lets the `ref.listen` handle the scroll.

## Scope

Chat mode only (`_ChatModeBody`'s `ListView`) — that's the screen in
the report. Tutor mode has its own layout and isn't touched.

## Verification

```text
flutter analyze — conversation_screen.dart → No issues found
```

## User prompt (verbatim)

> on this screen, if i put sometext and click send ( red pointed in
> the png), the chart should be scroll to bottom to see what i have
> seen.
> also when ai's response arrived, it should scroll to bottom so the
> user can notice it.
