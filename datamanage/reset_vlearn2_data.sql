-- reset_vlearn2_data.sql
-- Clears all application data in the vlearn2 database.
-- typeorm_migrations is preserved so TypeORM does not re-run migrations.
-- Run via: psql -U postgres -d vlearn2 -f reset_vlearn2_data.sql

BEGIN;

TRUNCATE TABLE
    -- user sessions & auth
    refresh_tokens,
    admin_refresh_tokens,
    -- conversation data
    guard_violations,
    session_scores,
    conversation_messages,
    conversation_sessions,
    -- progress & achievements
    user_achievements,
    user_scenario_completions,
    skill_snapshots,
    user_progress,
    -- social / news
    news_read_status,
    admin_audit_log,
    -- files
    uploaded_files,
    -- supplemental user tables
    vl_user_info,
    -- users & admins (last — others FK to these)
    users,
    admins
RESTART IDENTITY CASCADE;

-- Reference / seed tables are left intact:
--   personas, scenarios, courses, course_scenarios,
--   achievements, news_posts, vl_prompt_templates,
--   vl_categories, app_config, admin_permissions

COMMIT;

\echo 'vlearn2 data reset complete.'
