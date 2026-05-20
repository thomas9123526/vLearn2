# Another exception was thrown: GoError: There is nothing to pop

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-20T15:52:47.503Z

## User

Another exception was thrown: GoError: There is nothing to pop

## Assistant

Let me find where `context.pop()` is being called without a route to pop back to.

## Assistant

The error happens when the splash auto-routes a first-time user to `/signup` (via `context.go`, which replaces the stack), and the user then taps the back button — `context.pop()` has nothing to pop. Fix: fall back to `/signin` when there's nothing to pop.

## Assistant

Now let me also check the other `context.pop()` sites to see if any have the same exposure.

## Assistant

Those other sites (`scenario_brief_screen`, `conversation_history_screen`, `tutor_mode_view`) are only reachable via `context.push` from other in-app screens, so their pops are safe. Only `/signup` is exposed via the splash's `context.go`.

## Assistant

Clean. Now commit + story log.

## Assistant

Fixed and committed (`fefa759`).

**Root cause** — When the splash auto-routes a first-time user to `/signup` via `context.go`, that replaces the stack, so `/signup` is the only route. The AppBar back arrow at [sign_up_screen.dart:91](flutter_app/lib/features/auth/sign_up_screen.dart#L91) was calling `context.pop()` unconditionally, which throws `GoError: There is nothing to pop`.

**Fix** — Guard with `context.canPop()` and fall back to `context.go(AppRoute.signIn)` when there's nothing to pop. The other pop sites in the app (`scenario_brief`, `conversation_history`, `tutor_mode_view`) are only reachable via `context.push` from other in-app screens, so they're safe and untouched.
