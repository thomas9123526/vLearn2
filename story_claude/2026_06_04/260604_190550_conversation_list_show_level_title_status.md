# Conversation - Show level, scenario title and status in conversation list

| Field | Value |
|---|---|
| Saved | 2026-06-04 19:05:50 |
| Commit | auto: show CEFR level, scenario title, and status in conversation history list |
| Project | C:\project\vLearn2 |

---

## User

In the conversation list of application, I want show level and scenario title and last status that is completed or not.

## Assistant

Added scenario title, CEFR level badge, and completion status to the conversation history list.

**Backend (`conversations.service.ts` + `conversation.dto.ts`):**
- Added `scenarioTitle: string | null` to `SessionDto`
- `toSessionDto` gains an optional `scenarioTitle` parameter (null by default — other endpoints unaffected)
- `listForUser` now batch-loads scenario titles in one extra query (collects unique `scenario_id`s, does one `findBy({ id: In([...]) })`, builds a map) and passes the English title to each DTO

**Flutter (`models.dart`):**
- `ConversationSession` gains `cefrLevel: int?` (parsed from `cefrLevel` JSON key — was sent by backend but never read) and `scenarioTitle: String?`

**Flutter (`conversation_history_screen.dart`):**
- `_SessionTile` title row: small `B1`-style CEFR badge chip + scenario title (falls back to "Free conversation")
- Subtitle: persona name + date + turn count
- Trailing: status badge (Active / Completed / Abandoned) + delete button — unchanged

---

## Prompt

In the conversation list of application, I want show level and scenario title and last status that is completed or not.
