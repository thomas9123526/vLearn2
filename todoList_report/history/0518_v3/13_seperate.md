# Task Report: 13_seperate — Extract vl_user_info from users

**Date:** 2026-05-19  
**Commit:** `faed513`  
**Branch:** `dev`

---

## Task Description

Extract 16 fields from the `users` table and store them in a new `vl_user_info` table (1:1 relationship).

Fields extracted:
`email`, `avatar_emoji`, `native_language`, `ui_language`, `current_level`, `xp_total`, `streak_days`, `last_active_date`, `active_persona_id`, `active_theme`, `onboarding_done`, `role`, `status`, `suspended_until`, `suspended_reason`, `leaderboard_opt_in`

---

## What Was Done

### 1. New entity — `UserInfoEntity`
**File:** `backend/src/database/entities/user-info.entity.ts`

- Table `vl_user_info` with `user_id uuid PRIMARY KEY`
- FK → `users.id ON DELETE CASCADE`
- Holds all 16 extracted columns with original defaults
- `@Index({ unique: true })` on `email`
- Class-level `@Index(['xp_total'])` and `@Index(['streak_days'])` for leaderboard queries
- `@OneToOne(() => UserEntity, u => u.info, { onDelete: 'CASCADE' })`

### 2. Updated `UserEntity`
**File:** `backend/src/database/entities/user.entity.ts`

Removed 16 extracted columns. Added:
```typescript
@OneToOne(() => UserInfoEntity, (i) => i.user, { eager: true, cascade: ['insert', 'update'] })
info!: UserInfoEntity;
```
`eager: true` means any `findOne` on `UserEntity` automatically loads its `UserInfoEntity`. `cascade` means saving a user also saves its info row.

`users` table now holds only: `id`, `password_hash`, `name`, `cid`, `cid_username`, `gender`, `created_at`, `updated_at`.

### 3. Migration `1780000000000-extract-vl-user-info.ts`

**up():**
1. `CREATE TABLE vl_user_info` with PK + FK
2. Create unique index on `email`, perf indexes on `xp_total` / `streak_days`
3. `INSERT INTO vl_user_info SELECT ... FROM users ON CONFLICT DO NOTHING` (safe for empty/populated tables)
4. `ALTER TABLE users DROP COLUMN IF EXISTS` × 16

**down():**
1. Add columns back to `users`
2. `UPDATE users SET ... FROM vl_user_info WHERE user_id = id`
3. Re-apply `NOT NULL` on `email`, restore unique index
4. `DROP TABLE vl_user_info`

### 4. Service & controller updates

All moved-field accesses updated to go through `user.info.*`. API response JSON shapes are **unchanged** — no Flutter or admin-panel client changes needed.

| File | Change |
|------|--------|
| `auth.service.ts` | Sign-up creates `UserInfoEntity` via cascade; sign-in finds by `userInfos.findOne({ email })` first, then loads `UserEntity` by id |
| `auth.module.ts` | Added `UserInfoEntity` to `forFeature` |
| `users.service.ts` | `toProfile` and `updateProfile` use `user.info.*` for moved fields |
| `users.module.ts` | Added `UserInfoEntity` to `forFeature` |
| `admin-users.controller.ts` | Queries `userInfos` repo with `leftJoinAndSelect('i.user', 'u')`; suspend/restore operate on `UserInfoEntity` |
| `admin-leaderboard.controller.ts` | Queries `userInfos` repo with join; all leaderboard fields come from `i.*` |
| `admin-stats.controller.ts` | Counts on `userInfos` repo; `last_active_date` filter on `i.last_active_date` |
| `admin.module.ts` | Added `UserInfoEntity` to `forFeature` |
| `conversations.service.ts` | `user.current_level` → `user.info.current_level`, `user.native_language` → `user.info.native_language` |
| `entities/index.ts` | Exports `UserInfoEntity`, added to `ALL_ENTITIES` |

### 5. Migration result

```
Migration ExtractVlUserInfo1780000000000 has been executed successfully.
```

### 6. TypeScript build

```
npx tsc --noEmit  →  (no output = zero errors)
```

---

## Architecture Notes

- `vl_user_info.user_id` is both the PK and the FK — a shared-primary-key 1:1 pattern. No surrogate key needed.
- Eager loading keeps consumer code simple (`user.info.email` works everywhere without explicit joins).
- The `ON DELETE CASCADE` constraint means deleting a row from `users` automatically deletes its `vl_user_info` row.
- `role` and `status` are now in `vl_user_info`, so admin role/status queries target that table. JWT tokens still carry `role` in the payload (populated at sign-in from `user.info.role`).
