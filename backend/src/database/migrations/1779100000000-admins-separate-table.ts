import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Separate admins from users.
 *
 * Application users live in `users`; backend-control admins (admin +
 * superadmin) live in `admins`. Refresh tokens are split likewise. Admin-
 * touched tables (admin_permissions, admin_audit_log, news.author_id,
 * app_config.updated_by, uploaded_files.uploader_id) lose their FK to
 * `users.id` since the actor may now be an admin instead. UUIDs are
 * preserved when copying admin rows so existing admin_permissions and
 * admin_audit_log entries still line up by id.
 *
 * Idempotency: uses IF NOT EXISTS / IF EXISTS so re-running on a partially-
 * migrated DB is safe.
 */
export class AdminsSeparateTable1779100000000 implements MigrationInterface {
  name = 'AdminsSeparateTable1779100000000';

  public async up(q: QueryRunner): Promise<void> {
    // ─── 1. admins table ───────────────────────────────────────
    await q.query(`
      CREATE TABLE IF NOT EXISTS "admins" (
        "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "email" VARCHAR(255) NOT NULL,
        "password_hash" VARCHAR(255) NOT NULL,
        "display_name" VARCHAR(100) NOT NULL,
        "role" VARCHAR(20) NOT NULL DEFAULT 'admin',
        "status" VARCHAR(20) NOT NULL DEFAULT 'active',
        "last_login_at" TIMESTAMPTZ,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        CONSTRAINT "uniq_admins_email" UNIQUE ("email"),
        CONSTRAINT "chk_admins_role" CHECK ("role" IN ('admin','superadmin')),
        CONSTRAINT "chk_admins_status" CHECK ("status" IN ('active','suspended','deleted'))
      );
    `);

    // ─── 2. admin_refresh_tokens table ─────────────────────────
    await q.query(`
      CREATE TABLE IF NOT EXISTS "admin_refresh_tokens" (
        "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "admin_id" UUID NOT NULL REFERENCES "admins"("id") ON DELETE CASCADE,
        "token_hash" VARCHAR(255) NOT NULL,
        "expires_at" TIMESTAMPTZ NOT NULL,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);
    await q.query(
      `CREATE INDEX IF NOT EXISTS "idx_admin_refresh_tokens_admin_id" ON "admin_refresh_tokens"("admin_id");`,
    );

    // ─── 3. drop FK constraints that would block the user→admin move
    //
    // Postgres names constraints automatically as "<table>_<col>_fkey" unless
    // you name them explicitly. The initial migration didn't name them, so
    // we drop by the conventional name. IF EXISTS keeps this idempotent.
    await q.query(
      `ALTER TABLE "admin_permissions" DROP CONSTRAINT IF EXISTS "admin_permissions_user_id_fkey";`,
    );
    await q.query(
      `ALTER TABLE "admin_permissions" DROP CONSTRAINT IF EXISTS "admin_permissions_granted_by_fkey";`,
    );
    await q.query(
      `ALTER TABLE "admin_audit_log" DROP CONSTRAINT IF EXISTS "admin_audit_log_user_id_fkey";`,
    );
    await q.query(
      `ALTER TABLE "news_posts" DROP CONSTRAINT IF EXISTS "news_posts_author_id_fkey";`,
    );
    await q.query(
      `ALTER TABLE "app_config" DROP CONSTRAINT IF EXISTS "app_config_updated_by_fkey";`,
    );
    await q.query(
      `ALTER TABLE "uploaded_files" DROP CONSTRAINT IF EXISTS "uploaded_files_uploader_id_fkey";`,
    );

    // Some older Postgres versions name these slightly differently when the
    // table or column has been renamed. Belt-and-suspenders: scan and drop
    // anything that still references users(id) from these tables.
    await q.query(`
      DO $$
      DECLARE r RECORD;
      BEGIN
        FOR r IN
          SELECT conname, conrelid::regclass AS table_name
          FROM pg_constraint
          WHERE contype = 'f'
            AND confrelid = '"users"'::regclass
            AND conrelid::regclass::text IN (
              'admin_permissions', 'admin_audit_log',
              'news_posts', 'app_config', 'uploaded_files'
            )
        LOOP
          EXECUTE format('ALTER TABLE %s DROP CONSTRAINT %I', r.table_name, r.conname);
        END LOOP;
      END$$;
    `);

    // ─── 4. add FK on admin_permissions + admin_audit_log → admins
    await q.query(`
      ALTER TABLE "admin_permissions"
        ADD CONSTRAINT "admin_permissions_user_id_fkey"
        FOREIGN KEY ("user_id") REFERENCES "admins"("id") ON DELETE CASCADE;
    `);
    await q.query(`
      ALTER TABLE "admin_audit_log"
        ADD CONSTRAINT "admin_audit_log_user_id_fkey"
        FOREIGN KEY ("user_id") REFERENCES "admins"("id") ON DELETE SET NULL;
    `);

    // ─── 5. copy admin/superadmin rows from users into admins ──
    //
    // INSERT … ON CONFLICT DO NOTHING so re-running this migration on a DB
    // that's already been partially migrated doesn't duplicate.
    await q.query(`
      INSERT INTO "admins" (
        "id", "email", "password_hash", "display_name", "role",
        "status", "created_at", "updated_at"
      )
      SELECT
        "id", "email", "password_hash", "display_name", "role",
        "status", "created_at", "updated_at"
      FROM "users"
      WHERE "role" IN ('admin', 'superadmin')
      ON CONFLICT ("email") DO NOTHING;
    `);

    // ─── 6. delete admin/superadmin rows from users ────────────
    //
    // refresh_tokens still has ON DELETE CASCADE to users(id), so any user-
    // table refresh tokens for these admin rows get cleaned up automatically.
    // Admin-side sessions will be re-created via /admin/auth/signin.
    await q.query(
      `DELETE FROM "users" WHERE "role" IN ('admin', 'superadmin');`,
    );

    // Tighten the role check on users now that admin/superadmin are no
    // longer valid there. (Defensive — keeps a future bug from inserting
    // an admin row into the wrong table.)
    await q.query(
      `ALTER TABLE "users" DROP CONSTRAINT IF EXISTS "chk_users_role";`,
    );
    await q.query(
      `ALTER TABLE "users" ADD CONSTRAINT "chk_users_role" CHECK ("role" IN ('user'));`,
    );

    // Drop the partial unique index that enforced "only one superadmin in
    // users". The new constraint lives in `admins` if we ever want it.
    await q.query(`DROP INDEX IF EXISTS "uniq_one_superadmin";`);
  }

  public async down(q: QueryRunner): Promise<void> {
    // Reverse: copy admins rows back into users, then drop admin tables.
    await q.query(
      `ALTER TABLE "users" DROP CONSTRAINT IF EXISTS "chk_users_role";`,
    );
    await q.query(
      `ALTER TABLE "users" ADD CONSTRAINT "chk_users_role" CHECK ("role" IN ('user','admin','superadmin'));`,
    );

    await q.query(`
      INSERT INTO "users" (
        "id", "email", "password_hash", "display_name", "role", "status",
        "created_at", "updated_at"
      )
      SELECT
        "id", "email", "password_hash", "display_name", "role", "status",
        "created_at", "updated_at"
      FROM "admins"
      ON CONFLICT ("email") DO NOTHING;
    `);

    await q.query(
      `ALTER TABLE "admin_audit_log" DROP CONSTRAINT IF EXISTS "admin_audit_log_user_id_fkey";`,
    );
    await q.query(
      `ALTER TABLE "admin_permissions" DROP CONSTRAINT IF EXISTS "admin_permissions_user_id_fkey";`,
    );

    await q.query(`DROP TABLE IF EXISTS "admin_refresh_tokens";`);
    await q.query(`DROP TABLE IF EXISTS "admins";`);

    // We can't perfectly restore the original FKs since the data they pointed
    // to (admin users in users) may have been mutated — skip restoring the
    // dropped FKs on news_posts / app_config / uploaded_files. Re-add them
    // manually if you actually run a down migration in anger.
  }
}
