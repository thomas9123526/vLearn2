# so, where can i modify encryption fields?

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-01T23:20:59.058Z

## User

so, where can i modify encryption fields?

## Assistant

[backend/src/common/encrypted-fields.ts](backend/src/common/encrypted-fields.ts) is the catalog (documentation only), but the **actual** encryption is controlled by the `transformer:` option on individual `@Column` decorators in the entity files.

**To add encryption to a field:**
```ts
// in user-info.entity.ts (or any entity)
@Column({ type: 'text', nullable: true, transformer: encryptedFieldTransformer })
phone_number!: string | null;
```

**To remove encryption from a field:**
```ts
// just remove the transformer: option
@Column({ type: 'text', nullable: true })
phone_number!: string | null;
```

**Then update the catalog** in [backend/src/common/encrypted-fields.ts](backend/src/common/encrypted-fields.ts) to match — it's only used for documentation/auditing, not by runtime code.

**Currently encrypted columns (the ones with `transformer: encryptedFieldTransformer`):**

| File | Field |
|---|---|
| [user-info.entity.ts:25](backend/src/database/entities/user-info.entity.ts#L25) | `email` |
| [user-info.entity.ts:81](backend/src/database/entities/user-info.entity.ts#L81) | `suspended_reason` |
| [user-info.entity.ts](backend/src/database/entities/user-info.entity.ts) | `license_machine_id` |
| [user-info.entity.ts](backend/src/database/entities/user-info.entity.ts) | `license_serial` |

All in `UserInfoEntity` — `users` table has no encrypted fields anymore.
