# Conversation - Guard TTS auto-play for resumed sessions

| Field | Value |
|---|---|
| Saved | 2026-06-04 14:15:51 |
| Commit | Guard opening TTS auto-play: skip for resumed sessions with existing user turns |
| Project | C:\project\vLearn2 |

---

## User

ok , i found the issue. Tutor says first sentences when enter the conversation.
If i switch mode from tutor to chat or chat to tutor, it says again. This is what i wanted.
Also If the user continue conversation later, you should think what to do for that situation.

## Assistant

Added a guard: `final hasUserTurn = widget.messages.any((m) => m.role == 'user')`.

Auto-play from `initState` / `speechReadyProvider` now only fires when `!hasUserTurn` (Turn 0).

| Scenario | Behaviour |
|---|---|
| Fresh session entry (Turn 0) | ✅ Speaks opening greeting |
| Mode switch at Turn 0 | ✅ Speaks opening greeting (still no user turn) |
| Resume old session from history | ❌ Stays silent (user already heard it) |

New messages from the AI mid-conversation still auto-play via the existing `didUpdateWidget` path — that path is unchanged.

---

## Prompt

Also If the user continue conversation later, you should think what to do for that situation.
