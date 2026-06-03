import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Adds license columns to vl_user_info.
 *
 * License data is now owned by vl_user_info instead of users so that the
 * users table can remain unchanged for cross-system compatibility.
 * The physical columns on users (license_valid_until, license_machine_id,
 * license_serial, license_platform) are intentionally NOT dropped.
 */
export class VlUserInfoLicenseColumns1781600000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE vl_user_info
        ADD COLUMN IF NOT EXISTS license_valid_until  TIMESTAMPTZ NULL,
        ADD COLUMN IF NOT EXISTS license_machine_id   TEXT        NULL,
        ADD COLUMN IF NOT EXISTS license_serial       TEXT        NULL,
        ADD COLUMN IF NOT EXISTS license_platform     TEXT        NULL;
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE vl_user_info
        DROP COLUMN IF EXISTS license_valid_until,
        DROP COLUMN IF EXISTS license_machine_id,
        DROP COLUMN IF EXISTS license_serial,
        DROP COLUMN IF EXISTS license_platform;
    `);
  }
}
