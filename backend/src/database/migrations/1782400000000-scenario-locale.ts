import { MigrationInterface, QueryRunner } from 'typeorm';

export class ScenarioLocale1782400000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE vl_scenarios
        ADD COLUMN IF NOT EXISTS locale varchar(50) NULL;
    `);
    await queryRunner.query(`
      COMMENT ON COLUMN vl_scenarios.locale IS
        'Locale key for AI prompt grounding: china | japan | italy (NULL = auto-detect from user native language)';
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE vl_scenarios
        DROP COLUMN IF EXISTS locale;
    `);
  }
}
