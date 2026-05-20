# 03_tab — Admin-controlled bottom navigation tab visibility

## Ask

> There are 4 tabs on android screen. Those are home, scenarios, progress, settings. So I want settings on admin panel to show or hide those tabs. So If i uncheck "progress" tab, then the app shows only 3 tabs with good design.

## What changed

### Admin panel — flag catalog (`admin_panel/src/lib/flag-catalog.ts`)

Added a new `'navigation'` app-tab to the catalog:

```ts
export type AppTab = 'home' | 'scenarios' | 'conversation' | 'progress'
                   | 'settings' | 'report' | 'navigation' | 'system';
```

```ts
{ id: 'navigation', label: 'Navigation',
  hint: 'Show or hide the bottom navigation tabs.' },
```

Four new `big`-tier flags mapped to it:

| Key | Label |
|-----|-------|
| `tabs.home` | Home tab |
| `tabs.scenarios` | Scenarios tab |
| `tabs.progress` | Progress tab |
| `tabs.settings` | Settings tab |

These appear in the admin panel Config page under the **Navigation** tab as four prominent toggles.

### Backend seed (`backend/src/database/seeds/seeds/app-config.seed.ts`)

Four new rows added to `CATALOG`. All default to `true` and all have `is_visible_to_app: true` so they're included in the `GET /app-config` response the Flutter app reads:

```ts
{ key: 'tabs.home',      value: true, is_visible_to_app: true, ... },
{ key: 'tabs.scenarios', value: true, is_visible_to_app: true, ... },
{ key: 'tabs.progress',  value: true, is_visible_to_app: true, ... },
{ key: 'tabs.settings',  value: true, is_visible_to_app: true, ... },
```

Run `npm run db:seed` (or `npm run db:migrate`) on the backend to insert these rows.

### Flutter baked defaults (`flutter_app/lib/core/config/layout_config_provider.dart`)

Added the four tab flags to `_bakedDefaults` so the app shows all tabs even when the backend is unreachable:

```dart
'tabs.home': true,
'tabs.scenarios': true,
'tabs.progress': true,
'tabs.settings': true,
```

### Flutter AppShell (`flutter_app/lib/shared/widgets/app_shell.dart`)

Converted from `StatelessWidget` to `ConsumerWidget`. Now watches `layoutConfigProvider` and filters the visible tab list on every flag change:

```dart
final visibleTabs = cfgAsync.maybeWhen(
  data: (cfg) {
    final filtered = _allTabs.where((t) => cfg.isVisible(t.flagKey)).toList();
    return filtered.isEmpty ? List.unmodifiable(_allTabs) : filtered;
  },
  orElse: () => List.unmodifiable(_allTabs), // all tabs while loading
);
```

Each `_TabSpec` now carries a `flagKey` field matching its config key. The active-index calculation iterates over `visibleTabs` rather than the full list, so `NavigationBar.selectedIndex` is always valid.

Safety guarantee: if all four flags are turned off the app falls back to showing all four tabs — the user is never left with an empty nav bar.

## How to hide a tab

1. Open admin panel → **Config flags** → **Navigation** tab.
2. Uncheck e.g. **Progress tab** and click **Save**.
3. The app reads the updated flags from `GET /app-config` on its next load (or on background refresh). The Progress tab disappears and `NavigationBar` redraws with 3 items at equal width.

If the user happens to be on the hidden route when the flag changes mid-session, the body keeps showing that screen — the route is not forcibly replaced. They'll naturally navigate away on their next tap.

## Files changed

| File | Change |
|------|--------|
| [admin_panel/src/lib/flag-catalog.ts](../../admin_panel/src/lib/flag-catalog.ts) | Added `'navigation'` AppTab + 4 tab visibility flags |
| [backend/src/database/seeds/seeds/app-config.seed.ts](../../backend/src/database/seeds/seeds/app-config.seed.ts) | 4 `tabs.*` seed entries with `is_visible_to_app: true` |
| [flutter_app/lib/core/config/layout_config_provider.dart](../../flutter_app/lib/core/config/layout_config_provider.dart) | 4 `tabs.*` baked defaults |
| [flutter_app/lib/shared/widgets/app_shell.dart](../../flutter_app/lib/shared/widgets/app_shell.dart) | ConsumerWidget, `flagKey` on `_TabSpec`, filtered visible tabs |
