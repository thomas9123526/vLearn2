# Report — 04_flutter_architecture

**Spec:** [todoList/0516/04_flutter_architecture.md](../../todoList/0516/04_flutter_architecture.md)
**Date:** 2026-05-16
**Status:** ✅ Foundation complete — auth flow runnable end-to-end; screens are stubs that §05 will fill

## What was done

The Flutter app now has the complete architectural foundation: theme tokens + 4 themes (apricot/sage/iris/obsidian), a layered Dio API client with auth/error/compression interceptors, plain-Dart models, a state-notifier auth provider with token rotation, an auth-aware `go_router` configuration, and `MaterialApp.router` wired in `main.dart`. Sign-in/sign-up are real implementations; the four main-tab screens and the conversation/report/onboarding screens are intentional stubs that §05 fills in.

### Theme system — [lib/core/theme/](../../flutter_app/lib/core/theme/)

- **[app_tokens.dart](../../flutter_app/lib/core/theme/app_tokens.dart)** — design tokens shared across themes: spacing scale (4pt grid), border radius (sm/md/lg/xl/full), elevation shadows, animation durations
- **`AppPalette`** with 4 named palettes (`apricot`, `sage`, `iris`, `obsidian`) — primary, primaryDark, accent, background, surface, surfaceVariant, onSurface, onSurfaceMuted, outline, success, warning, error. `AppPalette.byKey` lookup map
- **[app_theme.dart](../../flutter_app/lib/core/theme/app_theme.dart)** `AppTheme.build(paletteKey)` — composes Material 3 `ColorScheme` + `GoogleFonts.interTextTheme` + customized AppBar / Card / FilledButton / OutlinedButton / InputDecoration / Chip / NavigationBar themes. `obsidian` switches to `Brightness.dark`

### API client — [lib/core/api/](../../flutter_app/lib/core/api/)

