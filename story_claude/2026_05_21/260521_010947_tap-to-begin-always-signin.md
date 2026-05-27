# Tap-to-begin always routes to /signin

## What this task did

Simplified the splash's `_TapToBeginButton._begin()` so a tap always navigates to `/signin` instead of forking between `/signin` and `/signup` based on `AuthHistory.hasEverSignedIn()`. The button no longer awaits SharedPreferences before navigating, so `_begin()` is now synchronous. First-time users still have a path to register — the sign-in screen's "Don't have an account? Sign up" link (line 219 of `sign_in_screen.dart`) handles that. Updated the button's doc comment to describe the new behavior.

## Conversation summary

- User asked: tap-to-begin should always go to /signin.
- Verified `/signin` carries a `context.push(AppRoute.signUp)` link, so first-time users still have a one-tap path to register.
- Removed the `hasEverSignedIn()` lookup from `_begin()` and dropped the `async`/`await` since the call is now a single `context.go(AppRoute.signIn)`.
- The earlier auto-redirect for returning users (added two tasks ago, separate code path in `_resolveReturning`) is untouched — returning devices still skip the button entirely.
- `flutter analyze` clean.

## Decisions / call-outs

- **Left `_TapToBeginButton` as `ConsumerStatefulWidget`** even though it no longer reads any provider. Converting it back to `StatefulWidget` would be diff churn for no benefit — Consumer wrappers without `ref` use are harmless.
- **Did not touch the auto-redirect for returning users** — that path still does the `AuthHistory` lookup in `_SplashScreenState._resolveReturning` and continues to short-circuit to `/signin`. So the fork by install-history is now exclusively at the splash level (tap or no tap), and the button itself is a pure navigation primitive.
- **First-time → sign-in → sign-up** is one extra tap compared to the old behavior, but the old behavior had no way to recover for someone who already had an account but landed on /signup. The new flow is symmetric (everyone enters via /signin).

## User prompt (verbatim)

> I want go signin screen when the user click "tap begin" on splash
