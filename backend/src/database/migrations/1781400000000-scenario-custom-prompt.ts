import { MigrationInterface, QueryRunner } from 'typeorm';

export class ScenarioCustomPrompt1781400000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE vl_scenarios
        ADD COLUMN IF NOT EXISTS custom_prompt text NULL;
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE vl_scenarios
        DROP COLUMN IF EXISTS custom_prompt;
    `);
  }
}