- **[api_client.dart](../../flutter_app/lib/core/api/api_client.dart)** — `apiClientProvider` builds a configured `Dio` with 10s connect / 30s receive timeouts, base URL from `--dart-define=API_BASE_URL=...` (default `http://localhost:3000/api`)
- **`TokenStore`** wraps `flutter_secure_storage` — `readAccess` / `readRefresh` / `writePair` / `clear`. Exposed via `tokenStoreProvider`
- **[auth_interceptor.dart](../../flutter_app/lib/core/api/interceptors/auth_interceptor.dart)** — attaches `Authorization: Bearer …` to outgoing requests (unless `extra.skipAuth=true` is set); on 401 it tries `POST /auth/refresh` exactly once via a fresh Dio (so the refresh call doesn't recurse through this interceptor), then retries the original. On refresh failure: clears tokens and surfaces the original 401
- **[error_interceptor.dart](../../flutter_app/lib/core/api/interceptors/error_interceptor.dart)** — translates `DioException` into a typed `ApiException` exposing `statusCode`, `i18nKey`, `message`, `extra` (for context like suspension info), and convenience getters (`isUnauthorized`, `isForbidden`, `isServerError`, `isNetwork`)
- **[compression_interceptor.dart](../../flutter_app/lib/core/api/interceptors/compression_interceptor.dart)** — flips `Accept-Encoding` between `gzip` (when `compression_enabled=true` in settings) and `identity` per [11 §11.2](../../todoList/0516/11_security_and_performance.md). Dio auto-decompresses gzipped responses
- **[auth_api.dart](../../flutter_app/lib/core/api/auth_api.dart)** — `signUp`/`signIn`/`me`/`signOut` as hand-rolled Dio calls (no Retrofit codegen). `extra: {skipAuth: true}` on signup/signin so AuthInterceptor skips them
- **[app_apis.dart](../../flutter_app/lib/core/api/app_apis.dart)** — `UsersApi`, `PersonasApi`, `ScenariosApi`, `CoursesApi`, `ConversationsApi`, `ProgressApi`, `AchievementsApi`. Each one matches the §03 backend endpoints 1:1. All exposed via per-API Riverpod providers

### Models — [lib/core/models/models.dart](../../flutter_app/lib/core/models/models.dart)

Plain Dart classes — deliberately not Freezed (codegen-free for now; can layer Freezed in later if needed). `fromJson` factories handle both snake_case (from raw DB columns) and camelCase (from DTOs).

| Model | Used by |
|-------|---------|
| `UserProfile` | auth provider, settings screen |
| `Persona` | tutor carousel, conversation header |
| `I18nText` with `forLocale(code)` helper | scenarios, courses, achievements |
| `Scenario` | scenarios list/detail, conversation start |
| `ConversationSession` + `ConversationMessage` | conversation + report screens |

### Providers — [lib/core/providers/](../../flutter_app/lib/core/providers/)

- **[auth_provider.dart](../../flutter_app/lib/core/providers/auth_provider.dart)** — `AuthNotifier` (`StateNotifier<AuthState>`) with `AuthStatus { checking, signedOut, signedIn }`. Restores session on app start by reading stored token + calling `/users/profile`; clears + signs out on token invalid. Exposes `signIn`, `signUp`, `signOut`, `refreshProfile`
- **[settings_provider.dart](../../flutter_app/lib/core/providers/settings_provider.dart)** — `AppSettingsNotifier` backed by `SharedPreferences` for hot-path synchronous reads. Convenience selectors: `themeKeyProvider`, `localeProvider`, `compressionEnabledProvider`

### Router — [lib/core/router/app_router.dart](../../flutter_app/lib/core/router/app_router.dart)

- `AppRoute` constants for every route
- **Auth-aware redirect**: signed-in users hitting `/signin` or `/signup` are bounced to `/home` (or `/onboarding` if `onboardingDone=false`); signed-out users hitting protected routes are bounced to `/signin`. Splash is unaffected during `AuthStatus.checking`
- **ShellRoute** wraps the four main-nav tabs (`home`/`scenarios`/`progress`/`settings`) with `AppShell` — a `NavigationBar` whose active tab is computed from `GoRouterState.matchedLocation`
- Fullscreen routes (no shell): conversation, session report, course detail, profile edit, splash, sign-in/up, onboarding

### Screens

**Real implementations:**

| Screen | File | Purpose |
|--------|------|---------|
| Splash | [features/splash/splash_screen.dart](../../flutter_app/lib/features/splash/splash_screen.dart) | Logo + spinner while `AuthNotifier._restore()` runs |
| Sign-in | [features/auth/sign_in_screen.dart](../../flutter_app/lib/features/auth/sign_in_screen.dart) | Form (email + password) with validation, loading state, inline error banner, link to sign-up |
| Sign-up | [features/auth/sign_up_screen.dart](../../flutter_app/lib/features/auth/sign_up_screen.dart) | Form with name + email + password (strength regex matching the backend's `SignUpDto`) + UI language dropdown |
| Onboarding | [features/onboarding/onboarding_screen.dart](../../flutter_app/lib/features/onboarding/onboarding_screen.dart) | Welcome screen; "Let's go" sets `onboardingDone=true` via `PATCH /users/profile` then `refreshProfile()` |
| Settings | [features/settings/settings_screen.dart](../../flutter_app/lib/features/settings/settings_screen.dart) | Profile header + theme picker (bottom sheet) + language picker + compression toggle + sign-out |

**Stubs (§05 fills in):**

- [home_screen.dart](../../flutter_app/lib/features/home/home_screen.dart) · [scenarios_screen.dart](../../flutter_app/lib/features/scenarios/scenarios_screen.dart) · [conversation_screen.dart](../../flutter_app/lib/features/conversation/conversation_screen.dart) · [session_report_screen.dart](../../flutter_app/lib/features/report/session_report_screen.dart) · [progress_screen.dart](../../flutter_app/lib/features/progress/progress_screen.dart) · [course_detail_screen.dart](../../flutter_app/lib/features/course/course_detail_screen.dart) · [profile_edit_screen.dart](../../flutter_app/lib/features/settings/profile_edit_screen.dart)

All share a single **`StubScreen`** widget that renders a labeled placeholder so the router compiles and the navigation flow is testable end-to-end.

### main.dart — [lib/main.dart](../../flutter_app/lib/main.dart)

`MaterialApp.router` consuming `routerProvider`. Theme and locale come from `themeKeyProvider` / `localeProvider`. Supported locales = en/ko/zh. `flutter_localizations` delegates loaded (real ARB delegate lands in §08).

## Honest call-outs

1. **No `localizationsDelegates: [AppLocalizations.delegate]` yet.** That arrives with the generated ARB file in §08. Today the `supportedLocales` are declared but actual string translations happen via inline English text.

2. **`AuthNotifier._restore()` calls `/users/profile` even before a valid token may exist.** If `tokenStore.readAccess()` returns null we short-circuit to `signedOut`; if it returns a stale token, the call fails with 401 and we sign out cleanly. The cost is one wasted HTTP request on app start when the token is expired beyond refresh — acceptable.

3. **The router redirect doesn't gate the onboarding screen specifically.** If a user with `onboardingDone=true` navigates to `/onboarding` manually, they reach it. Not a real issue since the only entry is via the redirect after signup. A stricter gate could be added in §05.

4. **`flutter_secure_storage` on Windows uses the Credential Manager API.** First run may prompt for credential storage — this is normal. On Android it uses EncryptedSharedPreferences (requires the minSdk=24 we set in §01).

5. **No offline cache reads yet.** The Drift schema exists from §02 and the tables are declared, but no repository layer reads/writes them yet. API providers go straight to Dio. Repository layer with offline-first semantics lands when the screens that need it arrive in §05 — designing the cache strategy without concrete consumers would be premature.

6. **No Freezed for models.** Plain classes with `fromJson` factories. Easier to write, faster to compile, no codegen step. If we later need `copyWith` + value equality, we can layer Freezed in selectively.

7. **`retrofit_generator` stays removed.** All API clients are hand-rolled Dio. This is verbose but avoids the analyzer incompat noted in §02.

## Verification

```bash
cd flutter_app && flutter analyze
# → No issues found!

# To run the app:
flutter run -d windows   # or -d <android-device>
# → Splash → sign-in screen (or home if already signed in)
```

## What's next

§05 — the 13 real screens (Home, Scenarios list/detail, Conversation chat+face modes, Session report with radar/score breakdown, Progress dashboard, Course detail, Profile edit, etc) built on top of this foundation. Each replaces a `StubScreen` and starts wiring real API data via the providers we just declared.
