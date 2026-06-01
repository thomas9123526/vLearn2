/**
 * Canonical list of encrypted database fields.
 *
 * Table            | Column                | Entity field
 * -----------------|-----------------------|-----------------------
 * users            | license_serial        | UserEntity.license_serial
 * users            | license_machine_id    | UserEntity.license_machine_id
 * vl_user_info     | suspended_reason      | UserInfoEntity.suspended_reason
 *
 * Encryption: AES-256-GCM, key from FIELD_ENCRYPTION_KEY env var.
 * When the key is absent the transformer is a no-op (plain text stored).
 * See field-encryption.transformer.ts for format details.
 */
export const ENCRYPTED_FIELDS = [
  { table: 'users',        column: 'license_serial',    entity: 'UserEntity.license_serial' },
  { table: 'users',        column: 'license_machine_id', entity: 'UserEntity.license_machine_id' },
  { table: 'vl_user_info', column: 'suspended_reason',  entity: 'UserInfoEntity.suspended_reason' },
] as const;
