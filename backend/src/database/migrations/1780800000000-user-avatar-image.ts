import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * User-uploaded profile photo. Mirrors the persona / scenario shape:
 * `avatar_storage_key` holds the path relative to UPLOADS_DIR (e.g.
 * `avatars/<user_id>.jpg`); `avatar_url` is the public URL
 * `/uploads/avatars/<user_id>.jpg` that the Flutter client + admin
 * panel render directly. Both nullable — emoji fallback stays
 * usable for users who never upload.
 */
export class UserAvatarImage1780800000000 implements MigrationInterface {
  public async up(qr: QueryRunner): Promise<void> {
    await qr.query(
      `ALTER TABLE vl_user_info ADD COLUMN IF NOT EXISTS avatar_storage_key VARCHAR(255)`,
    );
    await qr.query(
      `ALTER TABLE vl_user_info ADD COLUMN IF NOT EXISTS avatar_url VARCHAR(500)`,
    );
  }

  public async down(qr: QueryRunner): Promise<void> {
    await qr.query(
      `ALTER TABLE vl_user_info DROP COLUMN IF EXISTS avatar_url`,
    );
    await qr.query(
      `ALTER TABLE vl_user_info DROP COLUMN IF EXISTS avatar_storage_key`,
    );
  }
}
