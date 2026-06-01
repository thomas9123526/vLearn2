import { MigrationInterface, QueryRunner } from 'typeorm';

export class ScenarioBackgroundImage1781200000000 implements MigrationInterface {
  public async up(qr: QueryRunner): Promise<void> {
    await qr.query(
      `ALTER TABLE vl_scenarios ADD COLUMN IF NOT EXISTS background_image_storage_key VARCHAR(255)`,
    );
    await qr.query(
      `ALTER TABLE vl_scenarios ADD COLUMN IF NOT EXISTS background_image_url VARCHAR(500)`,
    );
  }

  public async down(qr: QueryRunner): Promise<void> {
    await qr.query(
      `ALTER TABLE vl_scenarios DROP COLUMN IF EXISTS background_image_url`,
    );
    await qr.query(
      `ALTER TABLE vl_scenarios DROP COLUMN IF EXISTS background_image_storage_key`,
    );
  }
}
