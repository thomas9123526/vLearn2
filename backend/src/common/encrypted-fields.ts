/**
 * Catalog of database columns that are encrypted at rest via AES-256-CBC.
 *
 * Encryption is applied by TypeORM column transformers in the entity files
 * listed below. The encryption key is read from the DB_FIELD_ENCRYPTION_KEY
 * environment variable (first 32 UTF-8 bytes).
 *
 * ┌───────────────────┬──────────────────────┬────────────────────────────────┐
 * │ Table             │ Column               │ Reason                         │
 * ├───────────────────┼──────────────────────┼────────────────────────────────┤
 * │ users             │ name                 │ PII — display name             │
 * │ users             │ license_machine_id   │ Device fingerprint             │
 * │ users             │ license_serial       │ License credential             │
 * │ vl_user_info      │ email                │ Primary identifier (PII)       │
 * └───────────────────┴──────────────────────┴────────────────────────────────┘
 *
 * Entity files:
 *   backend/src/database/entities/user.entity.ts       — name, license_*
 *   backend/src/database/entities/user-info.entity.ts  — email
 *
 * Search constraints:
 *   • Deterministic encryption (HMAC-derived IV) means UNIQUE indexes work.
 *   • ILIKE / substring search on encrypted columns is not supported.
 *     The admin Users list falls back to exact-match on encrypted email.
 *     If case-insensitive search is required in the future, maintain a
 *     separate `email_hash` column (HMAC-SHA256 of lowercased email).
 *
 * Migration (encrypting existing rows):
 *   Run `npx ts-node scripts/encrypt-existing-fields.ts` after setting
 *   DB_FIELD_ENCRYPTION_KEY. The script reads every row, writes it back
 *   (the transformer encrypts on write), then verifies the round-trip.
 *   Safe to re-run: already-encrypted rows pass through decryptField()
 *   unchanged because decryptField() skips values without the ':' separator.
 *
 * Key rotation:
 *   1. Decrypt all rows with OLD_KEY.
 *   2. Set DB_FIELD_ENCRYPTION_KEY to the new key.
 *   3. Re-run the migration script to re-encrypt with the new key.
 */

export const ENCRYPTED_FIELDS = [
  { table: 'users',        column: 'name',               entity: 'UserEntity',     reason: 'PII — display name' },
  { table: 'users',        column: 'license_machine_id', entity: 'UserEntity',     reason: 'Device fingerprint' },
  { table: 'users',        column: 'license_serial',     entity: 'UserEntity',     reason: 'License credential' },
  { table: 'vl_user_info', column: 'email',              entity: 'UserInfoEntity', reason: 'Primary identifier (PII)' },
] as const;
