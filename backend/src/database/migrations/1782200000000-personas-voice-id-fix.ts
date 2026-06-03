import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Fixes persona voice_id values to match the on-device VITS manifest
 * (en_VCTK-amy / en_VCTK-james). The previous seed used locale-specific IDs
 * (en_GB-alan, en_AU-james, etc.) that don't exist in the manifest, causing
 * the Flutter app to always fall back to the first voice (female) for every
 * tutor regardless of gender.
 */
export class PersonasVoiceIdFix1782200000000 implements MigrationInterface {
  name = 'PersonasVoiceIdFix1782200000000';

  public async up(q: QueryRunner): Promise<void> {
    // Female personas → amy
    await q.query(`
      UPDATE "vl_personas"
         SET "voice_id" = 'en_VCTK-amy'
       WHERE "slug" IN ('maya', 'sofia')
    `);

    // Male personas → james
    await q.query(`
      UPDATE "vl_personas"
         SET "voice_id" = 'en_VCTK-james'
       WHERE "slug" IN ('leo', 'theo')
    `);
  }

  public async down(q: QueryRunner): Promise<void> {
    await q.query(`UPDATE "vl_personas" SET "voice_id" = 'en_US-amy'  WHERE "slug" = 'maya'`);
    await q.query(`UPDATE "vl_personas" SET "voice_id" = 'en_GB-alan' WHERE "slug" = 'leo'`);
    await q.query(`UPDATE "vl_personas" SET "voice_id" = 'en_GB-jenny' WHERE "slug" = 'sofia'`);
    await q.query(`UPDATE "vl_personas" SET "voice_id" = 'en_AU-james' WHERE "slug" = 'theo'`);
  }
}
