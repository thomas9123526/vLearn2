# I want logic that If the user already signin before, the user can go signin scre

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-20T15:46:42.326Z

## User

I want logic that If the user already signin before, the user can go signin screen directly after splash showed.

## Assistant

Adding auto-redirect to `/signin` for returning users after the splash plays. First-time users keep the Tap-to-begin → `/signup` flow.

## Assistant

Now hide the Tap-to-begin button for returning users (and during the initial check) so they don't see it flash before the auto-redirect fires.

## Assistant

Now verify the file analyzes cleanly.

## Assistant

Single-file change — no todo list needed. Now let me follow the auto-commit policy by checking the story-claude format.

## Assistant

The previous session left several files uncommitted. I'll commit everything together with a descriptive message focused on the current change.

## Assistant

Done. Splash now auto-routes returning users to `/signin` after the entrance animation plays.

**What changed** ([flutter_app/lib/features/splash/splash_screen.dart](flutter_app/lib/features/splash/splash_screen.dart)):
- `SplashScreen` converted to `ConsumerStatefulWidget` so it can `ref.read(authHistoryProvider)`.
- On mount, reads `hasEverSignedIn()`; if `true`, a 2-second `Timer` pushes `/signin` (cancelled on dispose).
- "Tap to begin" CTA is hidden while the SharedPreferences read is in flight and for returning users, so a returning device never flashes the button before the auto-redirect fires.
- First-time users (`_returning == false`) keep the existing CTA → `/signup` flow unchanged.

`flutter analyze` on the file: clean. Committed as `3678979`, with the bundled prior uncommitted work (`auth_history.dart`, `auth_provider` hookup, app_shell desktop sidebar) folded into the same commit since they all belong to the same splash/auth flow.
