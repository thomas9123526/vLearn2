import { MigrationInterface, QueryRunner } from 'typeorm';

export class SessionScoreCefr1782000000000 implements MigrationInterface {
  async up(runner: QueryRunner): Promise<void> {
    await runner.query(`
      ALTER TABLE vl_session_scores
        ADD COLUMN IF NOT EXISTS cefr_estimate       VARCHAR(3) NULL,
        ADD COLUMN IF NOT EXISTS topic_adherence_score SMALLINT  NULL;
    `);
  }

  async down(runner: QueryRunner): Promise<void> {
    await runner.query(`
      ALTER TABLE vl_session_scores
        DROP COLUMN IF EXISTS cefr_estimate,
        DROP COLUMN IF EXISTS topic_adherence_score;
    `);
  }
}
