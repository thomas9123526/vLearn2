# Auto-route returning users from splash to /signin

## What this task did

Wired the splash screen to read `AuthHistory.hasEverSignedIn()` on mount and, when the device has signed in before, schedule a 2-second `Timer` that pushes `/signin`. The 2-second window matches the 1.5 s entrance choreography plus a half-second beat so the wordmark actually registers before the route flips. First-time users see the same screen, only this time the "Tap to begin" CTA stays put and still pushes `/signup`. Converted `SplashScreen` from `StatefulWidget`/`State` to `ConsumerStatefulWidget`/`ConsumerState` so the splash can `ref.read(authHistoryProvider)` directly. Hid the `_TapToBeginButton` while `_returning == null` (the SharedPreferences read is still in flight) and when `_returning == true`, so a returning device never flashes the button before the auto-redirect fires.

## Conversation summary

- User asked for logic so that a previously signed-in user goes directly to `/signin` after the splash plays — no tap required.
- I inspected `splash_screen.dart`, `app_router.dart`, `auth_history.dart`, and `auth_provider.dart` to confirm the flag (`auth.has_ever_signed_in`) is written by `_persistAndFetch` and survives `signOut()`.
- Decided to do the gating inside the splash widget itself rather than in `app_router.redirect`, because the redirect callback is synchronous and can't await SharedPreferences. The splash is the only place we ever want this auto-bounce, so keeping it local also avoids polluting the global redirect logic.
- Hid the CTA while `_returning == null` to prevent the button from appearing for a microsecond and then vanishing on a returning device.
- IDE flagged `_returning` as unused after the first edit; resolved by using it in the conditional CTA render.
- `flutter analyze lib/features/splash/splash_screen.dart` returned "No issues found!".

## Decisions / call-outs

- **2-second delay (`_autoNavDelay`)** — purely a UX choice. The entrance controller finishes at 1.5 s; an extra 500 ms gives the user a moment to register the wordmark. Easy to tweak if it feels wrong on real hardware.
- **Local gating, not router redirect** — `redirect` is sync, SharedPreferences is async; doing it in the widget keeps the router synchronous.
- **CTA hidden during the `null` window** — the SharedPreferences read returns in milliseconds, so first-time users see effectively no delay; returning users never see the CTA flash.
- **Auto-nav uses `context.go`, not `context.push`** — consistent with the existing `_TapToBeginButton` and means the splash is removed from the back stack (no way to "back" into it after sign-in).
- **No change to `app_router.dart`** — its existing splash logic (`signedIn && loc == splash → home/onboarding`) still wins for fully signed-in users; this code path only matters for signed-out returning users.

## User prompt (verbatim)

> I want logic that If the user already signin before, the user can go signin screen directly after splash showed.
