import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Initial schema for vLearn2.
 *
 * Hand-written (not auto-generated) so the SQL is auditable and the
 * ordering of FKs is explicit. Subsequent migrations should use
 * `npm run db:migrate:generate` to diff against entities.
 *
 * Tables covered (in dependency order):
 *   users → refresh_tokens
 *   personas
 *   scenarios   → user_scenario_completions
 *   courses     → course_scenarios
 *   conversation_sessions → conversation_messages → session_scores
 *   user_progress, skill_snapshots
 *   achievements → user_achievements
 *   guard_violations
 *   app_config, admin_audit_log, admin_permissions, uploaded_files
 */
export class InitialSchema1715800000000 implements MigrationInterface {
  name = 'InitialSchema1715800000000';

  public async up(q: QueryRunner): Promise<void> {
    // ─── Extensions ─────────────────────────────────────────
    await q.query(`CREATE EXTENSION IF NOT EXISTS "pgcrypto";`);

    // ─── users ──────────────────────────────────────────────
    await q.query(`
      CREATE TABLE "users" (
        "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "email" VARCHAR(255) UNIQUE NOT NULL,
        "password_hash" VARCHAR(255) NOT NULL,
        "display_name" VARCHAR(100) NOT NULL,
        "avatar_emoji" VARCHAR(10) DEFAULT '🐣',
        "native_language" VARCHAR(10) DEFAULT 'en',
        "ui_language" VARCHAR(10) DEFAULT 'en',
        "current_level" SMALLINT DEFAULT 1,
        "xp_total" INTEGER DEFAULT 0,
        "streak_days" SMALLINT DEFAULT 0,
        "last_active_date" DATE,
        "active_persona_id" UUID,
        "active_theme" VARCHAR(20) DEFAULT 'apricot',
        "onboarding_done" BOOLEAN DEFAULT false,
        "role" VARCHAR(20) NOT NULL DEFAULT 'user',
        "status" VARCHAR(20) NOT NULL DEFAULT 'active',
        "suspended_until" TIMESTAMPTZ,
        "suspended_reason" TEXT,
        "leaderboard_opt_in" BOOLEAN DEFAULT true,
        "created_at" TIMESTAMPTZ DEFAULT now(),
        "updated_at" TIMESTAMPTZ DEFAULT now()
      );
    `);
    await q.query(
      `CREATE INDEX "idx_users_xp_total" ON "users"("xp_total" DESC);`,
    );
    await q.query(
      `CREATE INDEX "idx_users_streak_days" ON "users"("streak_days" DESC);`,
    );
    await q.query(
      `CREATE INDEX "idx_users_status" ON "users"("status") WHERE "status" != 'active';`,
    );
    await q.query(
      `CREATE UNIQUE INDEX "uniq_one_superadmin" ON "users"("role") WHERE "role" = 'superadmin';`,
    );

    // ─── refresh_tokens ────────────────────────────────────
    await q.query(`
      CREATE TABLE "refresh_tokens" (
        "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "user_id" UUID NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
        "token_hash" VARCHAR(255) NOT NULL,
        "expires_at" TIMESTAMPTZ NOT NULL,
        "created_at" TIMESTAMPTZ DEFAULT now()
      );
    `);
    await q.query(
      `CREATE INDEX "idx_refresh_tokens_user_id" ON "refresh_tokens"("user_id");`,
    );

    // ─── personas ──────────────────────────────────────────
    await q.query(`
      CREATE TABLE "personas" (
        "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "slug" VARCHAR(50) UNIQUE NOT NULL,
        "name" VARCHAR(50) NOT NULL,
        "accent" VARCHAR(100) NOT NULL,
        "style" VARCHAR(100) NOT NULL,
        "specialties" JSONB NOT NULL DEFAULT '[]'::jsonb,
        "gradient_from" VARCHAR(7) NOT NULL,
        "gradient_to" VARCHAR(7) NOT NULL,
        "rive_asset" VARCHAR(100),
        "image_url" VARCHAR(500),
        "image_storage_key" VARCHAR(255),
        "is_active" BOOLEAN DEFAULT true
      );
    `);

    // FK from users.active_persona_id added once personas exists
    await q.query(`
      ALTER TABLE "users"
      ADD CONSTRAINT "fk_users_active_persona"
      FOREIGN KEY ("active_persona_id") REFERENCES "personas"("id") ON DELETE SET NULL;
    `);

    // ─── scenarios ─────────────────────────────────────────
    await q.query(`
      CREATE TABLE "scenarios" (
        "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "slug" VARCHAR(100) UNIQUE NOT NULL,
        "category" VARCHAR(50) NOT NULL,
        "difficulty" SMALLINT NOT NULL,
        "title" JSONB NOT NULL,
        "description" JSONB NOT NULL,
        "scene_description" JSONB NOT NULL,
        "user_role" JSONB NOT NULL,
        "tutor_role" JSONB NOT NULL,
        "objectives" JSONB NOT NULL,
        "key_phrases" JSONB NOT NULL,
        "estimated_minutes" SMALLINT DEFAULT 5,
        "xp_reward" SMALLINT DEFAULT 50,
        "order_index" SMALLINT DEFAULT 0,
        "image_url" VARCHAR(500),
        "image_storage_key" VARCHAR(255),
        "image_alt_text" VARCHAR(500),
        "author_id" UUID REFERENCES "users"("id") ON DELETE SET NULL,
        "status" VARCHAR(20) NOT NULL DEFAULT 'published',
        "published_at" TIMESTAMPTZ,
        "created_at" TIMESTAMPTZ DEFAULT now()
      );
    `);
    await q.query(
      `CREATE INDEX "idx_scenarios_category" ON "scenarios"("category");`,
    );
    await q.query(
      `CREATE INDEX "idx_scenarios_difficulty" ON "scenarios"("difficulty");`,
    );
    await q.query(
      `CREATE INDEX "idx_scenarios_status" ON "scenarios"("status");`,
    );

    // ─── courses ───────────────────────────────────────────
    await q.query(`
      CREATE TABLE "courses" (
        "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "slug" VARCHAR(100) UNIQUE NOT NULL,
        "title" JSONB NOT NULL,
        "description" JSONB NOT NULL,
        "level_range" VARCHAR(20) NOT NULL,
        "total_xp" SMALLINT DEFAULT 0,
        "order_index" SMALLINT DEFAULT 0,
        "image_url" VARCHAR(500),
        "status" VARCHAR(20) NOT NULL DEFAULT 'published',
        "published_at" TIMESTAMPTZ
      );
    `);
    await q.query(`CREATE INDEX "idx_courses_status" ON "courses"("status");`);

    // ─── course_scenarios ──────────────────────────────────
    await q.query(`
      CREATE TABLE "course_scenarios" (
        "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "course_id" UUID NOT NULL REFERENCES "courses"("id") ON DELETE CASCADE,
        "scenario_id" UUID NOT NULL REFERENCES "scenarios"("id") ON DELETE CASCADE,
        "order_index" SMALLINT NOT NULL,
        UNIQUE ("course_id", "scenario_id")
      );
    `);
    await q.query(
      `CREATE INDEX "idx_course_scenarios_order" ON "course_scenarios"("course_id", "order_index");`,
    );

    // ─── conversation_sessions ─────────────────────────────
    await q.query(`
      CREATE TABLE "conversation_sessions" (
        "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "user_id" UUID NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
        "scenario_id" UUID REFERENCES "scenarios"("id") ON DELETE SET NULL,
        "persona_id" UUID NOT NULL REFERENCES "personas"("id") ON DELETE RESTRICT,
        "mode" VARCHAR(20) NOT NULL,
        "status" VARCHAR(20) NOT NULL DEFAULT 'active',
        "started_at" TIMESTAMPTZ DEFAULT now(),
        "ended_at" TIMESTAMPTZ,
        "duration_seconds" INTEGER,
        "turn_count" SMALLINT DEFAULT 0,
        "word_count" INTEGER DEFAULT 0,
        "xp_earned" SMALLINT DEFAULT 0
      );
    `);
    await q.query(
      `CREATE INDEX "idx_sessions_user_id" ON "conversation_sessions"("user_id");`,
    );
    await q.query(
      `CREATE INDEX "idx_sessions_started_at" ON "conversation_sessions"("started_at");`,
    );

    // ─── conversation_messages ─────────────────────────────
    await q.query(`
      CREATE TABLE "conversation_messages" (
        "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "session_id" UUID NOT NULL REFERENCES "conversation_sessions"("id") ON DELETE CASCADE,
        "role" VARCHAR(10) NOT NULL,
        "content" TEXT NOT NULL,
        "sequence" INTEGER DEFAULT 0,
        "audio_url" VARCHAR(500),
        "created_at" TIMESTAMPTZ DEFAULT now()
      );
    `);
    await q.query(
      `CREATE INDEX "idx_messages_session_id" ON "conversation_messages"("session_id");`,
    );

    // ─── session_scores ────────────────────────────────────
    await q.query(`
      CREATE TABLE "session_scores" (
        "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "session_id" UUID UNIQUE NOT NULL REFERENCES "conversation_sessions"("id") ON DELETE CASCADE,
        "overall_score" SMALLINT,
        "pronunciation_score" SMALLINT,
        "fluency_score" SMALLINT,
        "vocabulary_score" SMALLINT,
        "grammar_score" SMALLINT,
        "engagement_score" SMALLINT,
        "listening_score" SMALLINT,
        "pronunciation_metrics" JSONB,
        "fluency_metrics" JSONB,
        "vocabulary_metrics" JSONB,
        "grammar_metrics" JSONB,
        "listening_metrics" JSONB,
        "strengths" TEXT[] DEFAULT ARRAY[]::TEXT[],
        "improvements" TEXT[] DEFAULT ARRAY[]::TEXT[],
        "ai_feedback" TEXT,
        "evaluator_versions" JSONB,
        "computed_at" TIMESTAMPTZ DEFAULT now()
      );
    `);

    // ─── skill_snapshots ───────────────────────────────────
    await q.query(`
      CREATE TABLE "skill_snapshots" (
        "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "user_id" UUID NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
        "snapshot_date" DATE NOT NULL,
        "pronunciation" SMALLINT,
        "fluency" SMALLINT,
        "vocabulary" SMALLINT DEFAULT 0,
        "grammar" SMALLINT DEFAULT 0,
        "listening" SMALLINT,
        "sessions_in_window" SMALLINT DEFAULT 0,
        "confidence" SMALLINT DEFAULT 50,
        UNIQUE ("user_id", "snapshot_date")
      );
    `);
    await q.query(
      `CREATE INDEX "idx_skill_snapshots_user_date" ON "skill_snapshots"("user_id", "snapshot_date");`,
    );

    // ─── user_progress ─────────────────────────────────────
    await q.query(`
      CREATE TABLE "user_progress" (
        "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "user_id" UUID UNIQUE NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
        "sessions_total" INTEGER DEFAULT 0,
        "sessions_this_week" SMALLINT DEFAULT 0,
        "minutes_spoken_total" INTEGER DEFAULT 0,
        "minutes_spoken_this_week" SMALLINT DEFAULT 0,
        "words_spoken_total" INTEGER DEFAULT 0,
        "scenarios_completed" INTEGER DEFAULT 0,
        "current_streak" SMALLINT DEFAULT 0,
        "longest_streak" SMALLINT DEFAULT 0,
        "level_history" JSONB DEFAULT '[]'::jsonb,
        "updated_at" TIMESTAMPTZ DEFAULT now()
      );
    `);

    // ─── user_scenario_completions ─────────────────────────
    await q.query(`
      CREATE TABLE "user_scenario_completions" (
        "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "user_id" UUID NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
        "scenario_id" UUID NOT NULL REFERENCES "scenarios"("id") ON DELETE CASCADE,
        "best_score" SMALLINT,
        "completion_count" SMALLINT DEFAULT 1,
        "first_completed_at" TIMESTAMPTZ DEFAULT now(),
        "last_completed_at" TIMESTAMPTZ,
        UNIQUE ("user_id", "scenario_id")
      );
    `);
    await q.query(
      `CREATE INDEX "idx_completions_user_id" ON "user_scenario_completions"("user_id");`,
    );

    // ─── achievements ──────────────────────────────────────
    await q.query(`
      CREATE TABLE "achievements" (
        "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "key" VARCHAR(50) UNIQUE NOT NULL,
        "title" JSONB NOT NULL,
        "description" JSONB NOT NULL,
        "icon" VARCHAR(10) NOT NULL,
        "xp_reward" SMALLINT DEFAULT 0,
        "condition_type" VARCHAR(50) NOT NULL,
        "condition_value" INTEGER NOT NULL
      );
    `);

    // ─── user_achievements ─────────────────────────────────
    await q.query(`
      CREATE TABLE "user_achievements" (
        "user_id" UUID NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
        "achievement_id" UUID NOT NULL REFERENCES "achievements"("id") ON DELETE CASCADE,
        "earned_at" TIMESTAMPTZ DEFAULT now(),
        PRIMARY KEY ("user_id", "achievement_id")
      );
    `);

    // ─── guard_violations ──────────────────────────────────
    await q.query(`
      CREATE TABLE "guard_violations" (
        "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "user_id" UUID NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
        "session_id" UUID REFERENCES "conversation_sessions"("id") ON DELETE SET NULL,
        "attempted_content" TEXT NOT NULL,
        "matched_terms" TEXT[] DEFAULT ARRAY[]::TEXT[],
        "severity" VARCHAR(10) NOT NULL,
        "language" VARCHAR(10) NOT NULL,
        "source" VARCHAR(10) NOT NULL,
        "user_acknowledged_warn" BOOLEAN DEFAULT false,
        "created_at" TIMESTAMPTZ DEFAULT now()
      );
    `);
    await q.query(
      `CREATE INDEX "idx_guard_violations_user_id" ON "guard_violations"("user_id", "created_at" DESC);`,
    );
    await q.query(
      `CREATE INDEX "idx_guard_violations_severity" ON "guard_violations"("severity", "created_at" DESC);`,
    );

    // ─── app_config ────────────────────────────────────────
    await q.query(`
      CREATE TABLE "app_config" (
        "key" VARCHAR(100) PRIMARY KEY,
        "value" JSONB NOT NULL,
        "value_type" VARCHAR(20) NOT NULL,
        "category" VARCHAR(50) NOT NULL,
        "description" TEXT NOT NULL,
        "default_value" JSONB NOT NULL,
        "is_visible_to_app" BOOLEAN DEFAULT true,
        "updated_at" TIMESTAMPTZ DEFAULT now(),
        "updated_by" UUID REFERENCES "users"("id") ON DELETE SET NULL
      );
    `);
    await q.query(
      `CREATE INDEX "idx_app_config_category" ON "app_config"("category");`,
    );

    // ─── admin_audit_log ───────────────────────────────────
    await q.query(`
      CREATE TABLE "admin_audit_log" (
        "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "user_id" UUID REFERENCES "users"("id") ON DELETE SET NULL,
        "action" VARCHAR(50) NOT NULL,
        "target_type" VARCHAR(20) NOT NULL,
        "target_id" VARCHAR(100) NOT NULL,
        "old_value" JSONB,
        "new_value" JSONB,
        "metadata" JSONB,
        "created_at" TIMESTAMPTZ DEFAULT now()
      );
    `);
    await q.query(
      `CREATE INDEX "idx_admin_audit_log_user_time" ON "admin_audit_log"("user_id", "created_at" DESC);`,
    );
    await q.query(
      `CREATE INDEX "idx_admin_audit_log_target" ON "admin_audit_log"("target_type", "target_id", "created_at" DESC);`,
    );
    await q.query(
      `CREATE INDEX "idx_admin_audit_log_action_time" ON "admin_audit_log"("action", "created_at" DESC);`,
    );

    // ─── admin_permissions ─────────────────────────────────
    await q.query(`
      CREATE TABLE "admin_permissions" (
        "user_id" UUID NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
        "permission" VARCHAR(60) NOT NULL,
        "granted_by" UUID REFERENCES "users"("id") ON DELETE SET NULL,
        "granted_at" TIMESTAMPTZ DEFAULT now(),
        PRIMARY KEY ("user_id", "permission")
      );
    `);
    await q.query(
      `CREATE INDEX "idx_admin_permissions_user" ON "admin_permissions"("user_id");`,
    );
    await q.query(
      `CREATE INDEX "idx_admin_permissions_perm" ON "admin_permissions"("permission");`,
    );

    // ─── uploaded_files ────────────────────────────────────
    await q.query(`
      CREATE TABLE "uploaded_files" (
        "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "storage_key" VARCHAR(255) UNIQUE NOT NULL,
        "original_filename" VARCHAR(500) NOT NULL,
        "mime_type" VARCHAR(50) NOT NULL,
        "size_bytes" INTEGER NOT NULL,
        "width" INTEGER,
        "height" INTEGER,
        "content_hash" VARCHAR(64) NOT NULL,
        "reference_count" INTEGER DEFAULT 1,
        "uploader_id" UUID REFERENCES "users"("id") ON DELETE SET NULL,
        "folder" VARCHAR(50) NOT NULL,
        "storage_provider" VARCHAR(20) NOT NULL,
        "created_at" TIMESTAMPTZ DEFAULT now()
      );
    `);
    await q.query(
      `CREATE INDEX "idx_uploaded_files_hash" ON "uploaded_files"("content_hash");`,
    );
    await q.query(
      `CREATE INDEX "idx_uploaded_files_uploader" ON "uploaded_files"("uploader_id", "created_at" DESC);`,
    );
  }

