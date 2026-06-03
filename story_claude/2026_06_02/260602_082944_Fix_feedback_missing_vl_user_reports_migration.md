# Conversation - Fix feedback missing vl_user_reports migration

| Field | Value |
|---|---|
| Saved | 2026-06-02 08:29:44 |
| Commit | fix: add missing migration to create vl_user_reports table |
| Project | C:\project\vLearn2 |

---

## User

I tried to send feedback from application, and it fails

## Assistant

Root cause: `UserReportEntity` maps to `vl_user_reports` but no migration ever created that
table. With `synchronize: false`, TypeORM never auto-creates it, so every `POST /users/report`
throws "relation does not exist" at the database layer.

Fix: added migration `1781700000000-vl-user-reports-table.ts` that creates the table with all
columns and the two composite indexes that match the entity's `@Index` decorators.

Run `npx typeorm migration:run -d src/database/data-source.ts` to apply.

---

## Prompt

I tried to send feedback from application, and it fails
