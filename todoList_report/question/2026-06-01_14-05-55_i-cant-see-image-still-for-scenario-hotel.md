# I can't see image still for scenario 'hotel reservation'

Session: `d506161a-a027-47af-a3ba-75104b012999`
Saved: 2026-06-01T05:05:55.101Z

## User

I can't see image still for scenario 'hotel reservation'

## Assistant

Let me check a few things simultaneously — what the backend actually returns for scenarios, whether there's a SQLite cache that might be serving stale data, and how the URL is constructed in Flutter.

## Assistant

The backend does include `background_image_url`. Most likely cause: **stale SQLite cache** — the scenario was cached before we added `backgroundImageUrl` to the model, so the stored JSON blob doesn't have that key. Let me check the cache TTL and force-refresh mechanism.

## Assistant

The cache always re-fetches live so stale cache isn't the blocker. Let me check the actual URL configuration and whether the scenario actually has the background image URL in the API response.

## Assistant

Let me check how the scenario detail screen loads its data and whether it fetches individually or from the list cache.

## Assistant

The detail screen fetches individually via `scenariosApiProvider.get()` — no SQLite cache involved. Let me check what endpoint that calls and what it returns.

## Assistant

Let me check how the API client uses the base URL — whether it adds `/api` itself.

## Assistant

Found a bug — `_resolveScenarioImage` uses `AppConfig.defaults` (hardcoded) instead of the actual loaded config. If the device's `app_config.json` points to a different host, image URLs still resolve against the hardcoded VPS address. Let me see how `_HeroCard` is built in the parent.

## Assistant

The bug is clear: `_resolveScenarioImage` uses `AppConfig.defaults` (the hardcoded VPS address) instead of the actual loaded config. If the device's `app_config.json` points to a local backend, image URLs still point to the VPS — which doesn't have the uploaded file.

Fix: pass the actual `uploadsOrigin` from the parent `ConsumerWidget` down to `_HeroCard`.

## Assistant

Now fix `_resolveScenarioImage` to use the passed-in `uploadsOrigin` instead of the hardcoded defaults.

## Assistant

Now update `ScenarioBriefScreen` to compute `uploadsOrigin` from the actual config and pass it to `_HeroCard`. I need to add a helper and update the call site at line 108.

## Assistant

Now add the `_resolveUploadsOrigin` method to `ScenarioBriefScreen`. Let me find a good insertion point — after the `build` method.

## Assistant

Clean. Now commit with the story.

## Assistant

Committed. The root cause was that `_resolveScenarioImage` always called `AppConfig.defaults.backendBaseUrl` — the hardcoded VPS address — regardless of what the device's `app_config.json` actually contained. So if your Flutter app is configured to hit a local backend, API calls went to the right place but image URLs still pointed at the VPS (which has no uploaded files).

**What changed** in [scenario_brief_screen.dart](flutter_app/lib/features/scenarios/scenario_brief_screen.dart):
- `_HeroCard` now takes an `uploadsOrigin` parameter instead of computing it internally
- `ScenarioBriefScreen` computes `uploadsOrigin` via the new `_resolveUploadsOrigin()` method, which reads the actual `appConfigProvider` (respecting `app_config.json` and `--dart-define=API_BASE_URL`)
- `_resolveScenarioImage` is now a one-liner using the passed-in origin

After a hot restart, the image URL will be built against whatever server your device is actually configured to talk to.
