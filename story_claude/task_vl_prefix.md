# Task: Add vl_ prefix to all backend DB tables except users

**User prompt:** I want add prefix to tables in backend api except users table

## What was done

Added `vl_` prefix to every TypeORM table name in the backend, leaving the `users` table unchanged.

### Entity files updated (15 files, 22 tables renamed)

| Old name | New name |
|---|---|
| achievements | vl_achievements |
| user_achievements | vl_user_achievements |
| admin_audit_log | vl_admin_audit_log |
| admin_permissions | vl_admin_permissions |
| admin_refresh_tokens | vl_admin_refresh_tokens |
| admins | vl_admins |
| app_config | vl_app_config |
| conversation_sessions | vl_conversation_sessions |
| conversation_messages | vl_conversation_messages |
| session_scores | vl_session_scores |
| courses | vl_courses |
| course_scenarios | vl_course_scenarios |
| guard_violations | vl_guard_violations |
| news_posts | vl_news_posts |
| news_read_status | vl_news_read_status |
| personas | vl_personas |
| refresh_tokens | vl_refresh_tokens |
| scenarios | vl_scenarios |
| skill_snapshots | vl_skill_snapshots |
| uploaded_files | vl_uploaded_files |
| user_progress | vl_user_progress |
| user_scenario_completions | vl_user_scenario_completions |

### Raw SQL updated

`backend/src/news/news.module.ts` — two raw SQL queries that referenced `news_posts` and `news_read_status` by name were updated to `vl_news_posts` and `vl_news_read_status`.

### Migration

`backend/src/database/migrations/1779800000000-add-vl-prefix.ts` — uses `ALTER TABLE IF EXISTS … RENAME TO` for each table. The `IF EXISTS` guard means running it on a fresh database (before seed) is safe.

Migration executed successfully:
```
Migration AddVlPrefix1779800000000 has been executed successfully.
```

## Commit

`c4ee615` feat: add vl_ prefix to all DB tables except users
