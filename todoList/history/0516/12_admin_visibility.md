# 12 – Admin-Controlled Layout Visibility

A remote-config / feature-flag system that lets a (future) Next.js admin panel toggle the visibility — and a few other knobs — of UI sections in the Flutter app **without shipping a new APK**.

The app side (this v1) installs the visibility hooks everywhere they could be useful and reads flags from a cached config. The admin-panel side (later, in a separate Next.js project) is just a CRUD UI over the API the app already speaks.

---

## 12.1 Goals & Non-Goals

### Goals
- **Toggle UI sections remotely** — admin hides "Continue your course" card, or removes the "Listening" axis from the radar, without rebuilding the APK
- **Layered defaults** — every flag has a default baked into the app, so a config-fetch failure never breaks the UI
- **Cheap on the hot path** — config fetched once at app start and cached locally; widget visibility check is O(1)
- **Auditable** — every config change records who changed it and when (admin user, timestamp)
- **Forward-compatible** — boolean flags first; same schema supports strings/numbers/JSON for later knobs (e.g. "max recommended scenarios = 4")

### Non-Goals (v1)
- **Per-user overrides.** Flags are global. Future work: cohort/segment-based variants for A/B testing
- **Real-time push.** App polls on launch and every N minutes; no WebSocket invalidation
- **Conditional logic (rules engine).** No "show X only if user level >= 3" — flags are flat values; conditional UX stays in app code
- **The admin panel itself.** This file specifies the API the panel will consume; the Next.js project is a separate effort

---

## 12.2 Architecture at a Glance

```
┌────────────────────┐                ┌────────────────────┐
│  Next.js Admin     │   PATCH        │   NestJS Backend   │
│  (FUTURE project)  │ ─────────────► │   /admin/config/*  │
└────────────────────┘                │                    │
                                      │   app_config table │
┌────────────────────┐    GET         │                    │
│   Flutter App      │ ◄──────────── │   /app-config      │
│  LayoutConfig      │   (cached)     │                    │
│  Provider          │                └────────────────────┘
└─────────┬──────────┘
          │ wraps every flag-controlled section
          ▼
   LayoutVisibility(
     configKey: 'evaluation.radar.skills.pronunciation',
     fallback: true,  // baked default
     child: PronunciationAxisOnRadar(),
   )
```

---

## 12.3 Database Schema Additions

### Table: app_config

**File:** `backend/src/database/migrations/*-create-app-config.ts`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| key | VARCHAR(100) | PK | dot-namespaced (e.g. `evaluation.radar.skills.pronunciation`) |
| value | JSONB | NOT NULL | actual value; boolean for visibility flags, other types allowed |
| value_type | VARCHAR(20) | NOT NULL | `boolean` / `string` / `number` / `object` / `array` — for admin-panel UI hinting |
| category | VARCHAR(50) | NOT NULL | for admin panel grouping: `home` / `evaluation` / `progress` / `conversation` / `scenarios` / `settings` / `system` |
| description | TEXT | NOT NULL | human-readable purpose (shown in admin panel) |
| default_value | JSONB | NOT NULL | the app-baked default; lets admin reset / panel show "differs from default" |
| is_visible_to_app | BOOLEAN | default true | if false, key is admin-internal and not returned by `/app-config` |
| updated_at | TIMESTAMPTZ | default now() | |
| updated_by | UUID | FK → users.id, nullable | last admin who edited; null on initial seed |

Indexes:
```sql
CREATE INDEX idx_app_config_category ON app_config(category);
```

### Schema change to `users` — admin role

Add to existing `users` table:

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| role | VARCHAR(20) | NOT NULL, default `'user'` | `user` / `admin` / `superadmin` — drives access to `/admin/*` endpoints |

For v1, role flips happen via direct DB update (no admin-grant UI yet). The Next.js panel will rely on this column for auth checks.

---

## 12.4 Backend API

