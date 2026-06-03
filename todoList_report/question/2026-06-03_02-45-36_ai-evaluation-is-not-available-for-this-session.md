# "Ai evaluation is not available for this session" shows when i end the conversat

Session: `f56bdf13-4b13-4f2d-9e88-40dba40b3f91`
Saved: 2026-06-02T17:45:36.346Z

## User

"Ai evaluation is not available for this session" shows when i end the conversation.

## Assistant

Let me find where that message comes from:

## Assistant

The screen polls `getSessionScore` every 3 seconds for up to 12 tries (36 seconds), then gives up and shows "not available" — meaning the backend's `evaluateSession` is returning `null` (failed silently).

This is the same root cause: the AI call inside `evaluateSession` fails with connection error. **Did you restart the backend after the `.env` change** (`localhost` → `127.0.0.1`)? That fix applies to both the chat and evaluation calls.

Check the backend log for a line like:
```
WARN [ConversationOrchestrator] Session evaluation failed: Connection error.
```

If you see it, the backend needs a restart to pick up the new `OPENAI_BASE_URL`.
