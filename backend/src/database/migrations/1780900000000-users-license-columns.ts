import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Adds per-user license state to the `users` table.
 *
 *   license_valid_until  — null = no license; far-future = permanent license.
 *   license_machine_id   — the device fingerprint the cert was bound to.
 *   license_serial       — the cert serial number, for audit cross-reference
 *                          with vLearnLicense.generate_log.
 */
export class UsersLicenseColumns1780900000000 implements MigrationInterface {
  public async up(qr: QueryRunner): Promise<void> {
    await qr.query(
      `ALTER TABLE users
         ADD COLUMN IF NOT EXISTS license_valid_until  TIMESTAMPTZ,
         ADD COLUMN IF NOT EXISTS license_machine_id   TEXT,
         ADD COLUMN IF NOT EXISTS license_serial       TEXT`,
    );
    await qr.query(
      `CREATE INDEX IF NOT EXISTS idx_users_license_machine_id
         ON users (license_machine_id)
         WHERE license_machine_id IS NOT NULL`,
    );
  }

  public async down(qr: QueryRunner): Promise<void> {
    await qr.query(
      `DROP INDEX IF EXISTS idx_users_license_machine_id`,
    );
    await qr.query(
      `ALTER TABLE users
         DROP COLUMN IF EXISTS license_serial,
         DROP COLUMN IF EXISTS license_machine_id,
         DROP COLUMN IF EXISTS license_valid_until`,
    );
  }
}
