import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Adds a `gender` column to the users table so the profile-edit dialog in
 * the Flutter Settings screen has somewhere to write to. Defaults to
 * 'unspecified' on existing rows — the app surfaces this as an explicit
 * choice rather than guessing for users who never set one.
 */
export class UsersGender1779700000000 implements MigrationInterface {
  name = 'UsersGender1779700000000';

  public async up(q: QueryRunner): Promise<void> {
    await q.query(
      `ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "gender" VARCHAR(20) NOT NULL DEFAULT 'unspecified';`,
    );
  }

  public async down(q: QueryRunner): Promise<void> {
    await q.query(`ALTER TABLE "users" DROP COLUMN IF EXISTS "gender";`);
  }
}
