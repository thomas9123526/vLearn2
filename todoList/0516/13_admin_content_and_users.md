# 13 – Admin Content & User Management

The rest of the admin panel surface beyond the visibility flags in [§12](12_admin_visibility.md). All endpoints documented here land in the v1 NestJS backend; the **Next.js admin panel that consumes them is a separate future project**.

Scope: scenario / course / achievement / persona CRUD with image uploads · user listing and management · leaderboards · individual user drill-down · stats dashboard · audit trail unifying admin actions.

---

## 13.1 Goals & Scope

### Goals
- Admin can create, edit, archive **scenarios** (the conversational practice topics) including a hero image upload — without redeploying
- Admin can manage **users**: search, view profile, edit role/level, suspend, soft-delete
- Admin can view **leaderboards** ranked by various metrics for engagement analysis
- Admin can **drill into a single user**: session history, score trend, skill progression, guard violations, transcripts (privacy-gated)
- Admin sees an **overview dashboard** with DAU/MAU, signup funnel, engagement metrics
- Every admin write is **audited** in a single unified `admin_audit_log` table

### Non-Goals (v1)
- Bulk operations (multi-select edit/delete on the list views) — defer
- Announcements / push notifications to users (separate feature when notifications land)
- Custom report builder / SQL playground — power admins can read the DB directly
- Real-time monitoring (live session count, current online users) — polling-based dashboard is enough for v1
- ML-driven user segmentation — flat filters only

---

## 13.2 Content Management

### 13.2.1 Scenario CRUD

