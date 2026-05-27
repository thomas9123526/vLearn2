-- reset_vlearn2_data.sql
-- Clears all user/session/admin data in the vlearn2 database.
-- Reference/config tables and vl_migrations are left intact.
-- Run via reset_vlearn2_data.bat, or:
--   psql -U postgres -d vlearn2 -f reset_vlearn2_data.sql

BEGIN;

-- vl_scenarios.author_id → users is ON DELETE SET NULL but TRUNCATE
-- doesn't fire row-level actions. Drop it, truncate, then restore.
ALTER TABLE vl_scenarios DROP CONSTRAINT scenarios_author_id_fkey;

TRUNCATE TABLE
    -- auth tokens
    vl_refresh_tokens,
    vl_admin_refresh_tokens,
    -- conversation data
    vl_guard_violations,
    vl_session_scores,
    vl_conversation_messages,
    vl_conversation_sessions,
    -- progress & achievements
    vl_user_achievements,
    vl_user_scenario_completions,
    vl_skill_snapshots,
    vl_user_progress,
    -- social / news
    vl_news_read_status,
    vl_admin_audit_log,
    -- files
    vl_uploaded_files,
    -- supplemental user tables
    vl_user_info,
    -- admin permissions (cleared with admins)
    vl_admin_permissions,
    -- users & admins
    users,
    vl_admins
RESTART IDENTITY;

-- Restore FK with original semantics
ALTER TABLE vl_scenarios
    ADD CONSTRAINT scenarios_author_id_fkey
    FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE SET NULL;

-- Tables left intact:
--   vl_personas, vl_scenarios, vl_courses, vl_course_scenarios,
--   vl_achievements, vl_news_posts, vl_prompt_templates,
--   vl_categories, vl_app_config, vl_migrations

COMMIT;

\echo 'vlearn2 data reset complete.'
