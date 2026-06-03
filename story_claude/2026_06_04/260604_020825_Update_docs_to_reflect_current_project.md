# Conversation - Update docs to reflect current project

| Field | Value |
|---|---|
| Saved | 2026-06-04 02:08:25 |
| Commit | Update docs to reflect current Flutter app architecture |
| Project | C:\project\vLearn2 |

---

## User

I made document inside docs. But the project has improved.
Can you make all document in docs reflect current the project function?

## Assistant

Read all 17 docs files and compared against the current codebase. Most docs (backend, admin panel, application protocol/auth/network) were accurate and unchanged. Two files needed updating:

**`docs/0525/app_source_description_part1.md`** — Major updates:
- `main.dart` section: expanded from 5 steps to 9 (added `_checkRequiredApp`, `layoutConfigProvider.refresh`, SharedPreferences default language, `CacheSeeder.seedIfEmpty`, `licenseStateProvider` watcher in `VLearn2App`)
- `core/config/`: added `rive_render_config.dart` (RiveRenderConfig, platform-based GPU/Flutter renderer selection)
- Added `core/cache/` section (CacheStore, CacheSeeder, Cached)
- Added `core/db/` section (Drift SQLite schema, AppDatabase, tables/)
- Added `core/guard/` section (ContentGuard)
- Added `core/license/` section — fully implemented: machine_id_service, license_state, license_state_provider, license_file_scanner
- `core/providers/`: added backend_flags_provider, personas_provider, cached_providers
- Features table: added splash/, onboarding/, license/, report/, setup/; removed SplashScreen from auth/; updated conversation/ to note emo_linear.riv; updated settings/ to note License gating
- Platform split table: updated Animation row to reflect RiveRenderConfig Platform.isWindows fork; updated Machine ID from "upcoming" to "implemented"

**`docs/0525/17_license_plan.md`** — Added "Implementation status" table at top showing which components are done vs still planned.

---

## Prompt

I made document inside docs. But the project has improved.
Can you make all document in docs reflect current the project function?
