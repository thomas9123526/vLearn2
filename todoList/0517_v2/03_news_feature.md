# 03 — News feature (subadmin uploads + home-screen list + bell-icon notifications)

New domain spanning backend (DB + module + endpoints + permissions), Flutter (home-screen widget + bell dropdown + mark-read flow), and admin panel (CRUD page).

## 3.1 Goals

- Subadmins (with `news.edit` permission) can create, edit, publish, and archive news posts
- Each post has multi-language title + body + optional hero image + published_at
- App users see the news list on the home screen — a horizontal strip or section above (or near) the recommended scenarios
- A **bell icon** on the home screen shows an **unread count badge**; tapping opens a news list with a "Mark all read" action
- Per-user read state is tracked server-side so the unread count is consistent across devices

## 3.2 DB schema additions

### Table: `news_posts`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| slug | VARCHAR(150) | UNIQUE | URL-safe identifier |
| title | JSONB | NOT NULL | `{en, ko?, zh?}` per the existing I18nText pattern |
| body | JSONB | NOT NULL | `{en, ko?, zh?}`; body is markdown-able rich text |
| summary | JSONB | nullable | shorter teaser shown on home screen; falls back to truncated body |
| image_url | VARCHAR(500) | nullable | uploaded via `POST /admin/news/:id/image` (reuses the existing StorageProvider) |
| image_storage_key | VARCHAR(255) | nullable | |
| author_id | UUID | FK → users.id, ON DELETE SET NULL | admin who created |
| status | VARCHAR(20) | NOT NULL default `'draft'` | `draft` / `published` / `archived` |
| pinned | BOOLEAN | default false | pinned posts appear at the top of the list |
| published_at | TIMESTAMPTZ | nullable | set when status flips to `published` |
| created_at | TIMESTAMPTZ | default now() | |
| updated_at | TIMESTAMPTZ | default now() | |

Indexes:
```sql
CREATE INDEX idx_news_posts_status_published ON news_posts(status, published_at DESC);
CREATE INDEX idx_news_posts_pinned ON news_posts(pinned, published_at DESC) WHERE status = 'published';
```

### Table: `news_read_status`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| user_id | UUID | FK → users.id, ON DELETE CASCADE | |
| news_post_id | UUID | FK → news_posts.id, ON DELETE CASCADE | |
| read_at | TIMESTAMPTZ | default now() | |
| PRIMARY KEY | (user_id, news_post_id) | | |

The **absence** of a row means unread. Mark-all-read inserts rows in a single SQL `INSERT … SELECT … ON CONFLICT DO NOTHING`.

## 3.3 Permission catalog additions

Add to [backend/src/admin/permissions/catalog.ts](../../backend/src/admin/permissions/catalog.ts):

| Key | Category | Description | grantable_to_subadmin |
|-----|----------|-------------|-----------------------|
| `news.view` | content | List news posts including drafts | true |
| `news.edit` | content | Create, update, publish, archive news posts | true |
| `news.delete` | content | Permanently delete news posts | true |
| `news.upload_image` | content | Upload hero images for news posts | true |

## 3.4 Backend module

**File:** `backend/src/news/news.module.ts`

User-facing endpoints (any authenticated user):

| Method | Path | Returns |
|--------|------|---------|
| GET | `/news` | List published posts (pinned first, then `published_at DESC`); pagination via `?page=&limit=` (default 20); includes `read` boolean per row for the current user |
| GET | `/news/:idOrSlug` | Single post detail; marks `read_at` automatically on GET |
| POST | `/news/:id/read` | Idempotent mark-read (alternative to opening the detail page) |
| POST | `/news/read-all` | Bulk mark-read for everything currently in the list |
| GET | `/news/unread-count` | Single integer count for the bell-icon badge |

Admin endpoints (gated by `@RequirePermission`):

| Method | Path | Permission |
|--------|------|------------|
| GET | `/admin/news` | `news.view` (includes drafts) |
| GET | `/admin/news/:id` | `news.view` |
| POST | `/admin/news` | `news.edit` |
| PATCH | `/admin/news/:id` | `news.edit` |
| POST | `/admin/news/:id/publish` | `news.edit` |
| POST | `/admin/news/:id/archive` | `news.edit` |
| DELETE | `/admin/news/:id` | `news.delete` |
| POST | `/admin/news/:id/image` | `news.upload_image` |

