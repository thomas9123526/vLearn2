# I uncheck key phrase section in Scenario Detail tab on admin  panel. But it is s

Session: `ec7e9529-1399-4642-b1c1-753f53834cc7`
Saved: 2026-06-04T13:29:26.794Z

## User

I uncheck key phrase section in Scenario Detail tab on admin  panel.
But it is still shows on the application scenario deatil screen.

Also application doen't load language information from the backend api and don't change the ui language. I think the application already has the en,zh,ru,ko language set.

## Assistant

Two things to check: whether `scenario_detail.*` flags are actually read in `scenario_brief_screen.dart`, and how `layoutConfigProvider` fetches config (does it filter by `is_visible_to_app`).

## Assistant

Let me check the backend `/app-config` endpoint to see what it returns:

## Assistant

Found the real issue — `/app-config` is protected by `@UseGuards(JwtAuthGuard)`. When the app hasn't logged in yet (or the token expired), the 401 is swallowed silently and the language fetch fails. Let me verify by checking the auth interceptor:

## Assistant

Clear picture. The `/app-config` endpoint has `@UseGuards(JwtAuthGuard)` — so the language fetch in `main()` silently 401s if the user hasn't logged in yet or the token is missing. Config flags should be public. Fix: remove the guard from `AppConfigController` only.

For Issue 1, the scenario detail flags are seeded but never read in `scenario_brief_screen.dart`. I need to wire them.

## Assistant

Now let me see `_HeroCard` and the pills section:

## Assistant

Now I have the full picture for both fixes. Implementing them:

**Fix 1: Remove auth guard from public `/app-config` endpoint:**

## Assistant

**Fix 2: Wire `scenario_detail.*` flags in the brief screen:**

## Assistant

The import will be used once I add the flag reads. Adding them now to the `build()` method and passing them through:

## Assistant

Now wire them into the widget tree. Pass the flags to `_HeroCard` and gate the sections in the `ListView`:

## Assistant

Need to add the new params to `_HeroCard`'s constructor and use them:

## Assistant

Now use the flags inside `_HeroCard.build()`:

## Assistant

No more diagnostics expected. Now commit everything:

## Assistant

Done. Summary of what changed:

**Scenario Detail flags now work in the app:**
- Unchecking "Key phrases section" in the admin panel → that section disappears in the brief screen
- Same for Description, Objectives, Background image, CEFR pill, XP pill
- All flags default to `true` so nothing changes unless explicitly unchecked

**Language fix:**
- Root cause was `GET /app-config` requiring a JWT — the call in `main()` happens before login, gets a silent 401, so `app.default_language` was never read from the server
- Removed the auth guard from the public-facing `/app-config` endpoint (the admin `/admin/config` endpoint stays protected)
- Now change the language in admin panel → restart the app → it applies
