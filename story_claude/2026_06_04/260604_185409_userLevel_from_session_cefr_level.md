# Conversation - userLevel always from session.cefr_level

| Field | Value |
|---|---|
| Saved | 2026-06-04 18:54:09 |
| Commit | auto: use session.cefr_level as authoritative userLevel in orchestrator calls |
| Project | C:\project\vLearn2 |

---

## User

on conversations.service.ts, userLevel must be session.cefr_level and session.cefr_level must have value.

## Assistant

`start()` already always sets `session.cefr_level` (from `dto.cefrLevel ?? user.current_level ?? 1`), so the fallback to `user.info.current_level` in `sendMessage` and `suggestNextLine` was dead code.

Changed both call sites from `session.cefr_level ?? user.info.current_level` to `session.cefr_level ?? 1`. The `?? 1` is a type-safety guard only (the entity column is declared `number | null` for DB backward compat); in practice the value is always set at session creation time.

---

## Prompt

on conversations.service.ts, userLevel must be session.cefr_level and session.cefr_level must have value.
