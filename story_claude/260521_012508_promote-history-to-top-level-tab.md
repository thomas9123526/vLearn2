# Promote conversation history to a top-level tab

## What this task did

Removed the "Conversation history" entry from the Settings screen and
promoted it to a top-level shell tab — left-sidebar item on Windows
("Conversation history") and bottom-nav tab on Android ("History"). Both
labels come from the same `_TabSpec` via a new `desktopLabel` field so
the platform-specific naming the user asked for is expressed as data,
not branches.

Concretely:

- `_TabSpec` gains an optional `desktopLabel` plus a `labelFor({required isDesktop})` helper; `_SidebarItem` reads via `labelFor(isDesktop: true)`, the mobile `NavigationDestination` keeps reading `label`.
- `_allTabs` order is Home, Scenarios, History, Progress, Settings — History sits between Scenarios and Progress so the practice → review → growth flow reads left-to-right on desktop and right-to-left on mobile (matches the existing nav order).
- The `conversation/history` route was moved from a top-level fullscreen route to inside the `ShellRoute`, so it now renders inside the sidebar/bottom-nav chrome.
- `ConversationHistoryScreen`'s AppBar drops the leading back arrow (`automaticallyImplyLeading: false`) — there's nowhere to pop back to when it's a tab.
- The Settings ListTile + its `LayoutVisibility('conversation.history')` wrapper are gone, along with two now-orphaned imports (`app_router`, `layout_visibility`).
- New layout flag `tabs.history` (default `true`) lives in:
  - `flutter_app/lib/core/config/layout_config_provider.dart` baked defaults
  - `backend/src/database/seeds/seeds/app-config.seed.ts`
  - `admin_panel/src/lib/flag-catalog.ts`
- The old `conversation.history` flag was the only consumer of the now-removed Settings entry, so it's deleted from all three of those files. (Existing DB rows from prior seeds are harmless — nothing reads them.)
- The other `tabs.*` seed descriptions were touched up to say "bottom nav bar / sidebar" since the desktop sidebar honours the same flag.

`flutter analyze` clean on all five touched Flutter files.

## Conversation summary

- User asked: remove Conversation history from Settings; left-sidebar
  on Windows; bottom tab on Android. Different labels per platform.
- Grepped for `conversation.history`/`conversationHistory`/`history` to
  find all the touch-points: AppShell tabs, router, screen, settings
  entry, layout config defaults, backend seed, admin flag catalog.
- Implemented in this order: AppShell tab spec + sidebar label →
  router move into ShellRoute (with a transient unused-import warning
  in between, since the import was needed but the route had been
  removed by step one of the edit) → screen AppBar back-button drop →
  Settings ListTile removal → import cleanup → flag rename
  (`conversation.history` → `tabs.history`) across Flutter, backend
  seed, admin flag catalog.

## Decisions / call-outs

- **One spec, two labels** — added `desktopLabel` to `_TabSpec` instead
  of duplicating the spec or hard-coding per platform. Other tabs that
  don't set it just fall back to `label`, so the change is a no-op for
  them.
- **Used `tabs.history`, deprecated `conversation.history`** — the new
  flag follows the `tabs.*` naming convention used by all other shell
  tabs, so the admin UI groups it consistently. The old
  `conversation.history` flag had only one consumer (the deleted
  Settings entry) and would have been dead weight.
- **No backend migration to drop the old flag row** — `app_configs` is
  seeded but rows aren't deleted by code. Existing rows are harmless
  (nothing reads them); the admin can purge from the UI if desired.
- **Back arrow removed from the screen, not made conditional** — the
  screen is now exclusively reached via the tab. If a future flow
  pushes it on top of something else, we'd add the arrow back at that
  call-site rather than re-introducing branching here.
- **Order in `_allTabs`** — placed History between Scenarios and
  Progress so the natural flow (practice → review → growth) reads in
  order.

## User prompt (verbatim)

> I want "conversation history" in the settings to be relocated.
> I want "conversation history" on the left side of the windows
> I want "history" on the bottom tab of the android.
