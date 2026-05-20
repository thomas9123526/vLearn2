# I want know Audit log tabs of admin panel. I'm new to concept. What tables are r

Session: `859710bb-e71a-42d3-b4d0-af5e037a10f3`
Saved: 2026-05-20T09:24:12.305Z

## User

I want know Audit log tabs of admin panel. I'm new to concept. What tables are related?
and how the audit log works and when "audit log tabs" show the content?

## Assistant

Re-answering this so it lands as a self-contained file via the save-conversation hook.

## Short answer

The Audit log is **scaffolded but not implemented**. The DB table exists, the permission key exists, the menu item exists, but nothing writes audit rows and nothing reads them — so the tab always shows a placeholder. There is **one** related table.

## What an audit log is (the concept)

An admin audit log records every privileged action an admin performs — *who* did *what* to *which* record, *when*, and *what changed*. It's append-only (every action is a new row; rows are never updated or deleted). It's used for:
- **Accountability** — "who suspended this user?"
- **Forensics** — "when was this scenario deleted, and by whom?"
- **Compliance** — required for SOC2 / GDPR / etc.

## The one related table

**`vl_admin_audit_log`** (was `admin_audit_log` before the `vl_`-prefix migration). TypeORM mapping: [AdminAuditLogEntity](backend/src/database/entities/admin-audit-log.entity.ts).

| Column | Type | Meaning |
|---|---|---|
| `id` | uuid PK | row id |
| `user_id` | uuid, FK → `vl_admins.id` (ON DELETE SET NULL) | *who* did it |
| `action` | varchar(50) | short verb — `"suspend"`, `"grant_permissions"`, `"update_prompt"`, etc. |
| `target_type` | varchar(20) | kind of thing acted on — `"user"`, `"scenario"`, `"prompt_template"` |
| `target_id` | varchar(100) | id of the target row (varchar so non-uuid targets work) |
| `old_value` | jsonb | snapshot before the change |
| `new_value` | jsonb | snapshot after the change |
| `metadata` | jsonb | optional extras (IP, reason, etc.) |
| `created_at` | timestamptz | when |

Schema created in [1715800000000-initial-schema.ts:325-339](backend/src/database/migrations/1715800000000-initial-schema.ts#L325-L339); three composite indexes (by actor+time, by target+time, by action+time) cover the typical query patterns. The FK was re-pointed when admins were split out from users — see [1779100000000-admins-separate-table.ts:87-95](backend/src/database/migrations/1779100000000-admins-separate-table.ts#L87-L95).

## How it works *today*

It doesn't. Three pieces are missing:

1. **No writer.** Grep for `AdminAuditLogEntity` finds only the entity file, the entity index, and the migrations. No service injects the repository; no controller inserts rows. Every Suspend / Grant / Edit-prompt / Update-scenario action runs without writing an audit row. The table is **empty** in any running instance.
2. **No reader.** No `GET /admin/audit` endpoint exists. The permission key [`audit.view`](backend/src/admin/permissions/catalog.ts#L48) exists in the catalog (so it appears in the Edit Permission dialog under Analytics), but it currently gates a page that fetches nothing.
3. **The tab is a literal stub.** [audit/page.tsx:14-22](admin_panel/src/app/(dashboard)/audit/page.tsx#L14-L22) renders a card whose body says:
   > *"The `admin_audit_log` table already exists in the DB, but no `/admin/audit` endpoint reads it yet. When that ships, this page will paginate with filters by actor / action / target / date range."*

## When does the tab show content?

**Never, currently.** The placeholder renders no matter who you are or what's happened.

It would start showing rows after someone implements:
1. **`AdminAuditLogService.record(...)`** on the backend — injects `Repository<AdminAuditLogEntity>` and INSERTs.
2. **Call sites** — every mutating admin endpoint calls `.record(...)` after its DB write. The minimum useful set: `AdminAdminsController.{suspend, restore, replacePerms, create, softDelete}`, `AdminPromptTemplatesController.update`, `AdminScenariosController.{create, update, publish, delete}`, `AdminPersonasController.update`, `AdminNewsController.{create, update, delete}`.
3. **`GET /admin/audit`** — paginated, filterable by `user_id` / `action` / `target_type` + `target_id` / date range, gated by `@RequirePermission('audit.view')`.
4. **Replace the placeholder** in `audit/page.tsx` with a TanStack-Query table + filter controls hitting the new endpoint.

Roughly one focused session of work for a v1.
