import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Adds `tts_age` and `tts_voice_sid` to the vl_personas table.
 *
 * `tts_age` gives the admin a high-level voice character label
 * ('young' | 'adult' | 'elder') that the Flutter app uses as a fallback
 * hint when `voice_id` is not set.
 *
 * `tts_voice_sid` is a direct speaker-index override (0-based) for the
 * on-device VITS model. When set it wins over both `voice_id` and the
 * `tts_age` heuristic, letting admins pin a specific SID without knowing
 * the voice name string.
 */
export class PersonasVoiceConfig1782100000000 implements MigrationInterface {
  name = 'PersonasVoiceConfig1782100000000';

  public async up(q: QueryRunner): Promise<void> {
    await q.query(
      `ALTER TABLE "vl_personas" ADD COLUMN IF NOT EXISTS "tts_age" VARCHAR(20);`,
    );
    await q.query(
      `ALTER TABLE "vl_personas" ADD COLUMN IF NOT EXISTS "tts_voice_sid" SMALLINT;`,
    );
  }

  public async down(q: QueryRunner): Promise<void> {
    await q.query(`ALTER TABLE "vl_personas" DROP COLUMN IF EXISTS "tts_voice_sid";`);
    await q.query(`ALTER TABLE "vl_personas" DROP COLUMN IF EXISTS "tts_age";`);
  }
}
