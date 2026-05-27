import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Adds `license_platform` to `users` so the admin panel can show
 * what kind of device each user activated their license from
 * (e.g. "android", "windows"). Client-reported and trust-on-write
 * — fine for "show in the admin Users list / segment by platform",
 * not fine for security decisions.
 */
export class UsersLicensePlatform1781100000000 implements MigrationInterface {
  public async up(qr: QueryRunner): Promise<void> {
    await qr.query(
      `ALTER TABLE users
         ADD COLUMN IF NOT EXISTS license_platform TEXT`,
    );
  }

  public async down(qr: QueryRunner): Promise<void> {
    await qr.query(
      `ALTER TABLE users DROP COLUMN IF EXISTS license_platform`,
    );
  }
}
