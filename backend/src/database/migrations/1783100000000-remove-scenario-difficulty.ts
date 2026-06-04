import { MigrationInterface, QueryRunner } from 'typeorm';

export class RemoveScenarioDifficulty1783100000000 implements MigrationInterface {
  async up(queryRunner: QueryRunner): Promise<void> {
    // Preserve existing difficulty values in cefr_level where not already set.
    // difficulty was 1–5; cefr_level is 1–6. Values 1–5 map directly.
    await queryRunner.query(
      `UPDATE vl_scenarios SET cefr_level = difficulty WHERE cefr_level IS NULL AND difficulty IS NOT NULL`,
    );
    await queryRunner.query(
      `ALTER TABLE vl_scenarios DROP COLUMN IF EXISTS difficulty`,
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE vl_scenarios ADD COLUMN IF NOT EXISTS difficulty smallint DEFAULT 1`,
    );
    await queryRunner.query(
      `UPDATE vl_scenarios SET difficulty = COALESCE(cefr_level, 1)`,
    );
  }
}
