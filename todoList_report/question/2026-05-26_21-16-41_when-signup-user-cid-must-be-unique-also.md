# when signup user, cid must be unique. also there can be one cid username for a g

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-26T12:16:41.795Z

## User

when signup user, cid must be unique.
also there can be one cid username for a given cid number.

## Assistant

Let me look at the current `users` table schema and the signup/auth code to understand the `cid` fields.

## Assistant

Now let me check the UserEntity and the latest migration number.

## Assistant

Clear picture. I need three changes:
1. **Migration** — add a partial unique index on `cid` (where not null)
2. **UserEntity** — add `unique: true` on the `cid` column
3. **auth.service.ts** `signUp` — check for duplicate `cid` and throw a readable error before the DB does it

## Assistant

Now update `UserEntity` to reflect the uniqueness:

## Assistant

Now update `signUp` to check for duplicate `cid` and give a clear error:

## Assistant

Now apply the migration to the running DB:

## Assistant

Migration applied. Now commit everything:

## Assistant

Done. Three changes, all live:

| Layer | Change |
|---|---|
| DB | Partial unique index `uq_users_cid ON users(cid) WHERE cid IS NOT NULL` — already applied |
| [user.entity.ts](backend/src/database/entities/user.entity.ts:25) | `cid` column now `unique: true` |
| [auth.service.ts](backend/src/auth/auth.service.ts:46) | `signUp` checks both `cid_username` and `cid` in parallel; returns `auth.cid_already_registered` on duplicate CID |

The partial index (`WHERE cid IS NOT NULL`) means users who registered without a CID (null) are unaffected — only rows with an actual CID value enforce uniqueness.
