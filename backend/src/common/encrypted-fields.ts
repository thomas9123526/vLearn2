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
 * │ vl_user_info      │ email                │ Primary identifier (PII)       │
 * │ vl_user_info      │ license_machine_id   │ Device fingerprint             │
 * │ vl_user_info      │ license_serial       │ License credential             │
 * │ vl_user_info      │ suspended_reason     │ Internal moderation note       │
 * └───────────────────┴──────────────────────┴────────────────────────────────┘
 *
 * Note: users.name / users.license_* columns are NOT encrypted — the users
 * table is shared with other systems and must remain plain-text.
 *
 * Entity files:
 *   backend/src/database/entities/user-info.entity.ts  — all encrypted fields
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
  { table: 'vl_user_info', column: 'email',              entity: 'UserInfoEntity', reason: 'Primary identifier (PII)' },
  { table: 'vl_user_info', column: 'license_machine_id', entity: 'UserInfoEntity', reason: 'Device fingerprint' },
  { table: 'vl_user_info', column: 'license_serial',     entity: 'UserInfoEntity', reason: 'License credential' },
  { table: 'vl_user_info', column: 'suspended_reason',   entity: 'UserInfoEntity', reason: 'Internal moderation note' },
] as const;
