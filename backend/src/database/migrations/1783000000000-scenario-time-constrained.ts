import { MigrationInterface, QueryRunner } from 'typeorm';

export class ScenarioTimeConstrained1783000000000 implements MigrationInterface {
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE vl_scenarios ADD COLUMN IF NOT EXISTS time_constrained boolean NOT NULL DEFAULT false`,
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE vl_scenarios DROP COLUMN IF EXISTS time_constrained`,
    );
  }
}