- [ ] **3.4.1** Entities: `NewsPostEntity` + `NewsReadStatusEntity`
- [ ] **3.4.2** Migration adding both tables
- [ ] **3.4.3** `NewsService` with `listForUser(userId, {page, limit})`, `markRead`, `markAllRead`, `unreadCount(userId)`, plus admin CRUD methods
- [ ] **3.4.4** Image upload reuses `StorageProvider` + `ImageProcessor` (from [0516/13 §13.3](../0516/13_admin_content_and_users.md))
- [ ] **3.4.5** Audit logging on every admin write (`action: 'news.create' | 'news.update' | 'news.publish' | 'news.archive' | 'news.delete'`)
- [ ] **3.4.6** `NewsModule` imported into `AppModule`

## 3.5 Flutter — home screen integration

### 3.5.1 News strip on home screen

- [ ] **3.5.1.1** New `NewsApi` in `lib/core/api/app_apis.dart` — `list({page, limit})`, `get(idOrSlug)`, `markRead(id)`, `markAllRead()`, `unreadCount()`
- [ ] **3.5.1.2** `lib/core/models/models.dart` adds `NewsPost` model with `fromJson`
- [ ] **3.5.1.3** New widget `lib/features/home/widgets/news_strip.dart` — horizontal scroll, pinned posts highlighted with a small badge, tap → opens news detail
- [ ] **3.5.1.4** `home_screen.dart` shows the strip wrapped in `LayoutVisibility(configKey: 'home.news_strip', child: NewsStrip())`
- [ ] **3.5.1.5** Add flag `home.news_strip` to the seed catalog ([backend/src/database/seeds/seeds/app-config.seed.ts](../../backend/src/database/seeds/seeds/app-config.seed.ts))

### 3.5.2 Bell icon

The bell already exists in the home screen flag catalog (`home.notification_bell` — seeded). This task wires it up.

- [ ] **3.5.2.1** Top-right of the home AppBar: `BellIcon` widget with red badge showing `unreadCount` when > 0
- [ ] **3.5.2.2** Tap → push `lib/features/news/news_list_screen.dart` (full list with read/unread visual differentiation)
- [ ] **3.5.2.3** "Mark all read" action in the AppBar of the news list screen
- [ ] **3.5.2.4** Bell badge auto-refreshes every 60s via a `Stream.periodic` + `Riverpod` provider (or on screen-resume)

### 3.5.3 News detail screen

- [ ] **3.5.3.1** `lib/features/news/news_detail_screen.dart`
- [ ] **3.5.3.2** Renders hero image (or gradient fallback), title, published_at, body (markdown via `flutter_markdown`)
- [ ] **3.5.3.3** On open → `markRead(id)` (best-effort; ignore network failure)

### 3.5.4 i18n keys

Add to `app_en.arb` / `app_ko.arb` / `app_zh.arb`:
- `newsTitle`, `newsEmpty`, `newsMarkAllRead`, `newsUnreadBadge`, `newsPublishedOn`

## 3.6 Admin panel — News CRUD

(Builds on [todoList/0517_v2/02](02_admin_panel_nextjs.md))

- [ ] **3.6.1** `admin_panel/src/app/(dashboard)/news/page.tsx` — list view with status filter + pin toggle
- [ ] **3.6.2** `admin_panel/src/app/(dashboard)/news/new/page.tsx` — create form: title/body/summary tabs per language + image dropzone + pin checkbox
- [ ] **3.6.3** `admin_panel/src/app/(dashboard)/news/[id]/page.tsx` — edit + publish/archive/delete actions
- [ ] **3.6.4** Markdown editor for body (e.g. `@uiw/react-md-editor`); preview tab shows what the Flutter app will render

## 3.7 Verification

- [ ] **3.7.1** Create a news post via admin panel → publish → app user sees it on home + bell badge increments
- [ ] **3.7.2** Open detail → `read_at` recorded → badge decrements
- [ ] **3.7.3** Re-open detail → no second `read_at` row (idempotent)
- [ ] **3.7.4** Archive a post → it disappears from `GET /news` but still listed in admin panel
- [ ] **3.7.5** A sub-admin without `news.edit` cannot create posts (403 with `i18nKey: 'admin.missing_permission'`)

## 3.8 Honest call-outs

1. **No push notifications.** This is a pull-based system (bell shows unread count from a periodic poll). Real push requires FCM (Android) + WNS (Windows) infrastructure — separate, much larger effort. Out of scope for this task.
2. **No "send to specific users / segments".** Every published post is visible to every user. Targeting (e.g. only Korean-speaking users see localized posts) is a future enhancement.
3. **Markdown rendering** uses `flutter_markdown` which has a finite feature set (headings, lists, links, images, code blocks, blockquotes). No tables, no HTML embedding. Acceptable for news content.
4. **No comment / reply feature.** Out of scope. If users should be able to react to news, a separate `news_reactions` table arrives later.
5. **Hero image is optional** but recommended for visual appeal on the home strip. Without it, the strip falls back to a gradient + title-only card (same pattern as scenarios).