### App-facing endpoint (anyone authenticated)

**`GET /app-config`**

Returns all app-visible config in one shot. App polls this on launch + every 30 min if the app stays foregrounded.

```json
{
  "version": "2026-05-16T18:45:00Z",
  "flags": {
    "evaluation.radar.skills.pronunciation": true,
    "evaluation.radar.skills.fluency": true,
    "evaluation.radar.skills.vocabulary": true,
    "evaluation.radar.skills.grammar": true,
    "evaluation.radar.skills.listening": true,
    "evaluation.report.ai_feedback": true,
    "evaluation.report.confetti": true,
    "home.streak_banner": true,
    "home.continue_course": true,
    "home.recommended_scenarios": true,
    "home.notification_bell": true,
    "progress.weekly_chart": true,
    "progress.achievements": true,
    "conversation.mode_toggle": true,
    "settings.theme_selector": true,
    "settings.tutor_carousel": true
  }
}
```

- [ ] **12.4.1** Endpoint returns only rows where `is_visible_to_app = true`
- [ ] **12.4.2** `version` field is `MAX(updated_at)` across the table — lets the app skip applying if unchanged (`If-Modified-Since` semantics)
- [ ] **12.4.3** Cached at the backend in memory; cache busted on any admin write
- [ ] **12.4.4** Response gzipped if eligible (see [§11.2](11_security_and_performance.md))

### Admin endpoints (gated by `@RequirePermission()` per [14 §14.8](14_admin_permissions.md))

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/admin/config` | List ALL config (including admin-internal keys) — drives the admin panel UI |
| GET | `/admin/config/:key` | Single key with full metadata |
| PATCH | `/admin/config/:key` | Update value (records `updated_by`) |
| POST | `/admin/config/reset/:key` | Reset to `default_value` |
| POST | `/admin/config/reset-all` | Reset everything (`superadmin` only) |
| GET | `/admin/config/audit` | Recent config changes (last 100, with user + timestamp) |

- [ ] **12.4.5** `JwtAuthGuard + PermissionGuard` (per [14 §14.6](14_admin_permissions.md)) gate every admin controller method; each method declares `@RequirePermission('config.view'|'config.edit'|...)` per the §14.8 mapping table
- [ ] **12.4.6** JWT payload extended with `role` — issued on signin, refreshed on `/auth/refresh`
- [ ] **12.4.7** Validation: PATCH body's `value` must match the row's `value_type` (`boolean` keys reject non-bool)
- [ ] **12.4.8** Audit log: every admin write inserts into the unified `admin_audit_log` table with `action='config.update'|'config.reset'`, `target_type='config'`, `target_id=<key>`, `old_value`, `new_value`, `user_id`. Schema defined in [13_admin_content_and_users.md §13.8.2](13_admin_content_and_users.md)
- [ ] **12.4.9** CORS rule allows the admin-panel origin (separate from Flutter app origin)

### Bootstrap seed

On first `npm run db:seed`, populate the table with every key listed in §12.6 (Default Flag Catalog) using its baked default.

- [ ] **12.4.10** Seed file `backend/src/database/seeds/app-config.seed.ts` is the **single source of truth** for the default catalog
- [ ] **12.4.11** A migration runner that compares baked catalog to DB and inserts missing keys is run on every deploy (so new flags added in code show up in the admin panel automatically)

---

## 12.5 Flutter Integration

### LayoutConfigProvider (Riverpod)

**File:** `flutter_app/lib/core/config/layout_config_provider.dart`

```dart
class LayoutConfig {
  final Map<String, dynamic> flags;
  final DateTime fetchedAt;
  
  bool isVisible(String key, {bool fallback = true}) {
    final v = flags[key];
    return v is bool ? v : fallback;
  }
  
  T? get<T>(String key) => flags[key] is T ? flags[key] as T : null;
}

