import { MigrationInterface, QueryRunner } from 'typeorm';

export class ExtractVlUserInfo1780000000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS vl_user_info (
        user_id uuid NOT NULL,
        email character varying(255) NOT NULL,
        avatar_emoji character varying(10) NOT NULL DEFAULT '🐣',
        native_language character varying(10) NOT NULL DEFAULT 'en',
        ui_language character varying(10) NOT NULL DEFAULT 'en',
        current_level smallint NOT NULL DEFAULT 1,
        xp_total integer NOT NULL DEFAULT 0,
        streak_days smallint NOT NULL DEFAULT 0,
        last_active_date date,
        active_persona_id uuid,
        active_theme character varying(20) NOT NULL DEFAULT 'apricot',
        onboarding_done boolean NOT NULL DEFAULT false,
        role character varying(20) NOT NULL DEFAULT 'user',
        status character varying(20) NOT NULL DEFAULT 'active',
        suspended_until timestamp with time zone,
        suspended_reason text,
        leaderboard_opt_in boolean NOT NULL DEFAULT true,
        CONSTRAINT pk_vl_user_info PRIMARY KEY (user_id),
        CONSTRAINT fk_vl_user_info_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);

    await queryRunner.query(`CREATE UNIQUE INDEX IF NOT EXISTS uq_vl_user_info_email ON vl_user_info (email)`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_vl_user_info_xp_total ON vl_user_info (xp_total)`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_vl_user_info_streak_days ON vl_user_info (streak_days)`);

    // Copy existing user rows (safe no-op when users table is empty)
    await queryRunner.query(`
      INSERT INTO vl_user_info (
        user_id, email, avatar_emoji, native_language, ui_language,
        current_level, xp_total, streak_days, last_active_date, active_persona_id,
        active_theme, onboarding_done, role, status,
        suspended_until, suspended_reason, leaderboard_opt_in
      )
      SELECT
        id, email, avatar_emoji, native_language, ui_language,
        current_level, xp_total, streak_days, last_active_date, active_persona_id,
        active_theme, onboarding_done, role, status,
        suspended_until, suspended_reason, leaderboard_opt_in
      FROM users
      ON CONFLICT DO NOTHING
    `);

    await queryRunner.query(`ALTER TABLE users DROP COLUMN IF EXISTS email`);
    await queryRunner.query(`ALTER TABLE users DROP COLUMN IF EXISTS avatar_emoji`);
    await queryRunner.query(`ALTER TABLE users DROP COLUMN IF EXISTS native_language`);
    await queryRunner.query(`ALTER TABLE users DROP COLUMN IF EXISTS ui_language`);
    await queryRunner.query(`ALTER TABLE users DROP COLUMN IF EXISTS current_level`);
    await queryRunner.query(`ALTER TABLE users DROP COLUMN IF EXISTS xp_total`);
    await queryRunner.query(`ALTER TABLE users DROP COLUMN IF EXISTS streak_days`);
    await queryRunner.query(`ALTER TABLE users DROP COLUMN IF EXISTS last_active_date`);
    await queryRunner.query(`ALTER TABLE users DROP COLUMN IF EXISTS active_persona_id`);
    await queryRunner.query(`ALTER TABLE users DROP COLUMN IF EXISTS active_theme`);
    await queryRunner.query(`ALTER TABLE users DROP COLUMN IF EXISTS onboarding_done`);
    await queryRunner.query(`ALTER TABLE users DROP COLUMN IF EXISTS role`);
    await queryRunner.query(`ALTER TABLE users DROP COLUMN IF EXISTS status`);
    await queryRunner.query(`ALTER TABLE users DROP COLUMN IF EXISTS suspended_until`);
    await queryRunner.query(`ALTER TABLE users DROP COLUMN IF EXISTS suspended_reason`);
    await queryRunner.query(`ALTER TABLE users DROP COLUMN IF EXISTS leaderboard_opt_in`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS email character varying(255)`);
    await queryRunner.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_emoji character varying(10) DEFAULT '🐣'`);
    await queryRunner.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS native_language character varying(10) DEFAULT 'en'`);
    await queryRunner.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS ui_language character varying(10) DEFAULT 'en'`);
    await queryRunner.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS current_level smallint DEFAULT 1`);
    await queryRunner.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS xp_total integer DEFAULT 0`);
    await queryRunner.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS streak_days smallint DEFAULT 0`);
    await queryRunner.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS last_active_date date`);
    await queryRunner.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS active_persona_id uuid`);
    await queryRunner.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS active_theme character varying(20) DEFAULT 'apricot'`);
    await queryRunner.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS onboarding_done boolean DEFAULT false`);
    await queryRunner.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS role character varying(20) DEFAULT 'user'`);
    await queryRunner.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS status character varying(20) DEFAULT 'active'`);
    await queryRunner.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS suspended_until timestamp with time zone`);
    await queryRunner.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS suspended_reason text`);
    await queryRunner.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS leaderboard_opt_in boolean DEFAULT true`);

    await queryRunner.query(`
      UPDATE users u
      SET
        email           = i.email,
        avatar_emoji    = i.avatar_emoji,
        native_language = i.native_language,
        ui_language     = i.ui_language,
        current_level   = i.current_level,
        xp_total        = i.xp_total,
        streak_days     = i.streak_days,
        last_active_date    = i.last_active_date,
        active_persona_id   = i.active_persona_id,
        active_theme        = i.active_theme,
        onboarding_done     = i.onboarding_done,
        role                = i.role,
        status              = i.status,
        suspended_until     = i.suspended_until,
        suspended_reason    = i.suspended_reason,
        leaderboard_opt_in  = i.leaderboard_opt_in
      FROM vl_user_info i
      WHERE i.user_id = u.id
    `);

    await queryRunner.query(`ALTER TABLE users ALTER COLUMN email SET NOT NULL`);
    await queryRunner.query(`CREATE UNIQUE INDEX IF NOT EXISTS uq_users_email ON users (email)`);

    await queryRunner.query(`DROP TABLE IF EXISTS vl_user_info`);
  }
}
