# why vl_users?  users table only don't have  prefix for "vl_"

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-20T18:46:45.222Z

## User

why vl_users?  users table only don't have  prefix for "vl_"

## Assistant

Let me check whether the `vl_` prefix is consistent across all tables.

## Assistant

You're right — that's an inconsistency in our schema. Looking at every `@Entity` in `backend/src/database/entities/`:

| Table | Entity file |
|---|---|
| **`users`** | [user.entity.ts:14](backend/src/database/entities/user.entity.ts#L14) — **no prefix** |
| `vl_user_info` | user-info.entity.ts:12 |
| `vl_admins`, `vl_admin_audit_log`, `vl_admin_permissions`, `vl_admin_refresh_tokens` | admin-*.entity.ts |
| `vl_achievements`, `vl_user_achievements` | achievement.entity.ts |
| `vl_conversation_sessions`, `vl_conversation_messages`, `vl_session_scores` | conversation.entity.ts |
| `vl_categories`, `vl_scenarios`, `vl_courses`, `vl_course_scenarios` | category/scenario/course |
| `vl_personas`, `vl_news_posts`, `vl_news_read_status` | persona/news |
| `vl_progress_*`, `vl_user_scenario_completions`, `vl_skill_snapshots` | progress |
| `vl_app_config`, `vl_prompt_templates`, `vl_refresh_tokens`, `vl_uploaded_files`, `vl_guard_violations` | misc |

**24 tables with `vl_`, exactly one without — `users`.** It's almost certainly an oversight from when the prefix convention was introduced. There's no functional reason `users` was excluded — every join in `auth.service.ts` (e.g. the eager `user.info` from `vl_user_info`) crosses the boundary already.

Also: that means the SQL I gave you in the previous turn was wrong on the table name. Corrected version:

```sql
SELECT u.id, u.cid_username, u.cid, ui.status
FROM users u                          -- not vl_users
LEFT JOIN vl_user_info ui ON ui.user_id = u.id
WHERE u.cid_username ILIKE '<what-you-typed>';
```

Want me to fix the inconsistency? It'd be a small migration that renames `users` → `vl_users`, plus one-line updates in the entity decorator and a few raw-SQL spots I'd need to grep for. Mid-blast-radius (changes the production table name), so I want to confirm before touching it.
