import { MigrationInterface, QueryRunner } from 'typeorm';

/** Creates the vl_user_reports table for user-submitted feedback and bug reports. */
export class VlUserReportsTable1781700000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS vl_user_reports (
        id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id     UUID        NOT NULL,
        type        VARCHAR(20) NOT NULL DEFAULT 'feedback',
        content     TEXT        NOT NULL,
        platform    VARCHAR(20) NULL,
        app_version VARCHAR(50) NULL,
        created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
      );

      CREATE INDEX IF NOT EXISTS idx_vl_user_reports_user_created
        ON vl_user_reports (user_id, created_at);

      CREATE INDEX IF NOT EXISTS idx_vl_user_reports_type_created
        ON vl_user_reports (type, created_at);
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS vl_user_reports;`);
  }
}