@riverpod
class LayoutConfigNotifier extends _$LayoutConfigNotifier {
  @override
  Future<LayoutConfig> build() async {
    // 1. Load defaults baked into the app
    final defaults = await _loadBakedDefaults();
    // 2. Try to read cached config from SQLite (offline-safe)
    final cached = await _readCache();
    // 3. Try to fetch fresh from /app-config (best-effort, never throws to caller)
    unawaited(_refreshInBackground());
    return cached ?? defaults;
  }
  
  Future<void> _refreshInBackground() async { /* fetches, updates state, persists to SQLite */ }
}
```

- [ ] **12.5.1** Defaults baked into `assets/config/defaults.json` (generated from §12.6 catalog at build time, OR maintained by hand if simpler)
- [ ] **12.5.2** Cached layer reads from a new SQLite table `layout_config_cache (key TEXT PK, value TEXT, fetched_at DATETIME)`
- [ ] **12.5.3** Background refresh: every app start + every 30 minutes when foregrounded
- [ ] **12.5.4** Never throws — config failures degrade gracefully to defaults
- [ ] **12.5.5** Settings → Debug section (dev-mode only) shows current resolved config + last fetched timestamp

### LayoutVisibility widget

**File:** `flutter_app/lib/shared/widgets/layout_visibility.dart`

```dart
class LayoutVisibility extends ConsumerWidget {
  final String configKey;
  final bool fallback;            // baked default; used if config not yet loaded
  final Widget child;
  final Widget? whenHidden;       // optional replacement (default: SizedBox.shrink)
  
