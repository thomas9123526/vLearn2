# Conversation - Move license fields to vl_user_info remove users encryption

| Field | Value |
|---|---|
| Saved | 2026-06-02 08:11:25 |
| Commit | refactor: move license fields to vl_user_info, remove encryption from users table |
| Project | C:\project\vLearn2 |

---

## User

I want know the current table's fields that is on for encryption.
And I don't want encryption for users table.
And I want move license_valid_until, license_machine_id, license_serial, license_platform of users to vl_user_info.
And I dont' want modify users table schema because we might use the users table globally with other system.

## Assistant

**Before (encrypted fields):**
- `users.name`
- `users.license_machine_id`
- `users.license_serial`
- `vl_user_info.email`
- `vl_user_info.suspended_reason`

**After (encrypted fields):**
- `vl_user_info.email`
- `vl_user_info.license_machine_id`
- `vl_user_info.license_serial`
- `vl_user_info.suspended_reason`

**Changes made:**
1. `user.entity.ts` — removed `encryptedFieldTransformer` from `name`; removed all 4 license `@Column` decorators (physical columns kept in DB, comment explains why)
2. `user-info.entity.ts` — added `license_valid_until`, `license_machine_id` (encrypted), `license_serial` (encrypted), `license_platform`
3. `encrypted-fields.ts` — updated catalog to reflect new state
4. `license.module.ts` — swapped `usersRepo` → `userInfoRepo`, changed `.where('id = :id')` → `.where('user_id = :id')`, swapped `TypeOrmModule.forFeature` entity
5. `admin-users.controller.ts` — changed `i.user.license_*` → `i.license_*` in both list and detail endpoints
6. `admin-stats.controller.ts` — SQL now joins `vl_user_info` instead of `users` for `license_platform`
7. New migration `1781600000000-vl-user-info-license-columns.ts` — ADDs 4 columns to `vl_user_info`

---

## Prompt

I want know the current table's fields that is on for encryption.
And I don't want encryption for users table.
And I want move license_valid_until license_machine_id license_serial license_platform of users to vl_user_info.
And I dont' want modify users table schema because we might use the users table globally with other system.
