# cid username must be also unique for users.

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-26T12:17:50.714Z

## User

cid username must be also unique for users.

## Assistant

The migration already created `uq_users_cid_username` — let me verify it's actually live in the DB and that the entity reflects it.

## Assistant

The DB index already exists (`uq_users_cid_username`) and `signUp` already checks for it. The only gap is the entity column isn't marked `unique: true`. One-line fix:

## Assistant

Done. The uniqueness was already enforced at two levels — the DB index (`uq_users_cid_username WHERE cid_username IS NOT NULL`) and the application check in `signUp`. The entity decorator just wasn't aligned. All three layers now consistent.
