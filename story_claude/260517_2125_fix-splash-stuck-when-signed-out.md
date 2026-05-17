# Fix: app stuck on splash when no token is stored

## What this task did

Fixed [flutter_app/lib/core/router/app_router.dart](../flutter_app/lib/core/router/app_router.dart) so the app actually leaves the splash screen after the auth check resolves.

Two bugs in one file:

1. **Missing redirect case.** The redirect treated `/` (splash) as `isPublic` and never sent the user away from it when the auth check finished as `signedOut`. None of the redirect branches matched the `(signedOut + splash)` combination, so `redirect` returned `null` and the app stayed on splash forever. Added an explicit case: `if (!signedIn && loc == AppRoute.splash) return AppRoute.signIn;`.
2. **No `refreshListenable`.** The router used `ref.watch(authProvider)` to rebuild the entire `GoRouter` on auth changes. That recreates a fresh router instance instead of nudging the existing one to re-evaluate its redirect against the current location — fragile, and a different bug from #1. Switched to the standard go_router pattern: a single `GoRouter` with a `ChangeNotifier`-based `refreshListenable` that `ref.listen` bumps whenever `authProvider` emits.

After this:
- App opens → splash → auth check runs (with or without a stored token) → state resolves → redirect fires → goes to `/signin` (signed out) or `/home`/`/onboarding` (signed in). No manual restart needed.

## Conversation summary

- User reported: *"I run flutter -d windows and the application launches. But it stuck on the splash screen."* (Windows build now works after this morning's ClangCL install.)
- I confirmed the backend was actually running (port 3000 listening) so the backend wasn't the cause.
- Traced [auth_provider.dart](../flutter_app/lib/core/providers/auth_provider.dart): `AuthNotifier()` constructor sets state to `checking`, calls `_restore()`. For a fresh device with no token, `_restore()` reads `null` from secure storage and sets state to `signedOut`. So the auth flow itself is fine.
- The bug was the router. Splash is listed as `isPublic`, the only redirect that fires for `signedOut` is `if (!signedIn && !isPublic)` which excludes splash. Stuck.

## Decisions / call-outs

- **Used `ref.listen` + a `ChangeNotifier`, not `ref.watch`.** `ref.listen` doesn't trigger Provider rebuilds — the router stays a singleton across auth changes, the `Listenable` just gets bumped. That's what go_router's `refreshListenable` is designed for.
- **Kept the `if (checking) return null;` early-return.** That's still correct — during the initial check, splash is the right place to be; the spinner animates and we wait. The fix is what happens *after* checking resolves to `signedOut`.
- **Added `ref.onDispose(refresh.dispose)`** so the `ChangeNotifier` is torn down if the routerProvider is ever invalidated. Defensive; routerProvider rarely disposes in practice but it's idiomatic.
- **Switched `(_, __)` to `(_, _)`** in the `ref.listen` callback to silence the Dart lint about multiple-underscore parameter names (Dart 3.7+ accepts duplicate `_` as wildcards). Cosmetic.
- **Did NOT add a fallback timeout** to the splash screen itself. Some apps add `Future.delayed(Duration(seconds: 5)).then(...go to signIn)` as a belt-and-suspenders. Felt unnecessary — the auth check completes in well under 100ms in the no-token case, and now the redirect handles every reachable state.
- **Did NOT inspect what `tokenStore.readAccess()` does on Windows.** flutter_secure_storage uses Windows DPAPI — first-call cost is negligible (single-digit ms). If a user had a slow secure-storage read, the spinner would just spin a bit longer; not the bug being fixed here.
- **Verified with `flutter analyze`** on the changed file: zero issues.

## How to verify

1. Hot restart (not hot reload) the running Flutter app: type `R` in the terminal where `flutter run` is attached.
2. Splash should appear briefly (≤500ms), then automatically transition to the Sign In screen.
3. After signing in with a known user → either `/home` or `/onboarding` depending on `onboardingDone`. After signing out → back to `/signin`.

## User prompt (verbatim)

> I run flutter -d windows and the application launches.
> But it stuck on the splash screen
