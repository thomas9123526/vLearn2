# what is the encryption fields now and how can i add or remove for encrypt certai

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-01T16:59:33.599Z

## User

what is the encryption fields now and how can i add or remove for encrypt certain fields.

## Assistant

Here's the current picture:

---

## Currently encrypted fields

| Table | Field | Entity |
|---|---|---|
| `users` | `name` | `UserEntity` |
| `users` | `license_machine_id` | `UserEntity` |
| `users` | `license_serial` | `UserEntity` |
| `vl_user_info` | `email` | `UserInfoEntity` |
| `vl_user_info` | `suspended_reason` | `UserInfoEntity` |

---

## How it works

[backend/src/common/field-encryption.ts](backend/src/common/field-encryption.ts) exports `encryptedFieldTransformer`. It's applied via the TypeORM `transformer:` option on any `@Column`.

```ts
// field-encryption.ts — AES-256-CBC, key from DB_FIELD_ENCRYPTION_KEY env var
export const encryptedFieldTransformer = {
  to: (plain) => encryptField(plain),   // called before writing to DB
  from: (stored) => decryptField(stored), // called after reading from DB
};
```

The IV is derived deterministically (HMAC-SHA256 of key+plaintext), so `UNIQUE` indexes still work.

---

## Adding encryption to a field

1. Open the entity file and add `transformer: encryptedFieldTransformer` to the column:

```ts
// e.g. in user-info.entity.ts
import { encryptedFieldTransformer } from '../../common/field-encryption';

@Column({ type: 'text', nullable: true, transformer: encryptedFieldTransformer })
phone_number: string | null;
```

2. Update the docs array in [backend/src/common/encrypted-fields.ts](backend/src/common/encrypted-fields.ts) (used for auditing/migration):

```ts
export const ENCRYPTED_FIELDS = [
  // ... existing ...
  { table: 'vl_user_info', column: 'phone_number' },
];
```

3. **Migrate existing data** — any existing plain-text rows won't be auto-encrypted. Run a one-off migration script to re-save each row so TypeORM's `to()` transformer fires.

---

## Removing encryption from a field

1. **Migrate first** — decrypt all existing stored values back to plain text in a migration script, otherwise the raw `iv:ciphertext` strings will be left in the column.
2. Remove `transformer: encryptedFieldTransformer` from the `@Column` decorator.
3. Remove the entry from `ENCRYPTED_FIELDS`.

---

**Important:** `DB_FIELD_ENCRYPTION_KEY` must be set in `.env` (32+ character secret). Without it, `encryptField` will throw at runtime.
