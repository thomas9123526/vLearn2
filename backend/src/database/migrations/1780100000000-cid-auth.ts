import { MigrationInterface, QueryRunner } from 'typeorm';

export class CidAuth1780100000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // email is no longer collected during signup — make it optional
    await queryRunner.query(
      `ALTER TABLE vl_user_info ALTER COLUMN email DROP NOT NULL`,
    );
    await queryRunner.query(`DROP INDEX IF EXISTS uq_vl_user_info_email`);
    await queryRunner.query(
      `CREATE UNIQUE INDEX IF NOT EXISTS uq_vl_user_info_email ON vl_user_info (email) WHERE email IS NOT NULL`,
    );

    // cid_username is now the login identifier — enforce uniqueness
    await queryRunner.query(
      `CREATE UNIQUE INDEX IF NOT EXISTS uq_users_cid_username ON users (cid_username) WHERE cid_username IS NOT NULL`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS uq_users_cid_username`);
    await queryRunner.query(`DROP INDEX IF EXISTS uq_vl_user_info_email`);
    await queryRunner.query(
      `CREATE UNIQUE INDEX IF NOT EXISTS uq_vl_user_info_email ON vl_user_info (email)`,
    );
    await queryRunner.query(
      `ALTER TABLE vl_user_info ALTER COLUMN email SET NOT NULL`,
    );
  }
}
