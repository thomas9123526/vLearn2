# I want erase all table contens for vLearn2 database, can you make a command or s

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-26T11:54:35.434Z

## User

I want erase all table contens for vLearn2 database, can you make a command or something like bat for it?
or is there another way to handle this properly?

## Assistant

Let me check what tables exist by looking at the migrations and entities.

## Assistant

I have all the tables. I'll create a SQL script + `.bat` that truncates everything (RESTART IDENTITY CASCADE) — everything except `typeorm_migrations` which must be kept so TypeORM doesn't re-run migrations on next start.

## Assistant

Two files created:

**[datamanage/reset_vlearn2_data.bat](datamanage/reset_vlearn2_data.bat)** — double-click or run from terminal; asks for `YES` confirmation before proceeding.

**[datamanage/reset_vlearn2_data.sql](datamanage/reset_vlearn2_data.sql)** — the actual SQL; you can also run it directly:
```
psql -U postgres -d vlearn2 -f datamanage/reset_vlearn2_data.sql
```

**What gets cleared** (TRUNCATE + RESTART IDENTITY CASCADE):
- `users`, `admins`, `refresh_tokens`, `admin_refresh_tokens`
- `conversation_sessions`, `conversation_messages`, `session_scores`, `guard_violations`
- `user_progress`, `user_achievements`, `user_scenario_completions`, `skill_snapshots`
- `news_read_status`, `uploaded_files`, `admin_audit_log`, `vl_user_info`

**What is preserved:**
- `typeorm_migrations` — must stay or TypeORM re-runs everything on next start
- `personas`, `scenarios`, `courses`, `achievements`, `news_posts` — seed/reference data
- `app_config`, `vl_prompt_templates`, `vl_categories`, `admin_permissions` — configuration
