# In the conversation list of application, I want show level and scenario title an

Session: `ec7e9529-1399-4642-b1c1-753f53834cc7`
Saved: 2026-06-04T10:06:19.332Z

## User

In the conversation list of application, I want show level and scenario title and last status that is completed or not.

## Assistant

Let me find the conversation list screen and check what the session list endpoint currently returns.

## Assistant

Now I have the full picture. The backend `toSessionDto` already returns `cefrLevel` — just missing `scenarioTitle`. The Flutter tile shows persona name and mode but not the scenario title or CEFR level.

**Plan:**
- Backend `listForUser` → join with `vl_scenarios` to include `scenarioTitle` (English) in each session row
- `ConversationSession` model → add `scenarioTitle: String?` (already has `cefrLevel`)
- `_SessionTile` → show scenario title as the primary title, CEFR chip + status badge in trailing

Let me check the SessionDto type to know where to add the field:

## Assistant

`In` is already imported. Now I'll make all the changes in one pass.

## Assistant

Now update `toSessionDto` to accept an optional title, and `listForUser` to batch-fetch titles:

## Assistant

Now update `listForUser` to batch-load scenario titles:

## Assistant

Now add `scenarioTitle` to the Flutter `ConversationSession` model:

## Assistant

Now update `_SessionTile` to show scenario title, CEFR level, and completion status clearly:

## Assistant

`ConversationSession` doesn't have `cefrLevel` yet — the backend sends it but the Flutter model never parsed it. Adding it now:

## Assistant

No more diagnostics errors. Now commit everything:

## Assistant

Done. Each session tile in the history list now shows:

- **Title row**: `[B1]` CEFR badge chip + scenario title (or "Free conversation" for free-talk sessions)
- **Subtitle**: persona name · date · turn count  
- **Trailing**: Active / Completed / Abandoned status badge + delete button

The backend does one extra query per `listSessions` call to batch-load scenario titles — no N+1.
