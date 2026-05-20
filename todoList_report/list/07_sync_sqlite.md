# 07 — How does the app sync its SQLite cache with the backend?

## Task

> how the app implements database sync between application and backend
> server side.

## Verdict — **A local SQLite (Drift) schema is defined but completely unwired. There is no app↔backend DB sync in the current code.**

## What's actually in the repo

### 1. Drift schema lives at `flutter_app/lib/core/db/`

```
database.dart                       # AppDatabase definition
database.g.dart                     # generated code
tables/
  layout_config_table.dart          # cached admin layout flags + meta row
  local_sessions_table.dart         # LocalSessions + LocalMessages
  progress_cache_table.dart         # daily / streak / XP cache
  scenarios_cache_table.dart        # read-through scenario list cache
  settings_table.dart               # per-user app settings
  users_table.dart                  # local user mirror
```

```dart
@DriftDatabase(tables: [
  LocalUsers, ScenariosCache, LocalSessions, LocalMessages,
  ProgressCache, AppSettings, LayoutConfigCache, LayoutConfigMeta,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  @override int get schemaVersion => 1;
  ...
}
```

The schema is comprehensive — it has tables for users, scenarios,
sessions + messages, progress, settings, and the layout-flag config.
Each table has at least one timestamp column (`cachedAt`,
`fetchedAt`, etc.) intended for a "is this stale" check, suggesting
a read-through cache design was intended.

### 2. Nothing imports `AppDatabase`

Grepped `flutter_app/lib/` for `AppDatabase` / `appDatabaseProvider`
/ `database.dart` — only matches are inside `lib/core/db/` itself
(the class declaration and the generated file). **No provider, no
repository, no screen, no migration, no test reads or writes any
row.** The class is dead code.

### 3. There is no Riverpod provider for the DB

If a provider were defined (e.g.,
`final appDatabaseProvider = Provider<AppDatabase>(...)`), we'd expect
a hit in `flutter_app/lib/core/`. Confirmed there is none.

### 4. All data flow is currently online-only

Every screen / repository in `lib/features/` reads through
**Riverpod `FutureProvider`s** which call the backend via Dio:

| Provider | Source of data |
|---|---|
| `_scenariosProvider` (home), `scenariosListProvider` | `GET /scenarios` per request, no cache |
| `_progressProvider` (home), `progressApi.myProgress()` | `GET /progress/me` per request |
| `_historyProvider` (conversation history) | `GET /conversations/sessions` per request |
| `personasListProvider` | `GET /personas` per request |
| `layoutConfigProvider` | Baked defaults in code + best-effort `GET /app-config`; ephemeral, not persisted |
| `backendFlagsProvider` | Same `GET /app-config`, separate caller |

Riverpod caches these futures for the lifetime of the
`ProviderContainer` (one app session). On the next cold start the
caches are gone and every screen re-fetches.

### 5. No background sync / offline machinery

- No `connectivity_plus`, `workmanager`, `background_fetch`, or
  similar in `pubspec.yaml`.
- No `Connectivity` listener wired anywhere.
- The Dio chain has Auth, Compression, Logging, and Error
  interceptors — no caching interceptor (no `dio_cache_interceptor`).
- `flutter_secure_storage` is used **only** for tokens + the
  "Save my account" credentials. `SharedPreferences` is used for
  small flags (`auth.has_ever_signed_in`, the layout config defaults
  during build).
- The model registry (`flutter_app/lib/core/storage/model_registry.dart`)
  is durable storage **only** for sherpa-onnx speech models — not
  user-facing content.

## Summary diagram

```
                    +------------------+
                    |  Backend         |
                    |  Postgres + DTOs |
                    +---------+--------+
                              |
              HTTPS Dio       v
                    +------------------+
                    |  Flutter app     |
                    |  ─────────────── |
                    |  FutureProvider  |  ← in-memory only, per session
                    |  caches          |
                    +------------------+
                              ^
                              |
                              |    (not wired)
                              |
                    +------------------+
                    |  Drift sqlite    |
                    |  vlearn2.sqlite  |  ← exists on disk only if
                    |  (would persist  |    someone constructs AppDatabase,
                    |   between cold-  |    which no code does today.
                    |   starts)        |
                    +------------------+
```

## What "implementing sync" would look like (out of scope, just for reference)

If the team wants the cache the Drift schema clearly anticipates,
the next four steps would be:

1. **Expose `AppDatabase` via a Riverpod provider** —
   `final appDatabaseProvider = Provider<AppDatabase>((_) =>
   AppDatabase());`. Wire its `close()` to `ref.onDispose`.
2. **Repository layer per resource** —
   e.g. `ScenariosRepository(this.db, this.api)` with:
   - `Stream<List<Scenario>> watch()` reading from
     `ScenariosCache`,
   - `Future<void> refresh()` calling `api.list()` and upserting
     rows with `cachedAt = now`.
   - Replace the FutureProvider with a `StreamProvider` over
     `watch()`.
3. **Background refresh** — on app foreground +
   `connectivity_plus` "online" event, kick `refresh()` for the
   resources that matter (home: scenarios, progress; settings:
   layout config).
4. **Conflict / staleness policy** — for write paths
   (sessions, messages), either: (a) accept "last write from server
   wins" with offline writes queued + replayed on reconnect, or
   (b) avoid offline writes entirely and only cache reads. (b) is
   much simpler and matches the data already in the schema (which
   is read-cache shaped, not offline-write shaped).

The Drift tables and the timestamp columns suggest the original
plan was option (b). Wiring it up is a meaningful but contained
project (maybe a week of dedicated work).

## Files inspected (no changes; audit task)

- `flutter_app/lib/core/db/database.dart`
- `flutter_app/lib/core/db/tables/*.dart` (all six)
- `flutter_app/lib/core/api/api_client.dart`
- `flutter_app/lib/core/config/layout_config_provider.dart`
- `flutter_app/lib/core/providers/backend_flags_provider.dart`
- `flutter_app/lib/features/home/home_screen.dart`
- `flutter_app/lib/features/conversation/conversation_history_screen.dart`
- `flutter_app/pubspec.yaml`

## TL;DR

The app currently has **no sync** between local SQLite and the
backend. The Drift schema exists at `flutter_app/lib/core/db/` but
is dead code — no provider, no repository, no read or write call
site references `AppDatabase`. All data flow today is online-only
via Dio + Riverpod's in-memory `FutureProvider` cache, which lasts
for one session. Cold-starting the app re-fetches everything.
