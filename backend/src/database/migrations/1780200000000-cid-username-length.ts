import { MigrationInterface, QueryRunner } from 'typeorm';

export class CidUsernameLength1780200000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE users ALTER COLUMN cid_username TYPE character varying(50)`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE users ALTER COLUMN cid_username TYPE character varying(12)`);
  }
}
