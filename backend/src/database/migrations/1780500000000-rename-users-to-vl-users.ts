import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Completes `1779800000000-add-vl-prefix.ts`, which renamed every other
 * application table to the `vl_` prefix but missed `users`. After this
 * migration the schema is fully consistent: every learner-facing table
 * carries the `vl_` namespace.
 *
 * Foreign-key references to `users(id)` from peer tables
 * (`vl_user_info`, `vl_refresh_tokens`, `vl_skill_snapshots`, etc.) keep
 * working — Postgres tracks FK targets by OID, not by table name, so
 * `RENAME TO` is transparent to them. Index and constraint names
 * (`idx_users_*`, `chk_users_role`, `uniq_one_superadmin`) are left
 * untouched for the same reason the original `add-vl-prefix` migration
 * left peers' index names alone: they're purely cosmetic.
 */
export class RenameUsersToVlUsers1780500000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE IF EXISTS "users" RENAME TO "vl_users"`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE IF EXISTS "vl_users" RENAME TO "users"`,
    );
  }
}
