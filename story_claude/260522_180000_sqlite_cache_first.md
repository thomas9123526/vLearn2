# SQLite cache-first loading — Home, Scenarios, Progress

## The problem

On a slow network the Home stats (Sessions / **Minutes** / Topics),
the recommended-scenarios strip, and the whole Progress screen showed
a spinner — the user stared at a loading indicator every app open
even though the numbers barely change between sessions.

## What was found

An audit of every screen (`lib/features/**`) for the
"spinner-instead-of-data" pattern. Screens fetching slow-changing
network data and showing a spinner/skeleton:

| Screen | Data |
|---|---|
| Home | progress stats, recommended scenarios |
| Scenarios | scenario list |
| Scenario brief | one scenario's detail |
| Progress | progress + snapshots + completions |
| News list / detail | news posts |
| Session report | session summary |
| Conversation history | past sessions |

Also found: the drift SQLite database (`AppDatabase`, with
`ScenariosCache` / `ProgressCache` tables) **existed but was never
instantiated** — fully dead scaffolding.

Scope this change: **Home + Scenarios + Progress** (the three
high-traffic tab screens). News / brief / report / history are left
for a follow-up — the cache layer added here extends to them trivially.

## The cache layer (new)

- **`core/cache/cache_store.dart`** — `CacheStore`, a tiny key→JSON
  store. Backed by a standalone `api_cache` SQLite table created
  lazily with `CREATE TABLE IF NOT EXISTS` via drift's
  `customStatement`, so it needs no drift schema bump / codegen and
  survives any future migration. Every op is best-effort: a cache
  failure can never break a screen. Also exposes `appDatabaseProvider`
  — the first thing to actually open `vlearn2.sqlite`.
- **`core/cache/cached.dart`** —
  - `Cached<T>`: `{ value, refreshing, error, fromCache, cachedAt }`.
  - `CachedNotifier<T>`: a keep-alive `Notifier` that loads
    **cache-first** — `build()` → show SQLite copy instantly
    (`refreshing: true`) → run the network fetch → swap in fresh data
    and write it back. On fetch failure the cached value stays on
    screen; only the spinner stops. A per-`build()` generation token
    guards against stale async writes when the user id changes.
- **`core/providers/cached_providers.dart`** — four shared providers:
  `progressSummaryProvider`, `scenariosProvider`,
  `progressSnapshotsProvider`, `progressCompletionsProvider`.
  Per-user caches are namespaced by the signed-in user id so a
  different account can't flash the previous user's numbers.
- **`shared/widgets/refreshing_dot.dart`** — `RefreshingDot`, the
  small 12–14px inline spinner shown next to a heading while a
  background refresh runs.

## Screen changes

- **Home** — `_progressProvider` / `_scenariosProvider` (plain
  `FutureProvider`s) replaced by the shared cached providers. Quick
  stats and the scenario strip show cached values at once; a
  `RefreshingDot` appears (top-right of the stats row / beside
  "Recommended scenarios") while refreshing. Cold first launch still
  shows the spinner / skeleton — nothing to show yet.
- **Scenarios** — now reads the cached **full** list and filters
  **client-side** (category, difficulty, search) — instant, no
  network per filter. The old `FutureProvider.family` + server-side
  `_Filters` query is gone. Added pull-to-refresh; the dot sits in
  the app-bar title.
- **Progress** — the 3 `FutureProvider`s replaced by the cached
  providers. Cards render as soon as a cached `/progress` copy
  exists; each card heading (`_SectionLabel`) carries its own dot.

## Model change

`I18nText` and `Scenario` gained `toJson()` (snake_case, the inverse
of `fromJson`) so the scenario list can round-trip through the cache.

## Behaviour notes

- Cold first launch: still a spinner (no cache yet) — every launch
  after that is instant.
- Scenario search is now a client-side substring match on the
  localized title/description rather than the server `q` param —
  fine for a curated scenario list, and instant.
- Providers are keep-alive, so tab switches don't re-fetch; pull to
  refresh forces it.

## Verification

```text
flutter analyze — whole project → No issues found
```

## User prompt (verbatim)

> When network is slow, the red pointed part is showing progress.
> Can you cache those values to sqlite? So when app opens show cache
> values if network is slow and busy and showing some animation or
> slight progress that it is fetching. when fetch done then show
> values for it.
> And Can you analyze the all screens and find which screens has the
> part like this?
