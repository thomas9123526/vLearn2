import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Enforces that each CID number can be registered by at most one user.
 * A partial unique index is used (WHERE cid IS NOT NULL) so that
 * users who signed up without a CID (cid = NULL) are not affected.
 */
export class UsersCidUnique1781000000000 implements MigrationInterface {
  public async up(qr: QueryRunner): Promise<void> {
    await qr.query(
      `CREATE UNIQUE INDEX IF NOT EXISTS uq_users_cid
         ON users (cid)
         WHERE cid IS NOT NULL`,
    );
  }

  public async down(qr: QueryRunner): Promise<void> {
    await qr.query(`DROP INDEX IF EXISTS uq_users_cid`);
  }
}