  public async down(q: QueryRunner): Promise<void> {
    // Drop in reverse FK dependency order
    await q.query(`DROP TABLE IF EXISTS "uploaded_files";`);
    await q.query(`DROP TABLE IF EXISTS "admin_permissions";`);
    await q.query(`DROP TABLE IF EXISTS "admin_audit_log";`);
    await q.query(`DROP TABLE IF EXISTS "app_config";`);
    await q.query(`DROP TABLE IF EXISTS "guard_violations";`);
    await q.query(`DROP TABLE IF EXISTS "user_achievements";`);
    await q.query(`DROP TABLE IF EXISTS "achievements";`);
    await q.query(`DROP TABLE IF EXISTS "user_scenario_completions";`);
    await q.query(`DROP TABLE IF EXISTS "user_progress";`);
    await q.query(`DROP TABLE IF EXISTS "skill_snapshots";`);
    await q.query(`DROP TABLE IF EXISTS "session_scores";`);
    await q.query(`DROP TABLE IF EXISTS "conversation_messages";`);
    await q.query(`DROP TABLE IF EXISTS "conversation_sessions";`);
    await q.query(`DROP TABLE IF EXISTS "course_scenarios";`);
    await q.query(`DROP TABLE IF EXISTS "courses";`);
    await q.query(`DROP TABLE IF EXISTS "scenarios";`);
    await q.query(
      `ALTER TABLE IF EXISTS "users" DROP CONSTRAINT IF EXISTS "fk_users_active_persona";`,
    );
    await q.query(`DROP TABLE IF EXISTS "personas";`);
    await q.query(`DROP TABLE IF EXISTS "refresh_tokens";`);
    await q.query(`DROP TABLE IF EXISTS "users";`);
  }
}
