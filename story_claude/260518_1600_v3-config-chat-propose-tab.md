# todoList/0518_v3 — Android config path, conversation flow doc, tab visibility

## What this task did

Three tasks from `todoList/0518_v3/`.

### 1 — Android config file path fixed (`01_config.txt`)

**Problem**: User couldn't see `룡마/가상외국어회화` folder on device. `ConfigFileService` computed the correct public path but `file.parent.createSync(recursive: true)` threw `FileSystemException: Permission denied` on Android 11+ (no `MANAGE_EXTERNAL_STORAGE` permission). The exception was swallowed in `main()`'s `catch (_)` so the app used defaults silently and never created the folder.

**Fixes**:
1. **`AndroidManifest.xml`** — added `READ/WRITE_EXTERNAL_STORAGE` (maxSdkVersion-capped for legacy Android) + `MANAGE_EXTERNAL_STORAGE` + `android:requestLegacyExternalStorage="true"`.
2. **`main.dart`** — calls `_requestAndroidStorage()` before loading config; `permission_handler` opens the **All files access** Settings screen if the permission is denied.
3. **`app_config.dart`** — wrapped `createSync` in a try/catch: if public storage creation fails, falls back to app-scoped external dir so the app still starts. On the next launch (after permission granted) the public `룡마/가상외국어회화/config/` path is used.

### 2 — Conversation flow document (`02_chat_propose.txt`)

Read-only documentation task. Traced the full conversation pipeline from Flutter to AI and back:
- Entry: session + persona fetched, no AI call on screen open
- Send message: `POST /conversations/sessions/:id/messages` → ConversationsService builds context (persona, scenario, user level/language, full history) → PromptBuilderService constructs system prompt → AI provider called (max 300 tokens, temperature 0.8, prompt caching enabled) → assistant message saved and returned
- Idle suggestion (20s silence in tutor mode): same context + "say one sentence the user can say next" instruction, max 60 tokens
- End session: XP calculated deterministically (word count formula), evaluation pipeline scaffolded but not yet connected to AI
- All tips/suggestions come from the AI (or canned fallbacks when AI is offline); no algorithmic tip generation

Report written to `todoList_report/0518_v3/02_chat_propose.md` for conversation format planning.

### 3 — Tab visibility from admin panel (`03_tab.txt`)

Admin can now show/hide the four main navigation tabs (Home, Scenarios, Progress, Settings) from Config flags → **Navigation** tab.

- **`flag-catalog.ts`** — added `'navigation'` as a new `AppTab` + 4 `tabs.*` flags (tier: big)
- **`app-config.seed.ts`** — 4 new seed rows, all `is_visible_to_app: true` so they reach the Flutter app
- **`layout_config_provider.dart`** — 4 entries added to `_bakedDefaults` (all `true`)
- **`app_shell.dart`** — converted to `ConsumerWidget`, watches `layoutConfigProvider`, filters `_allTabs` by each tab's `flagKey`. Safety: never shows zero tabs (falls back to all if every flag is off).

## Files

| Path | Change |
|------|--------|
| [flutter_app/android/app/src/main/AndroidManifest.xml](../flutter_app/android/app/src/main/AndroidManifest.xml) | Storage permissions + requestLegacyExternalStorage |
| [flutter_app/lib/main.dart](../flutter_app/lib/main.dart) | Request manageExternalStorage before loading config |
| [flutter_app/lib/core/config/app_config.dart](../flutter_app/lib/core/config/app_config.dart) | Fallback to app-scoped external on createSync failure |
| [admin_panel/src/lib/flag-catalog.ts](../admin_panel/src/lib/flag-catalog.ts) | `'navigation'` AppTab + 4 tabs.* flags |
| [backend/src/database/seeds/seeds/app-config.seed.ts](../backend/src/database/seeds/seeds/app-config.seed.ts) | 4 tabs.* seed rows |
| [flutter_app/lib/core/config/layout_config_provider.dart](../flutter_app/lib/core/config/layout_config_provider.dart) | 4 tabs.* baked defaults |
| [flutter_app/lib/shared/widgets/app_shell.dart](../flutter_app/lib/shared/widgets/app_shell.dart) | ConsumerWidget, flag-filtered visible tabs |
| [todoList_report/0518_v3/01_config.md](../todoList_report/0518_v3/01_config.md) | Task report |
| [todoList_report/0518_v3/02_chat_propose.md](../todoList_report/0518_v3/02_chat_propose.md) | Conversation flow documentation |
| [todoList_report/0518_v3/03_tab.md](../todoList_report/0518_v3/03_tab.md) | Task report |

## Heads-up for deploy

- Run `npm run db:seed` on the backend to insert the 4 `tabs.*` config rows.
- On first Android app launch after update the user will be prompted with the "All files access" Settings screen; after granting, `룡마/가상외국어회화/config/app_config.json` is created automatically.

## User prompt (verbatim)

> For every files inside todoList\0518_v3 folder, read it and do what they said. After you have done task, produce report what you have done and save as md format to 'todoList_report\0518_v3' folder. md filename can be xxx.md where xxx means the current todo file name. You are an expert fullstack developer. Don't ask me anything. Go automatically without my choice or answer. You do it by yourself and by your decision. You have many times. take it easy. Quality is important.
