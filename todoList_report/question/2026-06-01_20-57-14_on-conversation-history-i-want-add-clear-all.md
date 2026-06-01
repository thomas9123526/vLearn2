# on conversation history, i want add clear all button on top right

Session: `90c5c6ba-f941-45bb-8889-37114ea77f9f`
Saved: 2026-06-01T11:57:14.906Z

## User

on conversation history, i want add clear all button on top right

## Assistant

Let me find the conversation history screen.

## Assistant

No bulk-delete endpoint exists yet. I'll add it to the backend, wire it in the Flutter API client, then add the button to the history screen.

## Assistant

Now I have everything I need. Let me add all three pieces:

**1 — Backend service method:**

## Assistant

**2 — Backend controller endpoint:**

## Assistant

**3 — Flutter API client method:**

## Assistant

**4 — Clear All button on the history screen:**

## Assistant

Now commit:

## Assistant

Done. Three layers changed:

**Backend** — `DELETE /conversations/sessions` (no `:id`) calls `deleteAllSessions(userId)` which runs in one transaction: nulls guard-violation FKs, then bulk-deletes messages → scores → sessions.

**Flutter API client** — `deleteAllSessions()` in [app_apis.dart](flutter_app/lib/core/api/app_apis.dart).

**History screen** — `delete_sweep_outlined` icon appears in the AppBar top-right only when the list is non-empty. Tapping it shows a confirmation dialog with a red "Clear all" button. On confirm it calls the API then invalidates `_historyProvider` to refresh the now-empty list.
