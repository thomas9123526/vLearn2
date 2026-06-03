# Conversation - Fix deleteAllSessions 500 missing In operator

| Field | Value |
|---|---|
| Saved | 2026-06-01 21:05:15 |
| Commit | fix: use TypeORM In() in deleteAllSessions to fix 500 on clear-all |
| Project | C:\project\vLearn2 |

---

## User

```
→ DELETE http://localhost:5101/api/conversations/sessions
X 500 DELETE http://localhost:5101/api/conversations/sessions
   response body: {statusCode: 500, message: Internal server error}
[history.clear_all] DioException [bad response]: Internal server error
Error: ApiException(500): Internal server error
```

## Assistant

Root cause: `deleteAllSessions` in `conversations.service.ts` passed plain arrays to TypeORM's
`.delete()` method without the `In()` operator:

```typescript
.delete({ session_id: sessionIds as any })   // wrong — generates invalid SQL
```

TypeORM 0.3+ `.delete()` does not automatically convert array values to `IN` clauses; `In()` from
`typeorm` must be used explicitly. The `as any` cast was masking the type error.

Fix: imported `In` from `typeorm` and replaced all three `.delete()` calls to use `In(sessionIds)`.

---

## Prompt

```
→ DELETE http://localhost:5101/api/conversations/sessions
X 500 DELETE http://localhost:5101/api/conversations/sessions
   response body: {statusCode: 500, message: Internal server error}
[history.clear_all] DioException [bad response]: Internal server error
Error: ApiException(500): Internal server error
```
