# When network is slow, the red pointed part is showing progress. Can  you cache t

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-22T11:25:59.627Z

## User

When network is slow, the red pointed part is showing progress.
Can  you cache those values to sqlite? So when app opens show cache values if network is slow and busy and showing some animation or slight progress that it is fetching. when fetch done then show values for it.
And Can you analyze the all screens and find which screens has the part like this?

## Assistant

This is a meaty task — cache-first loading with background refresh, plus an audit of every screen. Let me explore the codebase first before proposing anything.

## Assistant

The app already uses **drift** (SQLite ORM) and has cache tables — `scenarios_cache`, `progress_cache`. Let me examine the home screen and the existing cache infrastructure.

## Assistant

The drift database and cache tables exist but **aren't wired up anywhere** — they were scaffolded and never used. Let me check the layout config provider (it may already have a cache pattern) and launch a broad screen audit in parallel.

## Assistant

I've now got the full picture. Here's what I found.

## Analysis — screens with the "spinner instead of data" pattern

The drift SQLite database **already exists** (`AppDatabase` with `ScenariosCache` + `ProgressCache` tables) but is **completely unused** — it was scaffolded and never wired up. So the cache tables for exactly your data are already defined.

Screens that fetch slow-changing network data and show a spinner/skeleton (candidates for cache-first):

| Screen | Data | Current loading UI |
|---|---|---|
| **Home** | progress stats (Sessions/Minutes/Topics) | `CircularProgressIndicator` |
| **Home** | recommended scenarios | skeleton boxes |
| **Scenarios** | scenario list | spinner |
| **Scenario brief** | one scenario's detail | spinner |
| **Progress** | progress + snapshots + completions (3 calls) | spinners |
| **News list / detail** | news posts | spinner |
| **Session report** | session summary | spinner |
| **Conversation history** | past sessions list | spinner |

Auth, onboarding, splash, settings, conversation, setup — either no network fetch, user-triggered, or transient data; no caching needed.

The fix pattern is **stale-while-revalidate**: read SQLite → show it instantly → fetch in background → swap in fresh values, with a subtle "refreshing" hint. (`layout_config_provider` already does a no-cache version of this with baked-in defaults — good precedent.)

Before I build it, two decisions:

## Assistant

The user wants Home + Scenarios + Progress cache-first, with a small inline spinner. Let me read the remaining screens and the API/model layer before settling the design.

## Assistant

This is a multi-file feature. Here's my design: a generic SQLite-backed `CacheStore` + a `CachedNotifier<T>` base that loads cache-first, used by 4 shared providers. Let me build it.

## Assistant

Fixing the redundant `refreshing: false` (it's the default) and adding `toJson` to the models:

## Assistant

Now the Home screen — swapping in the cached providers:

## Assistant

Stale diagnostics aside, two edits remain: rework `_QuickStats` and add the `_scenarioStrip` method. Let me read the current state:

## Assistant

Now the Scenarios screen — switching to the cached full list with client-side filtering:

## Assistant

Now the Progress screen — the largest change (3 cached providers + section dots):

## Assistant

All those diagnostics are stale — they fired between the batched edits. Let me run a real analyze across everything:

## Assistant

All clean — full project analyze passes. Let me write the story log and commit:

## Assistant

Done — committed as `60b2cc4`'s successor. Here's the summary.

## What I built

**SQLite cache-first loading** for Home, Scenarios, and Progress. On app open each screen now shows its **last-known values instantly** from SQLite, refreshes from the network in the background, and shows a **small inline spinner** next to the relevant heading while it does. When the fetch lands, fresh values swap in.

New cache layer:
- [cache_store.dart](flutter_app/lib/core/cache/cache_store.dart) — `CacheStore`, a key→JSON store on an `api_cache` SQLite table. Also `appDatabaseProvider` — the first thing to actually open the drift database, which **existed but was never wired up**.
- [cached.dart](flutter_app/lib/core/cache/cached.dart) — `Cached<T>` state + `CachedNotifier<T>`, the cache-first loader.
- [cached_providers.dart](flutter_app/lib/core/providers/cached_providers.dart) — 4 shared providers (progress summary, scenarios, snapshots, completions).
- [refreshing_dot.dart](flutter_app/lib/shared/widgets/refreshing_dot.dart) — the inline spinner.

The Scenarios screen now filters the **cached full list client-side** — category/difficulty/search are instant, no network per keystroke.

## Screen analysis — answer to "which screens have this pattern"

I audited every screen. Those that fetch slow-changing network data and showed a spinner/skeleton:

| Screen | Status now |
|---|---|
| **Home** — stats + scenarios | ✅ cached |
| **Scenarios** — list | ✅ cached |
| **Progress** — progress + snapshots + completions | ✅ cached |
| Scenario brief — one scenario's detail | ⚠️ still spinner |
| News list / News detail | ⚠️ still spinner |
| Session report — session summary | ⚠️ still spinner |
| Conversation history — past sessions | ⚠️ still spinner |

Auth, onboarding, splash, settings, conversation, setup — no caching needed (no network fetch, user-triggered, or transient data).

The 4 remaining `⚠️` screens were **out of the scope you picked** (Home + Scenarios + Progress). The cache layer I built is generic — extending it to those is just one more `CachedNotifier` subclass each, no new infrastructure. Say the word and I'll do them.

## Notes

- **Cold first launch** still shows a spinner (nothing cached yet) — every launch after that is instant.
- Scenario search is now a client-side substring match instead of the server `q` param — fine for a curated list, and instant.
- `flutter analyze` clean across the whole project. I haven't run it on a device — worth a quick test, since this is the first time the SQLite database is actually opened.
