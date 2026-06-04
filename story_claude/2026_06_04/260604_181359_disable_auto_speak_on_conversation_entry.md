# Conversation - Disable auto-speak on conversation entry

| Field | Value |
|---|---|
| Saved | 2026-06-04 18:13:59 |
| Commit | auto: don't auto-speak opening greeting when entering conversation screen |
| Project | C:\project\vLearn2 |

---

## User

Don's speak at first when user enter the conversation screen

## Assistant

Removed all four Turn-0 auto-speak triggers. The tutor now stays silent when the user first enters; speech only plays when the AI replies after the user sends a message.

**Removed from `conversation_screen.dart`:**
- `initState` post-frame callback that called `_maybeSpeakLatestAssistantReply()` when `!hasUserTurn`
- `speechReadyProvider` listener block that retried the opening greeting when speech became ready at Turn 0

**Removed from `tutor_mode_view.dart`:**
- Same two symmetrical blocks (initState callback + speechReadyProvider listener)

The `didUpdateWidget` calls that speak when new AI messages arrive after a user turn are untouched — normal conversational TTS still works.

---

## Prompt

Don's speak at first when user enter the conversation screen
