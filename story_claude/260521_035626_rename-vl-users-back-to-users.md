# Follow-up migration: rename `vl_users` back to `users`

## What this task did

Added `backend/src/database/migrations/1780600000000-rename-vl-users-back-to-users.ts`
to bring already-migrated environments back into sync with the
reverted entity.

Sequence of events:

1. Commit `6602460` shipped a rename migration (`users` → `vl_users`)
   plus the matching entity edit.
2. User ran the migration locally — DB now has `vl_users`.
3. User asked to revert the change. Commit `4a049f9` reverted the
   entity edit and deleted the migration file from disk.
4. After the revert the entity expects `users`, but the live DB still
   has `vl_users` — TypeORM would fail on first query.

The new migration's `up()` runs
`ALTER TABLE IF EXISTS "vl_users" RENAME TO "users"`. `IF EXISTS`
makes it idempotent: on a DB that never saw the original rename
(fresh seed, CI, teammates who didn't pull `6602460`) it's a no-op.

## Conversation summary

- Followed the user's "revert" with a "yes I already ran it" so we
  know the DB diverged from code.
- Decided to fix this with a forward-rolling migration instead of
  asking the user to manually `psql` or run a `down()` on the
  deleted migration.
- Used `IF EXISTS` guards so the migration is safe to ship to
  teammates whose DBs were never in the `vl_users` state.

## Decisions / call-outs

- **Forward migration, not a `down()` of the deleted migration.**
  Running `down()` on a migration whose file is no longer in the
  source tree is fragile (TypeORM matches by class name) and would
  leave an orphan migrations-table row regardless. Cleaner to ship
  a brand new migration with `IF EXISTS` semantics.
- **Did not clean up the orphan migrations-table row** for
  `RenameUsersToVlUsers1780500000000`. TypeORM only checks that
  *listed* migrations have rows; orphan rows from deleted migrations
  are inert dead weight. If we ever cared we could
  `DELETE FROM migrations WHERE name LIKE 'RenameUsersToVlUsers%'`,
  but it's not load-bearing.
- **Down direction is the reverse rename.** Symmetric, also
  `IF EXISTS`-guarded for safety.

## User prompt (verbatim)

> yes i already run the migration