**Endpoints** (all require `role IN ('admin','superadmin')`):

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/admin/scenarios` | List with filters: `status`, `category`, `difficulty`, `q` (search), `page`, `limit` |
| GET | `/admin/scenarios/:id` | Full detail incl. unpublished |
| POST | `/admin/scenarios` | Create (status defaults to `draft`) |
| PATCH | `/admin/scenarios/:id` | Edit any field |
| POST | `/admin/scenarios/:id/publish` | `draft → published` |
| POST | `/admin/scenarios/:id/archive` | `published → archived` (no longer shown in app) |
| DELETE | `/admin/scenarios/:id` | Hard delete (allowed only if scenario has zero sessions referencing it; otherwise force archive) |
| POST | `/admin/scenarios/:id/image` | Upload hero image (multipart) — see §13.3 |
| DELETE | `/admin/scenarios/:id/image` | Remove hero image |

**Status machine:** `draft → published → archived` (one-way). Drafts only visible in admin panel. Published shown in app's `GET /scenarios`. Archived hidden from app but kept for historical session FK integrity.

**Image:** optional. Falls back to the scenario's emoji-based gradient placeholder (existing design) when no image is uploaded.

- [ ] **13.2.1.1** Add `image_url`, `image_storage_key`, `author_id`, `status`, `published_at` columns to `scenarios` (see §13.9)
- [ ] **13.2.1.2** App's existing `GET /scenarios` filters out `status != 'published'` automatically
- [ ] **13.2.1.3** Scenario validation on create/update: title/description/scene/roles/objectives all must have at least the `en` key; `ko` and `zh` can be empty (fallback to en in the app)
- [ ] **13.2.1.4** A `POST /admin/scenarios/:id/test` endpoint runs a single AI turn with the scenario's system prompt — lets admin sanity-check tutor behavior before publishing
- [ ] **13.2.1.5** Soft-validation: warn (don't block) when title contains profanity matched against §11 guard wordlist

### 13.2.2 Course CRUD

Parallel structure to scenarios. Endpoints under `/admin/courses/*`. Status machine same as scenarios. Add same image upload support if cover images become a thing later (v1: no images on courses, only on scenarios).

- [ ] **13.2.2.1** Endpoint set: list / get / create / patch / publish / archive / delete
- [ ] **13.2.2.2** `POST /admin/courses/:id/scenarios` adds a scenario to the course at a given `order_index`; `DELETE /admin/courses/:id/scenarios/:scenarioId` removes it
- [ ] **13.2.2.3** Reorder endpoint: `PATCH /admin/courses/:id/scenarios/order` accepts an ordered array of scenario IDs

### 13.2.3 Achievement CRUD

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/admin/achievements` | List all |
| POST | `/admin/achievements` | Create |
| PATCH | `/admin/achievements/:id` | Edit |
| DELETE | `/admin/achievements/:id` | Delete (hard — only if zero users have earned it; else archive) |
| POST | `/admin/users/:userId/achievements/:achievementId/grant` | Manually grant an achievement to a user (`superadmin` only) |
| DELETE | `/admin/users/:userId/achievements/:achievementId` | Revoke (`superadmin` only) |

- [ ] **13.2.3.1** Achievement icon stays an emoji (existing design); no image upload needed for v1
- [ ] **13.2.3.2** Manual grant inserts into `user_achievements` and logs to `admin_audit_log`

### 13.2.4 Persona Management

Personas (Maya/Leo/Sofia/Theo) are currently 4 hardcoded seeded records. Admin editability is **optional** but useful when adding a fifth persona later.

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/admin/personas` | List incl. inactive |
| PATCH | `/admin/personas/:id` | Edit name, accent, style, specialties, colors |
| POST | `/admin/personas/:id/image` | Upload portrait (for chat header avatar — optional; falls back to gradient monogram) |
| POST | `/admin/personas/:id/deactivate` | `is_active=false` — hidden from app |
| POST | `/admin/personas/:id/activate` | `is_active=true` |

**Out of scope v1:** creating *new* personas. Adding a fifth persona requires more than DB data (Rive animation asset, voice pack for sherpa-onnx TTS). Defer until those assets exist.

- [ ] **13.2.4.1** Endpoints scaffolded; only patch/image/activate flags work in v1 (no POST /admin/personas)
- [ ] **13.2.4.2** App's `GET /personas` filters `is_active=true`

### 13.2.5 Profanity Wordlist Editing

Cross-reference to [§11.1.8](11_security_and_performance.md). The `custom.json` wordlist file is admin-editable:

- [ ] **13.2.5.1** `GET /admin/guard/wordlists` returns current state of each language file + custom.json
- [ ] **13.2.5.2** `PATCH /admin/guard/wordlists/custom` accepts `{block: [...], warn: [...]}` to replace custom.json
- [ ] **13.2.5.3** `POST /admin/guard/reload` reloads wordlists from disk into memory without restart
- [ ] **13.2.5.4** Changes audit-logged with the full diff

---

## 13.3 File Upload Infrastructure

Used by §13.2 (scenarios, personas) and any future admin-uploaded asset.

### 13.3.1 Storage Provider Abstraction

Same pattern as the AI provider abstraction in [§9.2](09_ai_integration.md).

**File:** `backend/src/storage/storage-provider.interface.ts`

```typescript
export interface UploadedFile {
  storageKey: string;       // opaque identifier for this provider
  publicUrl: string;        // URL the app uses to fetch
  sizeBytes: number;
  mimeType: string;
  width?: number;
  height?: number;
}

export abstract class StorageProvider {
  abstract upload(buffer: Buffer, opts: {
    mimeType: string;
    originalFilename: string;
    folder: string;            // 'scenarios' | 'personas' | etc
  }): Promise<UploadedFile>;
  
  abstract delete(storageKey: string): Promise<void>;
  
  abstract resolveUrl(storageKey: string): string;
}
```

**Implementations (v1 ships only Local; S3 stub for forward-compat):**

| Provider | When to use | Config |
|----------|------------|--------|
| `LocalStorageProvider` | Single-host dev + small prod | `LOCAL_UPLOAD_DIR=./uploads` + `PUBLIC_BASE_URL=http://localhost:3000` |
| `S3StorageProvider` | Multi-host prod, CDN-fronted | `S3_BUCKET`, `S3_REGION`, `S3_ACCESS_KEY`, `S3_SECRET_KEY`, `S3_PUBLIC_BASE_URL` |

Toggle via `STORAGE_PROVIDER=local|s3` in `.env`.

- [ ] **13.3.1.1** Define interface, implement `LocalStorageProvider`, scaffold `S3StorageProvider` with a clear "not implemented v1" comment + tests
- [ ] **13.3.1.2** `LocalStorageProvider` serves uploads at `<PUBLIC_BASE_URL>/uploads/<path>` via Express static middleware
- [ ] **13.3.1.3** Storage provider factory injects the chosen impl based on env (parallels AiProviderFactory)

### 13.3.2 Image Processing Pipeline

**File:** `backend/src/storage/image-processor.service.ts`

Every image upload runs through this pipeline before being stored:

```
multipart upload
  ↓
validate: MIME type ∈ {image/jpeg, image/png, image/webp}; size ≤ 5 MB; magic-byte check (not just header)
  ↓
strip EXIF metadata (privacy + smaller file size)
  ↓
resize: if max(width, height) > 1920 → resize to fit 1920 keeping aspect ratio
  ↓
re-encode to WebP (better compression than JPEG/PNG) at quality 80
  ↓
generate thumbnail variant (300×300 cover-crop) for list views
  ↓
hash content (SHA-256) for dedup
  ↓
storage.upload() — writes both full + thumbnail; returns storage keys
  ↓
record in uploaded_files table
```

Library: [`sharp`](https://www.npmjs.com/package/sharp) — fastest Node image lib.

- [ ] **13.3.2.1** Reject non-image uploads with magic-byte mismatch (defends against renamed scripts)
- [ ] **13.3.2.2** Reject animated images (animated GIF / WebP) — static only for v1
- [ ] **13.3.2.3** Max upload: 5 MB before resize; max output ~300 KB after compression
- [ ] **13.3.2.4** Thumbnail variant stored at `<key>_thumb.webp`; full at `<key>.webp`
- [ ] **13.3.2.5** SHA-256 dedup: if hash exists in `uploaded_files`, reuse the existing storage key + bump a reference counter

### 13.3.3 File Upload Endpoints

Multipart endpoints follow this pattern:

```http
POST /admin/scenarios/:id/image
Content-Type: multipart/form-data; boundary=...
Authorization: Bearer <admin token>

(form fields)
file: <binary>
alt_text: "Optional alt text for accessibility"
```

Response:
```json
{
  "imageUrl": "https://cdn.example.com/uploads/scenarios/abc123.webp",
  "thumbnailUrl": "https://cdn.example.com/uploads/scenarios/abc123_thumb.webp",
  "sizeBytes": 287433,
  "width": 1920,
  "height": 1080
}
```

- [ ] **13.3.3.1** Use NestJS's built-in `FileInterceptor` from `@nestjs/platform-express`
- [ ] **13.3.3.2** Stream the file through the pipeline (don't buffer entire 5 MB in memory if avoidable)
- [ ] **13.3.3.3** Both full and thumbnail URLs returned in response
- [ ] **13.3.3.4** Cleanup on failure: if storage.upload() succeeds but DB write fails, the orphaned blob is deleted

### 13.3.4 Static File Serving (Local Provider)

When `STORAGE_PROVIDER=local`:

- [ ] **13.3.4.1** Mount `express.static('./uploads', { maxAge: '7d' })` at `/uploads`
- [ ] **13.3.4.2** `Cache-Control: public, max-age=604800` on responses
- [ ] **13.3.4.3** `ETag` headers enabled so the app's HTTP cache works correctly
- [ ] **13.3.4.4** No directory listing

---

## 13.4 User Management

### 13.4.1 List Users

`GET /admin/users`

Query parameters:
| Param | Type | Notes |
|-------|------|-------|
| `q` | string | Search across `email` + `display_name` (ILIKE) |
| `status` | string | `active` / `suspended` / `deleted` |
| `role` | string | `user` / `admin` / `superadmin` |
| `min_level` / `max_level` | int 1–6 | Filter by `current_level` |
| `language` | string | `ui_language` |
| `signed_up_since` / `signed_up_before` | ISO date | |
| `active_since` | ISO date | `last_active_date >= since` |
| `sort` | string | `xp_desc` (default) / `xp_asc` / `created_desc` / `streak_desc` / `level_desc` |
| `page` | int | default 1 |
| `limit` | int | default 50, max 200 |

Response:
```json
{
  "users": [
    {
      "id": "...", "email": "...", "displayName": "...",
      "role": "user", "status": "active",
      "level": 3, "xpTotal": 1850, "streak": 7,
      "uiLanguage": "ko",
      "lastActiveDate": "2026-05-15",
      "createdAt": "2026-03-01T..."
    }
  ],
  "page": 1, "limit": 50, "total": 1234
}
```

- [ ] **13.4.1.1** SQL uses indexed columns; full-text search on email/display_name limited to ILIKE prefix for v1 (no pg_trgm)
- [ ] **13.4.1.2** Excludes `password_hash`, `active_persona_id` (joined separately if needed), refresh tokens, etc — only safe fields exposed

### 13.4.2 View User Profile (Drill-down)

`GET /admin/users/:id`

Comprehensive view combining multiple resources in one response (avoids the admin panel making 10 round-trips):

```json
{
  "user": { ...all safe fields },
  "progress": { ...same shape as /users/profile },
  "activePersona": { ... },
  "recentSessions": [...last 10],
  "sessionStats": { "total": N, "completedLast30d": N, "avgScore": N },
  "skillTrend": [ ...last 8 weekly snapshots ],
  "guardViolationCount": { "block": N, "warn": N, "last7d": N },
  "achievements": [...earned ones]
}
```

- [ ] **13.4.2.1** Endpoint composes results; admin panel renders sections as needed
- [ ] **13.4.2.2** Excludes session **transcripts** (those go through a separate audited endpoint — see §13.6.5)

### 13.4.3 Edit User

`PATCH /admin/users/:id`

Editable fields by role:

| Field | Admin | Superadmin |
|-------|-------|------------|
| `display_name` | ✅ | ✅ |
| `avatar_emoji` | ✅ | ✅ |
| `ui_language` | ✅ | ✅ |
| `active_theme` | ✅ | ✅ |
| `active_persona_id` | ✅ | ✅ |
| `current_level` | ❌ | ✅ (rare manual correction) |
| `xp_total` | ❌ | ✅ (rare manual correction) |
| `role` | ❌ | ✅ |
| `email` | ❌ | ✅ (rare — most cases user changes via auth flow) |

- [ ] **13.4.3.1** Authorize per-field: admin endpoint rejects attempts to modify superadmin-only fields with 403
- [ ] **13.4.3.2** Audit log records `old_value` / `new_value` per field

### 13.4.4 Suspend / Restore / Soft-Delete

| Endpoint | Effect |
|----------|--------|
| `POST /admin/users/:id/suspend` body: `{until: <ISO datetime>, reason: string}` | `status='suspended'`, `suspended_until` set, `suspended_reason` set. Suspended users see "Your account is suspended until X" on next request and cannot sign in |
| `POST /admin/users/:id/restore` | `status='active'`, clear suspended_* fields |
| `DELETE /admin/users/:id` | Soft-delete: `status='deleted'`, scramble email/display_name, revoke refresh tokens. User data retained but inaccessible from app |

- [ ] **13.4.4.1** `JwtAuthGuard` rejects requests from users with `status != 'active'` with 401 + `{i18nKey: 'account.suspended'}`
- [ ] **13.4.4.2** Hard delete is **not** exposed via API — done manually by DBA if GDPR/CCPA right-to-erasure request lands
- [ ] **13.4.4.3** Suspension shows the reason in app's sign-in error screen

---

## 13.5 Leaderboards

### 13.5.1 Endpoints

`GET /admin/leaderboard?metric=<m>&limit=50&lang=<lang>&since=<iso>`

Metrics:
| Metric | Source | Window |
|--------|--------|--------|
| `xp` | `users.xp_total` | All-time |
| `xp_30d` | sum of `session_scores.xp` for sessions in last 30 days | Rolling |
| `level` | `users.current_level` desc, `xp_total` desc as tiebreak | All-time |
| `streak` | `users.streak_days` | Current |
| `longest_streak` | `user_progress.longest_streak` | All-time |
| `skill.pronunciation` | latest `skill_snapshots.pronunciation` | Latest snapshot |
| `skill.fluency` / `skill.vocabulary` / `skill.grammar` / `skill.listening` | same shape | Latest snapshot |
| `sessions_30d` | count of `conversation_sessions` in last 30 days | Rolling |

Filters:
| Filter | Effect |
|--------|--------|
| `lang` | filter to users with `ui_language=<lang>` |
| `since` | filter to users active since date |
| `min_level` / `max_level` | level bucket |

Response: same shape as `GET /admin/users` but ordered by the metric.

- [ ] **13.5.1.1** Each metric backed by an indexed query — verify EXPLAIN ANALYZE on a 100k-user fixture
- [ ] **13.5.1.2** Materialized view for the most expensive ones (xp_30d, sessions_30d) refreshed nightly via cron
- [ ] **13.5.1.3** Pagination via `page` + `limit`, default 50

### 13.5.2 Privacy Note for Future Public Leaderboard

If you later expose leaderboards to end users (gamification feature), add a `users.leaderboard_opt_in` boolean. Admin endpoints ignore this flag (admins see everyone). Public endpoints would honor it (only show opted-in users). Out of scope for v1; the admin endpoint sees all users.

---

## 13.6 Individual User Drill-down

### 13.6.1 Session History

`GET /admin/users/:userId/sessions?page=1&limit=50&status=completed`

Returns paginated session list with scores + scenario name + duration. **Does not** include transcripts (that's §13.6.5).

### 13.6.2 Score Trend

`GET /admin/users/:userId/scores/trend?since=<iso>`

Returns time-series array `[{date, overall, pronunciation, fluency, vocabulary, grammar, listening, engagement}, ...]` from `session_scores` joined to `conversation_sessions`, bucketed by day. Powers charts in the admin panel.

### 13.6.3 Skill Radar Snapshots

`GET /admin/users/:userId/skills/snapshots?limit=12`

Last N weekly snapshots from `skill_snapshots` — drives a "trend over time" view.

### 13.6.4 Guard Violations

`GET /admin/users/:userId/violations?since=<iso>&severity=<sev>`

Returns rows from `guard_violations` for moderation review.

- [ ] **13.6.4.1** Excludes the `attempted_content` field for `admin` role — only severity + matched terms shown
- [ ] **13.6.4.2** `superadmin` role sees full `attempted_content`
- [ ] **13.6.4.3** Every read of `attempted_content` audit-logged with admin user_id + violation_id

### 13.6.5 Transcript Viewing (Superadmin only, audited)

The most privacy-sensitive surface. Users wrote private conversations with the AI tutor — they expect them to stay private.

`GET /admin/users/:userId/sessions/:sessionId/transcript`

| Role | Behavior |
|------|----------|
| `admin` | **403 Forbidden** |
| `superadmin` | Returns full message list + warning banner copy ("Reading this transcript is logged. Do so only for safety / moderation purposes.") |

- [ ] **13.6.5.1** Strict role gate — admin role cannot reach this endpoint at all
- [ ] **13.6.5.2** Every successful read inserts into `admin_audit_log` with action='transcript_view', target_type='session', target_id=sessionId
- [ ] **13.6.5.3** Admin panel UI shows a confirmation modal before fetching: "This action will be logged"
- [ ] **13.6.5.4** Optional future feature: notify the user that an admin viewed their transcript (transparency)

---

## 13.7 Stats Dashboard

`GET /admin/stats`

Single endpoint returning overview metrics for the admin home page.

```json
{
  "users": {
    "total": 12450,
    "newToday": 23,
    "new7d": 156,
    "new30d": 612,
    "active7d": 3201,         // logged a session in last 7 days
    "active30d": 8540,
    "byLevel": { "A1": 5200, "A2": 3100, "B1": 2400, "B2": 1100, "C1": 480, "C2": 170 },
    "byLanguage": { "en": 6200, "ko": 3800, "zh": 2450 },
    "byStatus": { "active": 12100, "suspended": 50, "deleted": 300 }
  },
  "sessions": {
    "total": 84200,
    "today": 412,
    "7d": 3201,
    "30d": 14800,
    "avgDurationSeconds": 287,
    "completionRate": 0.84   // completed / (completed + abandoned)
  },
  "scenarios": {
    "total": 24,
    "topByCompletions": [
      { "id": "...", "title": "Ordering at a café", "completions": 4210 },
      ...
    ]
  },
  "moderation": {
    "guardViolationsToday": 12,
    "guardViolations7d": 88,
    "suspendedUsers": 50
  },
  "generatedAt": "2026-05-16T..."
}
```

- [ ] **13.7.1** Backed by aggregation queries; cached 60 seconds in-memory to avoid hammering the DB on dashboard refresh
- [ ] **13.7.2** All queries indexed; verify EXPLAIN ANALYZE on a representative dataset
- [ ] **13.7.3** Returns 200 with partial data + a `degraded: true` field if any sub-query times out (avoids whole dashboard breaking when one count is slow)

---

## 13.8 Privacy & Audit

### 13.8.1 Audit Coverage Matrix

Every admin write goes into `admin_audit_log` (replaces `config_audit_log` from §12). Reads of sensitive data also audited.

| Action | Audited? | Reason |
|--------|----------|--------|
| Config flag update / reset | ✅ | From §12 |
| Scenario create / update / publish / archive / delete | ✅ | Content history |
| Image upload | ✅ | Track who uploaded what |
| Achievement create / update / delete / manual grant | ✅ | XP/economy integrity |
| User edit (any field) | ✅ | Per-field old/new |
| User suspend / restore / soft-delete | ✅ | With reason |
| Wordlist update / reload | ✅ | Compliance / safety |
| **Transcript view** (superadmin) | ✅ | Privacy |
| Guard violation full-content view | ✅ | Privacy |
| User listing query | ❌ | Too noisy; aggregated daily logs at infrastructure level instead |
| Profile view | ❌ | Too noisy |
| Stats dashboard view | ❌ | Too noisy |

### 13.8.2 admin_audit_log Table (Generalizes config_audit_log from §12)

The §12 file mentions a `config_audit_log` table. This is generalized into `admin_audit_log` so a single table captures every admin action regardless of domain.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| user_id | UUID FK → users.id | the admin who acted |
| action | VARCHAR(50) | `config.update` / `scenario.create` / `user.edit` / `user.suspend` / `transcript.view` / etc — dot-namespaced |
| target_type | VARCHAR(20) | `config` / `scenario` / `course` / `achievement` / `persona` / `user` / `session` / `wordlist` / `image` |
| target_id | VARCHAR(100) | flexible identifier (UUID for entities, key string for config) |
| old_value | JSONB nullable | redacted (no PII spillage) |
| new_value | JSONB nullable | redacted |
| metadata | JSONB nullable | extra context: { reason, ip_address, user_agent, ... } |
| created_at | TIMESTAMPTZ default now() | |

Indexes:
```sql
CREATE INDEX idx_admin_audit_log_user_time ON admin_audit_log(user_id, created_at DESC);
CREATE INDEX idx_admin_audit_log_target ON admin_audit_log(target_type, target_id, created_at DESC);
CREATE INDEX idx_admin_audit_log_action_time ON admin_audit_log(action, created_at DESC);
```

- [ ] **13.8.2.1** Drop the `config_audit_log` table planned in §12; the equivalent records land in `admin_audit_log` with `target_type='config'`
- [ ] **13.8.2.2** Update [12 §12.4.8](12_admin_visibility.md) reference to point at `admin_audit_log`
- [ ] **13.8.2.3** Audit interceptor at the NestJS level captures every `@AuditAction(...)`-annotated controller method automatically (no manual log calls in business code)

### 13.8.3 Retention & Export

- [ ] **13.8.3.1** Audit log rows retained indefinitely by default; admin can manually purge older than N days via `DELETE /admin/audit?before=<iso>` (`superadmin` only)
- [ ] **13.8.3.2** `GET /admin/audit?since=<iso>&user_id=<uid>&action=<a>&target_type=<t>&limit=200` for searching the log
- [ ] **13.8.3.3** Export to CSV: `GET /admin/audit/export?format=csv&since=<iso>` returns a streaming CSV

---

## 13.9 DB Schema Additions

### Scenarios — new columns
| Column | Type | Default | Notes |
|--------|------|---------|-------|
| `image_url` | VARCHAR(500) | nullable | served by storage provider |
| `image_storage_key` | VARCHAR(255) | nullable | internal pointer for delete |
| `image_alt_text` | VARCHAR(500) | nullable | accessibility |
| `author_id` | UUID FK → users.id | nullable | admin who created (null for seeded) |
| `status` | VARCHAR(20) | `'published'` | `draft` / `published` / `archived` |
| `published_at` | TIMESTAMPTZ | nullable | set when status flips to published |

(Existing `is_active` column is now redundant with `status`; migration: `is_active=false → status='archived'`.)

### Users — new columns
| Column | Type | Default | Notes |
|--------|------|---------|-------|
| `status` | VARCHAR(20) | `'active'` | `active` / `suspended` / `deleted` |
| `suspended_until` | TIMESTAMPTZ | nullable | NULL means indefinite when status=suspended |
| `suspended_reason` | TEXT | nullable | shown to user on sign-in error |
| `leaderboard_opt_in` | BOOLEAN | `true` | reserved for future public leaderboard; admin endpoints ignore |

### Courses, Personas — new columns
Same `status` + `image_url` / `image_storage_key` columns where applicable. Personas already have `is_active` — migrate similarly.

### uploaded_files table (new)
Single source of truth for every uploaded asset across all admin-uploaded content.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| storage_key | VARCHAR(255) | UNIQUE — provider's blob identifier |
| original_filename | VARCHAR(500) | for audit trail |
| mime_type | VARCHAR(50) | post-processing |
| size_bytes | INTEGER | post-processing |
| width | INTEGER | nullable |
| height | INTEGER | nullable |
| content_hash | VARCHAR(64) | SHA-256 for dedup |
| reference_count | INTEGER | default 1 — drives garbage collection |
| uploader_id | UUID FK → users.id | the admin who uploaded |
| folder | VARCHAR(50) | `scenarios` / `personas` / etc |
| storage_provider | VARCHAR(20) | `local` / `s3` |
| created_at | TIMESTAMPTZ | |

Index:
```sql
CREATE INDEX idx_uploaded_files_hash ON uploaded_files(content_hash);
```

### admin_audit_log table (new — replaces config_audit_log from §12)
Schema in §13.8.2 above.

---

## 13.10 Implementation Checklist (Backend, v1)

- [ ] **13.10.1** Migrations: add `status` + suspension columns to users; add image + status + author columns to scenarios; add same to courses + personas as applicable
- [ ] **13.10.2** Create `uploaded_files` and `admin_audit_log` tables
- [ ] **13.10.3** Drop the planned `config_audit_log` table (it never shipped; rolled into `admin_audit_log`)
- [ ] **13.10.4** `StorageProvider` interface + `LocalStorageProvider` impl + S3 stub + factory
- [ ] **13.10.5** `ImageProcessor` service using `sharp` — resize + EXIF strip + WebP re-encode + thumbnail + SHA-256 dedup
- [ ] **13.10.6** `AdminScenariosModule` — list / get / create / patch / publish / archive / delete / image upload-delete / test endpoints
- [ ] **13.10.7** `AdminCoursesModule` — parallel structure to scenarios + scenario-membership endpoints
- [ ] **13.10.8** `AdminAchievementsModule` + manual grant/revoke
- [ ] **13.10.9** `AdminPersonasModule` — patch + image + activate/deactivate (no create v1)
- [ ] **13.10.10** `AdminUsersModule` — list / get / patch / suspend / restore / soft-delete + drill-down endpoints (sessions / scores trend / skill snapshots / violations / transcript)
- [ ] **13.10.11** `AdminLeaderboardModule` — single endpoint with metric switch; cron job refreshes materialized views for `xp_30d` and `sessions_30d`
- [ ] **13.10.12** `AdminStatsModule` — `/admin/stats` with in-memory 60s cache
- [ ] **13.10.13** `AdminAuditModule` — search + export + retention; `@AuditAction()` decorator + interceptor for automatic logging
- [ ] **13.10.14** Update §12's `AdminConfigController` to log into `admin_audit_log` (action prefix: `config.*`) instead of the dropped `config_audit_log` table
- [ ] **13.10.15** Permission-based authorization helpers come from [14](14_admin_permissions.md): `PermissionGuard` + `@RequirePermission()` decorator. Every admin controller method in §13 declares its required permission per the [§14.8 mapping table](14_admin_permissions.md). The previous "admin / superadmin" coarse split is replaced by the granular catalog

## 13.11 Implementation Checklist (App-side awareness, v1)

The Flutter app mostly stays unchanged — most of §13 is admin-side. But a few app-facing pieces need attention:

- [ ] **13.11.1** Sign-in error path: when 401 returns `{i18nKey: 'account.suspended', suspendedUntil, reason}`, app shows a friendly suspension screen with the reason and unsuspend date
- [ ] **13.11.2** `GET /scenarios` continues to filter `status='published'` — app users never see drafts/archived
- [ ] **13.11.3** Scenario card UI checks for `image_url` and shows the photo; falls back to the existing gradient + emoji placeholder when null
- [ ] **13.11.4** Add `scenarioCardImage` to scenarios_cache Drift schema (TextColumn nullable)
- [ ] **13.11.5** New i18n keys: `accountSuspendedTitle`, `accountSuspendedBody`, `accountSuspendedUntil`

---

## 13.12 Future Considerations (Out of Scope for v1)

| Idea | Why deferred |
|------|--------------|
| In-app push notifications / admin announcements | Notification infrastructure isn't built yet — separate v2 effort |
| Public-facing leaderboards (user opt-in) | Has `leaderboard_opt_in` column reserved; UX and abuse mitigation are real work |
| ML-driven user segmentation | Too speculative without traffic |
| Custom report builder | DBA can SQL the warehouse |
| Real-time live-session monitor | Doesn't justify the WebSocket infra |
| Multi-tenant / org accounts | Single-tenant for v1; orgs would touch users/scenarios/courses heavily |
| Webhook subscriptions for admin events | Useful for org integrations; deferred until needed |
