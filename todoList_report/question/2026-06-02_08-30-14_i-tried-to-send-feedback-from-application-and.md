# I tried to send feedback from application , and it fails

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-01T23:30:14.512Z

## User

I tried to send feedback from application , and it fails

## Assistant

Let me find the feedback feature code.

## Assistant

Found it. The `vl_user_reports` table has **no migration** — the entity was added but the `CREATE TABLE` was never written. Since `synchronize: false`, TypeORM won't create it automatically, so every `POST /users/report` crashes with a "relation does not exist" error.

## Assistant

The `UserReportEntity` existed but the `CREATE TABLE` migration was never written — the table simply didn't exist in the database.

Run the pending migrations to fix it:

```bash
cd backend
npx typeorm migration:run -d src/database/data-source.ts
```

This will apply both the new `vl_user_reports` table and the `vl_user_info` license columns from the previous change in one go.