  const LayoutVisibility({
    required this.configKey,
    this.fallback = true,
    required this.child,
    this.whenHidden,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(layoutConfigProvider).valueOrNull;
    final visible = config?.isVisible(configKey, fallback: fallback) ?? fallback;
    return visible ? child : (whenHidden ?? const SizedBox.shrink());
  }
}
```

Usage at the call site:

```dart
// In skill_radar_chart.dart:
final visibleSkills = [
  if (config.isVisible('evaluation.radar.skills.pronunciation')) skills.pronunciation,
  if (config.isVisible('evaluation.radar.skills.fluency'))       skills.fluency,
  if (config.isVisible('evaluation.radar.skills.vocabulary'))    skills.vocabulary,
  if (config.isVisible('evaluation.radar.skills.grammar'))       skills.grammar,
  if (config.isVisible('evaluation.radar.skills.listening'))     skills.listening,
];
// Radar renders with whatever axes are visible

// In home_screen.dart:
LayoutVisibility(
  configKey: 'home.continue_course',
  child: const ContinueCourseCard(),
);

LayoutVisibility(
  configKey: 'home.streak_banner',
  child: const StreakBanner(),
);
```

- [ ] **12.5.6** Wrap every section listed in §12.6 with `LayoutVisibility` or the equivalent inline check
- [ ] **12.5.7** Naming convention: `<screen-or-domain>.<section>[.<subsection>]` dot-namespaced
- [ ] **12.5.8** A lint rule (or pre-commit grep) ensures every `configKey` used in code exists in `assets/config/defaults.json`

---

## 12.6 Default Flag Catalog (v1)

Every key here lands in `app_config` via seed. Default is `true` (visible) unless noted.

### Evaluation domain
| Key | Type | Default | Controls |
|-----|------|---------|----------|
| `evaluation.radar.skills.pronunciation` | bool | true | Pronunciation axis on radar chart |
| `evaluation.radar.skills.fluency` | bool | true | Fluency axis |
| `evaluation.radar.skills.vocabulary` | bool | true | Vocabulary axis |
| `evaluation.radar.skills.grammar` | bool | true | Grammar axis |
| `evaluation.radar.skills.listening` | bool | true | Listening axis |
| `evaluation.report.overall_score_ring` | bool | true | Large score ring at top of report |
| `evaluation.report.score_breakdown` | bool | true | 4 animated bars (fluency / vocab / grammar / engagement) |
| `evaluation.report.xp_earned` | bool | true | "+N XP" count-up section |
| `evaluation.report.ai_feedback` | bool | true | Claude-generated paragraph |
| `evaluation.report.strengths` | bool | true | Green-icon strengths list |
| `evaluation.report.improvements` | bool | true | Amber-icon improvements list |
| `evaluation.report.confetti` | bool | true | Confetti burst on good score |
| `evaluation.report.share_button` | bool | true | Share to clipboard |

### Home domain
| Key | Type | Default | Controls |
|-----|------|---------|----------|
| `home.greeting` | bool | true | "Good morning, {name}" header |
| `home.streak_banner` | bool | true | 🔥 N day streak |
| `home.xp_progress` | bool | true | XP bar to next level |
| `home.continue_course` | bool | true | Course continuation card |
| `home.quick_stats` | bool | true | Sessions / Minutes / Scenarios row |
| `home.recommended_scenarios` | bool | true | Horizontal scroll of suggestions |
| `home.recent_activity` | bool | true | Last 3 sessions list |
| `home.notification_bell` | bool | true | Bell icon + dialog |

### Progress domain
| Key | Type | Default | Controls |
|-----|------|---------|----------|
| `progress.level_badge` | bool | true | A1-C2 level badge + XP bar |
| `progress.stats_grid` | bool | true | 2×2 stats cards |
| `progress.streak_section` | bool | true | Fire icon + day count |
| `progress.weekly_chart` | bool | true | Minutes-spoken bar chart |
| `progress.skill_radar` | bool | true | The whole radar chart container |
| `progress.achievements` | bool | true | Horizontal badge scroll |

### Scenarios domain
| Key | Type | Default | Controls |
|-----|------|---------|----------|
| `scenarios.search` | bool | true | Search bar at top |
| `scenarios.category_filter` | bool | true | All/Travel/Business/Social/Daily chips |
| `scenarios.difficulty_filter` | bool | true | A1-C2 filter row |

### Conversation domain
| Key | Type | Default | Controls |
|-----|------|---------|----------|
| `conversation.mode_toggle` | bool | true | Chat ↔ Face mode button |
| `conversation.face_mode_available` | bool | true | Whether Face mode is reachable at all |
| `conversation.mic_button` | bool | true | Mic UI (also gated by `speechService.isAvailable`) |
| `conversation.live_caption` | bool | true | Subtitle on Face stage |

### Settings domain
| Key | Type | Default | Controls |
|-----|------|---------|----------|
| `settings.profile_section` | bool | true | Avatar + display name |
| `settings.tutor_carousel` | bool | true | Persona switcher |
| `settings.language_selector` | bool | true | English/조선어/中文 |
| `settings.theme_selector` | bool | true | Apricot/Sage/Iris/Obsidian swatches |
| `settings.learning_section` | bool | true | Daily goal |
| `settings.network_section` | bool | true | Compression toggle (see §11.2) |
| `settings.storage_section` | bool | true | Model storage status (see §9.15.6) |
| `settings.about_section` | bool | true | Version / Terms / Privacy |

### System / non-visibility flags (forward-compatible)
| Key | Type | Default | Controls |
|-----|------|---------|----------|
| `system.maintenance_banner` | object | `{"enabled": false, "message_i18n_key": null}` | Shown app-wide when on |
| `system.min_app_version` | string | `"1.0.0"` | If user's app is older, show "please update" wall |
| `home.recommended_scenarios.max_count` | number | 4 | How many cards to show |
| `progress.weekly_chart.weeks_shown` | number | 8 | Last N weeks |

~40 flags total. Reasonable surface — admin panel can group by category for sanity.

- [ ] **12.6.1** Seed all keys from this catalog on first deploy
- [ ] **12.6.2** Migration script on every deploy compares this catalog to DB and inserts new keys (so adding a flag in code doesn't need a manual DB update)

---

## 12.7 Future Next.js Admin Panel (Out of Scope, Spec'd Here)

Separate repo / project. Connects to the same NestJS backend via the admin endpoints in §12.4.

### Minimum feature set
- Admin login (reuse `/auth/signin` + role check)
- Flag list grouped by `category`, with current value, default value, "differs from default" badge
- Toggle / edit each flag with type-aware controls (checkbox / text / number / JSON editor)
- Reset to default per flag + bulk reset
- Audit log view (who changed what, when)

### Suggested stack
- Next.js 14+ (App Router)
- shadcn/ui for the dashboard (matches the editorial design vibe of the Flutter app)
- TanStack Query for backend calls
- Auth via the same JWT pair the Flutter app uses

### Notes
- The admin panel is a **read/write client of the existing API**. No backend changes needed when the panel is built — everything required is in §12.4.
- v1 of the admin panel can be very thin: a table view + edit modal. CRUD over `/admin/config/*`.

---

## 12.8 Failure Modes & Defaults

| Failure | Behavior |
|---------|----------|
| `/app-config` returns 5xx | Use cached value if any, else baked defaults; retry on next poll |
| Network entirely unavailable | Baked defaults used (no degraded UX) |
| Cache file corrupt | Falls back to baked defaults; cache rewritten on next successful fetch |
| Flag key referenced in code but missing from config response | Falls back to `fallback` param in `LayoutVisibility` (which itself defaults to `true`) — fail-open |
| Admin sets a flag to wrong type (e.g. string into a `boolean` slot) | Backend validation rejects with 400 |
| Admin removes a critical flag (e.g. hides ALL settings sections) | Allowed — the system trusts admins. Add a "preview as user" mode to the future panel to test before saving |

**Key principle: fail open, not closed.** A broken config never breaks the app — at worst, the user sees the default layout. This avoids whole-app blackouts from a misconfigured flag.

---

## 12.9 Implementation Checklist (App Side, v1)

These are the concrete tasks the Flutter dev does NOW, before the admin panel exists:

- [ ] **12.9.1** Add `LayoutConfigProvider` (Riverpod) + `LayoutVisibility` widget per §12.5
- [ ] **12.9.2** Add `layout_config_cache` Drift table (mirrors backend schema)
- [ ] **12.9.3** Add `LayoutConfigApi` Retrofit client calling `GET /app-config`
- [ ] **12.9.4** Bake `assets/config/defaults.json` with the catalog from §12.6
- [ ] **12.9.5** Wrap every section in §12.6 with the appropriate visibility check (per screen)
- [ ] **12.9.6** Settings → Debug screen (dev builds only) shows resolved config
- [ ] **12.9.7** Tests: with config absent → defaults applied; with flag false → section hidden; with flag flipped → next refresh applies it

## 12.10 Implementation Checklist (Backend, v1)

- [ ] **12.10.1** Create `app_config` table + migration
- [ ] **12.10.2** Add `role` column to `users` table + migration; backfill existing users to `'user'`
- [ ] **12.10.3** Implement `AppConfigModule` with `AppConfigService`, `AppConfigController` (`GET /app-config`), `AdminConfigController` (`/admin/config/*`)
- [ ] **12.10.4** Use the shared `PermissionGuard` + `@RequirePermission()` from [14](14_admin_permissions.md); do NOT reintroduce a bespoke `AdminGuard`
- [ ] **12.10.5** Extend JWT payload to include `role`
- [ ] **12.10.6** Write to the unified `admin_audit_log` table on every admin mutation (table defined in [13 §13.8.2](13_admin_content_and_users.md); no separate `config_audit_log`)
- [ ] **12.10.7** Seed file with the full §12.6 catalog
- [ ] **12.10.8** Deploy-time reconciler: insert any missing catalog keys (additive only — never deletes admin overrides)
