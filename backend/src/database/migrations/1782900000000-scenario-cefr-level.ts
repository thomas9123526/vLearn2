import { MigrationInterface, QueryRunner } from 'typeorm';

export class ScenarioCefrLevel1782900000000 implements MigrationInterface {
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE vl_scenarios ADD COLUMN IF NOT EXISTS cefr_level smallint NULL`,
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE vl_scenarios DROP COLUMN IF EXISTS cefr_level`,
    );
  }
}
