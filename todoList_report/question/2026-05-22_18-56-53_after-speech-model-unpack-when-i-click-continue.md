# After speech model unpack, when i click continue, it forget the scenario that i 

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-22T09:56:53.596Z

## User

After speech model unpack, when i click continue, it forget the scenario that i selected before and go back to homescreen, how about it?

## Assistant

The flow: tap scenario → `/conversation/:sessionId` → router redirect sees speech not ready → bounces to `/setup/models`, **discarding** the conversation route. Then `_ReadyBody`'s Continue hardcodes `context.go('/home')` — so the original destination is lost.

Fix: carry the conversation route through the redirect as a query param, and send the user back there after setup.

## Assistant

Now adding the `redirectTo` parameter to `ModelsNotInstalledScreen` and wiring it into Continue / text-only:

## Assistant

The `_destination` warning is stale (it fired before the third edit landed). Let me verify with analyze:

## Assistant

Done. Committed as `c61ab06`.

**What was happening:** the router's model-gate redirect returned a bare `/setup/models`, dropping the `/conversation/:sessionId` route. Continue then hardcoded `context.go('/home')` — scenario lost.

**The fix — carry the destination through:**

1. **Redirect** ([app_router.dart:90-96](flutter_app/lib/core/router/app_router.dart#L90-L96)) — now appends the intended route as a query param: `/setup/models?redirect=<encoded conversation route>`.

2. **Route builder** ([app_router.dart:126-131](flutter_app/lib/core/router/app_router.dart#L126-L131)) — reads `redirect` and passes it to the screen.

3. **Setup screen** ([models_not_installed_screen.dart](flutter_app/lib/features/setup/models_not_installed_screen.dart)) — new `redirectTo` param + `_destination` getter (`redirectTo ?? '/home'`). **Continue** now does `context.go(_destination)` — straight back into the conversation the user picked.

I also applied it to **Text-only mode** — same "forgot the scenario" issue. After `acknowledgeTextOnly()`, the gate lets the conversation route through, so the user enters that exact conversation directly in text-only mode instead of `/home`.

No redirect loop (when the location is `/setup/models` itself, `isSetup` is true → gate returns null), and returning to `/conversation/:sessionId` is exact since the sessionId carries the chosen scenario. If the screen is opened any other way (no `redirect` param), it still falls back to `/home`. `flutter analyze` clean.
