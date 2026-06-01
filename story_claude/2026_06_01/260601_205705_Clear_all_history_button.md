# Conversation - Clear all history button on conversation history screen

| Field | Value |
|---|---|
| Saved | 2026-06-01 20:57:05 |
| Commit | feat: add Clear All button to conversation history screen |
| Project | C:\project\vLearn2 |

---

## User

on conversation history, i want add clear all button on top right

## Assistant

Added DELETE /conversations/sessions backend endpoint (deleteAllSessions service method — nulls guard violation FKs, deletes messages/scores/sessions in a transaction). Added deleteAllSessions() to Flutter API client. Added delete_sweep_outlined IconButton to the AppBar of ConversationHistoryScreen (only visible when list is non-empty) with a confirmation dialog before firing the request.

---

## Prompt

on conversation history, i want add clear all button on top right
