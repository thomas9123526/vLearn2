# I want go signin screen when the user click "tap begin" on splash

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-20T16:10:23.659Z

## User

I want go signin screen when the user click "tap begin" on splash

## Assistant

Quick check — does the sign-in screen link out to sign-up so first-time users have a path to register?

## Assistant

Good — `/signin` already links out to `/signup`. So Tap-to-begin always going to `/signin` works for both first-timers and returning users. Updating the button now.

## Assistant

Clean. Commit and log.

## Assistant

Done — committed as `ce3205f`.

**Change** ([splash_screen.dart:805-811](flutter_app/lib/features/splash/splash_screen.dart#L805-L811)): Tap-to-begin now navigates straight to `/signin`. The `hasEverSignedIn()` lookup is gone from the button, so `_begin()` is synchronous.

**For first-time users**: `/signin` already carries a "Don't have an account? Sign up" link to `/signup`, so they still have a one-tap path to register.

**Returning-user auto-redirect untouched**: the `_resolveReturning` path that auto-routes returning devices to `/signin` after the splash animation still works — install-history forking now lives exclusively there, not in the button.
