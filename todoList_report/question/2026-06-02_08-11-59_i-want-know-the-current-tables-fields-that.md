# I want know the current table's fields that is on for encryption. And I don't wa

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-01T23:11:59.211Z

## User

I want know the current table's fields that is on for encryption.
And I don't want encryption for users table.
And I want move license_valid_until
license_machine_id
license_serial
license_platform of users to vl_user_info.
And I dont' want modify users table schema because we might use the users table globally with other system.

## Assistant

Let me read the relevant entity files first.

## Assistant

Let me find all code that reads the license fields from `UserEntity` before I plan the changes:

## Assistant

Good — `synchronize: false` so I need to write a migration. Let me read the files that need updating:

## Assistant

Now I have everything I need. Here's the full set of changes:

**Summary of what changes:**
- `users` table physical columns stay untouched
- `UserEntity`: remove encryption from `name`, remove the 4 license column mappings  
- `UserInfoEntity`: add the 4 license columns (with encryption on `machine_id` + `serial`)
- `LicenseService`: swap `usersRepo` for `userInfoRepo`, update the write target
- `admin-users.controller.ts`: read license fields from `i` instead of `i.user`
- `admin-stats.controller.ts`: SQL joins `vl_user_info` instead of `users`
- New migration adds 4 columns to `vl_user_info`

## Assistant

Now update `encrypted-fields.ts`:

## Assistant

Now update `license.module.ts` to write to `vl_user_info` via `UserInfoEntity`:

## Assistant

Now find and update the module's `TypeOrmModule.forFeature` to swap `UserEntity` for `UserInfoEntity`:

## Assistant

Now update the admin users controller reads:

## Assistant

Now fix the raw SQL in the stats controller:

## Assistant

Now write the migration:

## Assistant

Now commit and story:

## Assistant

Done. Here's what changed:

**Encrypted fields — before → after:**

| Table | Column | Before | After |
|---|---|---|---|
| `users` | `name` | encrypted | plain |
| `users` | `license_machine_id` | encrypted | unmapped (physical col kept) |
| `users` | `license_serial` | encrypted | unmapped (physical col kept) |
| `vl_user_info` | `email` | encrypted | encrypted |
| `vl_user_info` | `suspended_reason` | encrypted | encrypted |
| `vl_user_info` | `license_machine_id` | — | **new, encrypted** |
| `vl_user_info` | `license_serial` | — | **new, encrypted** |
| `vl_user_info` | `license_valid_until` | — | **new, plain** |
| `vl_user_info` | `license_platform` | — | **new, plain** |

**After deploying, run the migration:**
```bash
npx typeorm migration:run -d src/database/data-source.ts
```

The old `users.license_*` columns remain in the database untouched — they just aren't read or written by this app anymore.
