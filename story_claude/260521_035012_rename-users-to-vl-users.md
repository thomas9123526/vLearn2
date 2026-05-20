# Rename `users` → `vl_users` for naming-prefix consistency

## What this task did

Brought the `users` table into line with the `vl_` prefix convention
that every other application table already uses. Two changes:

1. **New migration** `backend/src/database/migrations/1780500000000-rename-users-to-vl-users.ts`
   — runs `ALTER TABLE IF EXISTS "users" RENAME TO "vl_users"` on
   `up()` and the reverse on `down()`.
2. **Entity decorator update** in
   `backend/src/database/entities/user.entity.ts:14`: `@Entity({ name:
   'users' })` → `@Entity({ name: 'vl_users' })`.

That's the entire live-code surface. Confirmed by grepping
`backend/src/` for raw-SQL references to a bare `users` table — the
only hits are in **historical migrations** (`1715800000000-initial-schema.ts`,
`1716000000000-news-tables.ts`, `1779100000000-admins-separate-table.ts`,
`1779700000000-users-gender.ts`, `1779900000000-users-name-cid.ts`,
`1780000000000-extract-vl-user-info.ts`, `1780200000000-cid-username-length.ts`).
Those must stay unchanged so the migration history replays correctly
from a fresh DB — each of them runs **before** our new rename, so the
sequence is internally consistent.

Foreign-key references from peer tables (`vl_user_info.user_id`,
`vl_refresh_tokens.user_id`, `vl_skill_snapshots.user_id`,
`vl_admin_audit_log.user_id`, …) keep working without changes:
Postgres tracks FK targets by OID, not by table name, so `ALTER TABLE
… RENAME TO …` is transparent to them.

Backend `tsc --noEmit` is clean. The pre-existing lint errors in
`auth/auth.controller.spec.ts` and `test/app.e2e-spec.ts` are unrelated
to this change.

## Conversation summary

- User pointed out that `users` is the only table without the `vl_`
  prefix and asked why.
- Confirmed via grep: 24 entities use `vl_`, one (`users`) doesn't.
  Traced to migration `1779800000000-add-vl-prefix.ts`, which renamed
  every other table but skipped `users` (probably caution about
  renaming the main entity).
- User said yes to finishing the job. I added a follow-up migration
  and updated the entity decorator.
- Verified there are no live raw-SQL references to bare `users` —
  only historical migrations, which must stay unchanged.

## Decisions / call-outs

- **Did not edit historical migrations.** They reference `"users"` in
  CREATE/ALTER/REFERENCES clauses by design. Migrations run in order;
  each pre-existing one creates or operates on `users`, then ours
  renames it last. Replay from a fresh DB still works.
- **Did not rename indexes / constraints** (`idx_users_*`,
  `chk_users_role`, `uniq_one_superadmin`). Postgres keeps them
  pointed at the renamed table; their names are cosmetic. The original
  `1779800000000-add-vl-prefix.ts` made the same call for its 22
  renames, so we keep the codebase consistent with that policy.
- **Did not rename the REST URL `@Controller('users')`.** The URL path
  and the DB table name are independent — Flutter consumes
  `/api/users/profile`, and changing the public API surface would be a
  breaking client change for no schema benefit.
- **Did not rename `users.*` permission keys** in
  `admin/permissions/catalog.ts`. Those are a separate namespace and
  used in stored audit log rows; changing them would orphan history.
- **Single-statement migration, idempotent via `IF EXISTS`.** Safe to
  run on a DB that's already had it applied (no-op), and safe to roll
  back via `down()`.

## User prompt (verbatim)

> yes
