import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Adds `gender` and `voice_id` columns to the personas table.
 *
 * `gender` defaults to 'neutral' on existing rows so the Flutter app's
 * avatar code (which switches body animations on this column) has a sane
 * starting point until an admin sets the real value.
 *
 * `voice_id` is nullable because the TTS voice catalog ships with the
 * model bundle, not the database — admins set the value through the admin
 * panel once they know which voices the manifest exposes.
 */
export class PersonasGenderVoice1779600000000 implements MigrationInterface {
  name = 'PersonasGenderVoice1779600000000';

  public async up(q: QueryRunner): Promise<void> {
    await q.query(
      `ALTER TABLE "personas" ADD COLUMN IF NOT EXISTS "gender" VARCHAR(10) NOT NULL DEFAULT 'neutral';`,
    );
    await q.query(
      `ALTER TABLE "personas" ADD COLUMN IF NOT EXISTS "voice_id" VARCHAR(100);`,
    );
  }

  public async down(q: QueryRunner): Promise<void> {
    await q.query(`ALTER TABLE "personas" DROP COLUMN IF EXISTS "voice_id";`);
    await q.query(`ALTER TABLE "personas" DROP COLUMN IF EXISTS "gender";`);
  }
}
