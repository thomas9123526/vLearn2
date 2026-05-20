# Report — 12_admin_visibility

**Spec:** [todoList/0516/12_admin_visibility.md](../../todoList/0516/12_admin_visibility.md)
**Date:** 2026-05-16
**Status:** ✅ Backend AppConfigModule + Flutter LayoutConfigProvider + LayoutVisibility widget

## What was done

### Backend

- **[backend/src/app-config/app-config.module.ts](../../backend/src/app-config/app-config.module.ts)** — One file containing `AppConfigService`, `AppConfigController` (`GET /app-config` returns visibility flags for the Flutter app with a `version` timestamp), and `AdminConfigController` (`GET/PATCH/POST` on `/admin/config/*` guarded by `@RequirePermission('config.view'|'config.edit')`).
- **`AppConfigService.appVisibleFlags()`** — Returns only `is_visible_to_app=true` rows; computes `version` as `MAX(updated_at)` for client-side If-Modified-Since caching.
- **`update()`** validates that the new value's type matches the row's `value_type` (boolean/string/number/array/object) — rejects mismatches with 400.
- **`reset()` and `resetAll()`** — Reset to `default_value`; reset-all is superadmin-only.
- **Seed data already in place from §02** — 44 default flags covering the §12.6 catalog.

### Flutter

- **[flutter_app/lib/core/config/layout_config_provider.dart](../../flutter_app/lib/core/config/layout_config_provider.dart)** — `LayoutConfigNotifier` (Riverpod `AsyncNotifier`) starts with baked-in defaults (so the UI never blanks even with no network), then fires a best-effort background fetch from `GET /app-config`. Dio failures keep the defaults. Never throws.
- **`LayoutConfig.isVisible(key, {fallback})` + `get<T>(key)`** — O(1) flag reads.
- **[flutter_app/lib/shared/widgets/layout_visibility.dart](../../flutter_app/lib/shared/widgets/layout_visibility.dart)** — `LayoutVisibility(configKey: '...', fallback: true, child: ...)` widget that wraps any section. Screens can adopt it incrementally as the admin panel comes online.

## Honest call-outs

1. **Screens don't wrap their sections in `LayoutVisibility` yet.** The widget is in place; the catalog is seeded; the API returns flags; the provider caches them. The remaining step is for each screen to wrap its sections: e.g. `LayoutVisibility(configKey: 'home.streak_banner', child: _StreakAndXp(...))`. Mechanical refactor, low risk. Done as needed when the admin panel ships.

2. **No SQLite caching of the config** — only in-memory (Riverpod). On app restart the baked defaults show first, then the server fetch updates. Acceptable for a feature-flag system that changes rarely. Adding Drift caching is a small follow-up.

3. **No active-config-version sync** — when the admin updates a flag, in-flight app sessions still see the old value until next launch (or a manual provider invalidation). A push or websocket invalidation would be a v2 enhancement.
