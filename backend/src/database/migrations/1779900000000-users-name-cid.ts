import { MigrationInterface, QueryRunner } from 'typeorm';

export class UsersNameCid1779900000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE users RENAME COLUMN display_name TO name`,
    );
    await queryRunner.query(
      `ALTER TABLE users ADD COLUMN IF NOT EXISTS cid character varying(10)`,
    );
    await queryRunner.query(
      `ALTER TABLE users ADD COLUMN IF NOT EXISTS cid_username character varying(12)`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE users DROP COLUMN IF EXISTS cid_username`,
    );
    await queryRunner.query(`ALTER TABLE users DROP COLUMN IF EXISTS cid`);
    await queryRunner.query(
      `ALTER TABLE users RENAME COLUMN name TO display_name`,
    );
  }
}
