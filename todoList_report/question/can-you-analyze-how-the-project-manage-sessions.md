# Can you analyze how the project manage sessions vs conversations? There should b

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-20T13:49:03.170Z

## User

Can you analyze how the project manage sessions vs conversations?
There should be conversation history, the user resume last conversation or start new conversation. then old conversation or session gones?

## Assistant

Here's the full picture, in two parts: **(A) what the data model says** and **(B) what the UX actually does with it**.

---

## A) Data model — there are only "sessions", no separate "conversation" concept

The names are confusing because the code uses both words, but at the storage layer there's just one thing.

| Word | What it actually is |
| --- | --- |
| "session" | A single conversation. Table: [`vl_conversation_sessions`](backend/src/database/entities/conversation.entity.ts#L13). Has `status: 'active' \| 'completed' \| 'abandoned'`, `scenario_id` (nullable for free chat), `persona_id`, `mode`, `turn_count`, `word_count`, `xp_earned`, `started_at`, `ended_at`. |
| "conversation" | Just the *UI label*. There is **no separate `vl_conversations` table** and no parent grouping above sessions. The REST namespace is `/api/conversations/sessions/…` — `conversations` is a routing label, `sessions` is the resource. |
| messages | [`vl_conversation_messages`](backend/src/database/entities/conversation.entity.ts#L54) — one row per turn, keyed on `session_id`. |

So when the user "starts a conversation", a session row is created. When they "end the conversation", the same session's `status` flips.

---

## B) Lifecycle & resume behaviour

### Start

`POST /api/conversations/sessions` (body: `personaId`, optional `scenarioId`, `mode`). Server creates a session with `status='active'` and writes the tutor's greeting as message `sequence: 0`. [conversations.service.ts:38-74](backend/src/conversations/conversations.service.ts#L38-L74).

### Send

`POST /api/conversations/sessions/:id/messages`. Server appends user msg + assistant reply, bumps `turn_count` and `word_count`. Refuses if `status !== 'active'`. [conversations.service.ts:108-185](backend/src/conversations/conversations.service.ts#L108-L185).

### End

`POST /api/conversations/sessions/:id/end` with `{ status: 'completed' | 'abandoned' }`. Fills in `ended_at`, `duration_seconds`, `xp_earned`. Idempotent for already-ended sessions. [conversations.service.ts:227-253](backend/src/conversations/conversations.service.ts#L227-L253).

### Resume vs start new — **only inside a scenario brief**

The resume flow lives entirely in [scenario_brief_screen.dart](flutter_app/lib/features/scenarios/scenario_brief_screen.dart):

```dart
// line 25-34: ask the server "any active session for THIS scenario?"
final _activeSessionProvider =
    FutureProvider.family<ConversationSession?, String>((ref, scenarioId) async {
  final raw = await ref.read(conversationsApiProvider).listSessions(
        scenarioId: scenarioId,
        status: 'active',
        limit: 1,
      );
  if (raw.isEmpty) return null;
  return ConversationSession.fromJson(raw.first);
});
```

If that returns a session, the brief shows a `_ContinueBanner` + a sticky dock with **two buttons**:

| Button | What it calls | Effect on the old session |
| --- | --- | --- |
| **Continue** | `context.pushReplacement(AppRoute.conversation(activeSession.id))` | Nothing — keeps writing into the same row. |
| **Start fresh** | `endSession(activeSessionId, status: 'abandoned')` → then `startSession(...)` | Old session is **marked abandoned** (not deleted), and a brand-new session row is created. |

If no active session is found, the dock just shows a single "Start speaking" button → `startSession`.

### What happens to old sessions?

**They never go away.** Nothing in the backend or Flutter app deletes session rows or message rows.

- `'completed'` sessions sit there with their full message history and final scores.
- `'abandoned'` sessions sit there with whatever partial history existed when the user hit "Start fresh".
- Both stay queryable indefinitely via `GET /api/conversations/sessions` (sorted `started_at DESC`, default limit 50). The backend filters by `user_id` so each user only sees their own.

---

## C) What's missing / things worth knowing

1. **No "history" screen exists in the UI yet**, even though the backend API supports it. The `listForUser` endpoint is only consumed by the scenario-brief's "find one active session for this scenario" check — `limit: 1`, `status: 'active'`. So a completed session is essentially invisible to the user once they leave the report screen.
2. **Resume is scoped to one scenario at a time.** If you start a session for scenario A, then start a session for scenario B without ending A, both stay active. The scenario brief only checks "active sessions for *this* scenarioId", so each scenario shows its own "Continue?" prompt independently.
3. **Free chat (no scenario) is technically possible at the API level** (`scenarioId` is optional in `StartSessionDto`) but no UI surface starts one. If you ever wire a "Free chat" button, you'll get sessions with `scenario_id IS NULL` — and there's currently no resume affordance for them since the active-session lookup is keyed by scenarioId.
4. **"End" is irreversible.** Once a session goes `completed`/`abandoned`, the controller refuses further messages (`session.not_active`). Resume always means a still-active session, not reopening a finished one.

---

## TL;DR

- One table, one concept: `vl_conversation_sessions`. The word "conversation" in the code is just a routing label.
- Resume is per-scenario: if an active session exists for that scenario, the brief offers **Continue** (same row) or **Start fresh** (current row gets `status='abandoned'`, new row created).
- Old sessions are never deleted — they're soft-archived via `status` and remain queryable.
- The history is *available on the server* but the Flutter UI doesn't currently show a list of past sessions outside the per-scenario "Continue this?" prompt — that's the gap if you want a "browse history" feature.

If you want me to add a Conversation History screen (list completed/abandoned sessions, tap into the transcript), say the word — the API for it (`GET /api/conversations/sessions?status=completed`) is already there.
