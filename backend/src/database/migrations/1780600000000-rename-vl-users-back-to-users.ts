import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Companion to the reverted `1780500000000-rename-users-to-vl-users.ts`.
 * That earlier migration shipped, was run against at least one
 * environment (renaming `users` → `vl_users`), and then got reverted
 * from code. The reverted code expects the table to be named `users`
 * again, but the live DB still has `vl_users`. This migration brings
 * those environments back into sync.
 *
 * Both directions are guarded with `IF EXISTS` so this is a true no-op
 * on a fresh DB that never had the original rename applied: it sees
 * neither `vl_users` (already a `users` table) nor a need to roll back.
 */
export class RenameVlUsersBackToUsers1780600000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE IF EXISTS "vl_users" RENAME TO "users"`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE IF EXISTS "users" RENAME TO "vl_users"`,
    );
  }
}
