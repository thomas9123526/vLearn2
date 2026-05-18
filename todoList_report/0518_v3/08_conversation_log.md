# 08_conversation_log — Conversation history analysis & continue last session

## Ask

> When the user enter conversation with tap one scenario, the user discuss with the tutor.
> Some time later after the user exits normally or unexpectedly like app crashes or by going
> home screen, the user can visit app again. And the user tap the same scenario, and the
> conversation begins with new context.
>
> So How the conversation history is constructed now? And what can you suggest or recommend
> to how the user feels his past conversations, or the choice to continue last conversation.
> Please analyze the structure based on the current database and application and give me best
> answer to match our conversation application.

---

## How conversation history is structured today

### Database (backend)

Two entities drive conversations:

**`ConversationSessionEntity`** — one row per conversation attempt:

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | Primary key |
| `user_id` | uuid | Owner |
| `scenario_id` | uuid \| null | The scenario played (null = free talk) |
| `persona_id` | uuid | Which tutor was used |
| `mode` | `chat` \| `face` | Text or voice/face mode |
| `status` | `active` \| `completed` \| `abandoned` | Lifecycle state |
| `started_at` | timestamp | Session creation time |
| `ended_at` | timestamp \| null | Set by `POST /sessions/:id/end` |
| `turn_count` | int | Incremented on every user message |
| `word_count` | int | Running sum of user words spoken |
| `xp_earned` | int | Computed at end, capped by scenario `xp_reward` |

**`ConversationMessageEntity`** — one row per chat turn:

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | |
| `session_id` | uuid | Foreign key → session |
| `role` | `user` \| `assistant` | Who spoke |
| `content` | text | The message text |
| `sequence` | int | 0-based ordering within the session |
| `audio_url` | text \| null | TTS audio link if generated |
| `created_at` | timestamp | |

### The gap — why history felt invisible

The root cause of "conversation begins with new context" was three-fold:

1. **`GET /conversations/sessions` had no filters** — it returned all sessions for the user ordered by date, with no `scenarioId` or `status` filter. The app couldn't efficiently ask "is there an unfinished session for *this* scenario?".

2. **`_startSession` always created a new session** — `scenario_brief_screen.dart` called `startSession(...)` unconditionally with no check for an existing active session.

3. **No UI signal** — the brief screen showed no banner telling the user "you were here before".

---

## What was implemented

### Backend — `GET /conversations/sessions` now accepts filters

**`backend/src/conversations/conversations.module.ts`**

```ts
@Get('sessions')
list(
  @CurrentUser() user: JwtPayload,
  @Query('limit') limit?: string,
  @Query('scenarioId') scenarioId?: string,   // NEW
  @Query('status') status?: string,            // NEW
) {
  return this.svc.listForUser(user.sub, limit ? parseInt(limit, 10) : 50, scenarioId, status);
}
```

**`backend/src/conversations/conversations.service.ts`**

```ts
async listForUser(userId, limit = 50, scenarioId?, status?): Promise<SessionDto[]> {
  const rows = await this.sessions.find({
    where: {
      user_id: userId,
      ...(scenarioId ? { scenario_id: scenarioId } : {}),
      ...(status ? { status } : {}),
    },
    order: { started_at: 'DESC' },
    take: limit,
  });
  return rows.map((s) => this.toSessionDto(s));
}
```

Now the mobile app (and any future admin feature) can call:

```
GET /conversations/sessions?scenarioId=<id>&status=active&limit=1
```

### Flutter API layer — `ConversationsApi.listSessions`

**`flutter_app/lib/core/api/app_apis.dart`**

```dart
Future<List<Map<String, dynamic>>> listSessions({
  int? limit,
  String? scenarioId,   // NEW
  String? status,       // NEW
}) async {
  final res = await _dio.get<List<dynamic>>(
    '/conversations/sessions',
    queryParameters: <String, Object?>{
      'limit': limit,
      'scenarioId': scenarioId,
      'status': status,
    }..removeWhere((_, v) => v == null),
  );
  return res.data!.cast<Map<String, dynamic>>();
}
```

### Flutter UI — scenario brief screen gains "Continue" flow

**`flutter_app/lib/features/scenarios/scenario_brief_screen.dart`**

**New provider** — fetches the most recent active session for this scenario:

```dart
final _activeSessionProvider =
    FutureProvider.family<ConversationSession?, String>((ref, scenarioId) async {
  final raw = await ref.read(conversationsApiProvider).listSessions(
        scenarioId: scenarioId, status: 'active', limit: 1);
  if (raw.isEmpty) return null;
  return ConversationSession.fromJson(raw.first);
});
```

**`_ContinueBanner`** — shown at the top of the brief's scrollable content when an active session exists:

```
┌─────────────────────────────────────────────┐
│ ⟳  Unfinished conversation                  │
│    5 turns · started 3m ago                 │
└─────────────────────────────────────────────┘
```

**`_ContinueDock`** — replaces the normal bottom dock when an active session exists:

```
┌──────────────────────────────────────────────┐
│  ▶  Continue conversation           [full-w] │
│  Back          Start fresh (5m)              │
└──────────────────────────────────────────────┘
```

- **Continue** → `context.pushReplacement(AppRoute.conversation(activeSession.id))` — resumes the existing session with full message history.
- **Start fresh** → calls `endSession(status: 'abandoned')` on the old session, then creates a new one normally.
- **Back** → pops to the scenarios list.

**`_startFresh` method** abandons the old session gracefully before creating a new one. If the abandon call fails (e.g. the device is offline), it proceeds anyway — the old session stays as `active` on the server but the user gets their new session.

---

## Files changed

| File | Change |
|------|--------|
| [backend/src/conversations/conversations.module.ts](../../backend/src/conversations/conversations.module.ts) | Added `scenarioId` and `status` `@Query` params to `GET /sessions` controller |
| [backend/src/conversations/conversations.service.ts](../../backend/src/conversations/conversations.service.ts) | Updated `listForUser` signature to accept optional `scenarioId` and `status` filters |
| [flutter_app/lib/core/api/app_apis.dart](../../flutter_app/lib/core/api/app_apis.dart) | Added `scenarioId` and `status` params to `ConversationsApi.listSessions` |
| [flutter_app/lib/features/scenarios/scenario_brief_screen.dart](../../flutter_app/lib/features/scenarios/scenario_brief_screen.dart) | Added `_activeSessionProvider`, `_ContinueBanner`, `_ContinueDock`, `_startFresh` |
