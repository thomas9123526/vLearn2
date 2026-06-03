/**
 * Canonical list of AES-256-CBC encrypted database fields.
 *
 * Algorithm: AES-256-CBC, deterministic IV (HMAC-SHA256 of key+plaintext).
 * Key source: DB_FIELD_ENCRYPTION_KEY env var (first 32 UTF-8 bytes).
 * When the key is absent the transformer is a no-op (plain text stored).
 *
 * Table            | Column               | Entity field
 * -----------------|----------------------|---------------------------------
 * users            | name                 | UserEntity.name
 * users            | license_serial       | UserEntity.license_serial
 * users            | license_machine_id   | UserEntity.license_machine_id
 * vl_user_info     | email                | UserInfoEntity.email
 * vl_user_info     | suspended_reason     | UserInfoEntity.suspended_reason
 *
 * Implementation: backend/src/common/field-encryption.ts
 *
 * Notes:
 * - Deterministic IV means UNIQUE indexes remain valid (same input → same ciphertext).
 * - Admin panel email search uses exact match (encrypted query) instead of ILIKE.
 * - Partial-text search on encrypted columns is not supported.
 */
export const ENCRYPTED_FIELDS = [
  { table: 'users',        column: 'name',               entity: 'UserEntity.name' },
  { table: 'users',        column: 'license_serial',     entity: 'UserEntity.license_serial' },
  { table: 'users',        column: 'license_machine_id', entity: 'UserEntity.license_machine_id' },
  { table: 'vl_user_info', column: 'email',              entity: 'UserInfoEntity.email' },
  { table: 'vl_user_info', column: 'suspended_reason',   entity: 'UserInfoEntity.suspended_reason' },
] as const;
