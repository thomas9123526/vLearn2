# 04 – Flutter App Architecture

**Cross-cutting concerns spec'd in separate files** (still live under `lib/core/`):
- Content guard (client-side wordlist check) — [11 §11.1](11_security_and_performance.md) — `lib/core/guard/`
- Compression interceptor (Dio `Accept-Encoding` toggle) — [11 §11.2](11_security_and_performance.md) — `lib/core/api/interceptors/`
- **Layout visibility + remote-config** — [12](12_admin_visibility.md) — `lib/core/config/layout_config_provider.dart` + `lib/shared/widgets/layout_visibility.dart`. Every screen section listed in §12.6 wraps its content with `LayoutVisibility` so the admin panel can toggle it remotely without an APK rebuild.

## 4.1 Folder Structure

```
lib/
├── core/
│   ├── api/
│   │   ├── api_client.dart           # Dio client factory
│   │   ├── auth_api.dart             # Retrofit auth endpoints
│   │   ├── user_api.dart
│   │   ├── scenario_api.dart
│   │   ├── conversation_api.dart
│   │   ├── progress_api.dart
│   │   ├── course_api.dart
│   │   └── interceptors/
│   │       ├── auth_interceptor.dart # Auto-attach JWT, refresh on 401
│   │       └── logging_interceptor.dart
│   ├── db/
│   │   ├── app_database.dart         # Drift database class
│   │   ├── tables/                   # Drift table definitions
│   │   └── daos/                     # Data access objects
│   ├── models/
│   │   ├── user.dart                 # Freezed models
│   │   ├── persona.dart
│   │   ├── scenario.dart
│   │   ├── conversation.dart
│   │   ├── message.dart
│   │   ├── progress.dart
│   │   ├── session_score.dart
│   │   └── achievement.dart
│   ├── providers/
│   │   ├── auth_provider.dart        # AuthNotifier (Riverpod)
│   │   ├── theme_provider.dart
│   │   ├── locale_provider.dart
│   │   ├── user_provider.dart
│   │   └── connectivity_provider.dart
│   ├── router/
│   │   ├── app_router.dart           # go_router config
│   │   └── route_names.dart          # Route path constants
│   ├── theme/
│   │   ├── app_theme.dart            # ThemeData factory
│   │   ├── app_colors.dart           # 4 palettes from tokens.json
│   │   ├── app_typography.dart       # Text styles
│   │   ├── app_spacing.dart          # Spacing constants
│   │   └── app_shadows.dart
│   └── utils/
│       ├── extensions.dart
│       ├── date_utils.dart
│       └── validators.dart
├── features/
│   ├── auth/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   ├── home/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   ├── scenarios/
│   ├── conversation/
│   │   ├── providers/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── rive/               # Rive animation controllers
│   ├── report/
│   ├── progress/
│   ├── course/
│   └── settings/
├── shared/
│   ├── widgets/
│   │   ├── avatar.dart
│   │   ├── score_ring.dart
│   │   ├── animated_bar.dart
│   │   ├── animated_number.dart
│   │   ├── talking_avatar.dart
│   │   ├── voice_bubble.dart
│   │   ├── confetti_burst.dart
│   │   ├── app_button.dart
│   │   ├── app_chip.dart
│   │   ├── app_card.dart
│   │   └── section_head.dart
│   └── dialogs/
│       ├── notification_dialog.dart
│       └── edit_profile_dialog.dart
├── l10n/
│   ├── app_en.arb
│   ├── app_ko.arb
│   └── app_zh.arb
└── main.dart
```

## 4.2 State Management (Riverpod)

### Auth State
- [ ] **4.2.1** `AuthNotifier extends AsyncNotifier<AuthState>`
  - States: `unauthenticated`, `loading`, `authenticated(User)`, `error`
  - Methods: `signIn()`, `signUp()`, `signOut()`, `refreshToken()`
  - Auto-restore session from SQLite on app start
- [ ] **4.2.2** `authProvider` (StateNotifierProvider)
- [ ] **4.2.3** Token refresh: interceptor calls `authProvider.refresh()` on 401

### Theme State
- [ ] **4.2.4** `themeProvider` — reads from AppSettings SQLite table
  - Returns `AppThemeData` (colors, fonts for current theme + persona)
- [ ] **4.2.5** `localeProvider` — returns `Locale` from AppSettings

### Conversation State
- [ ] **4.2.6** `ConversationNotifier extends AsyncNotifier<ConversationState>`
  - State: `{ session, messages, isLoading, isTutorTyping, avatarState }`
  - `startSession(scenarioId?, personaId, mode)`
  - `sendMessage(content)` → update messages + animate avatar
  - `endSession()` → navigate to report
- [ ] **4.2.7** `avatarStateProvider` — `speaking | listening | thinking | idle`

### Home / Progress
- [ ] **4.2.8** `homeDataProvider` — FutureProvider fetching dashboard data
- [ ] **4.2.9** `progressProvider` — FutureProvider for progress screen
- [ ] **4.2.10** `scenariosProvider` — FutureProvider with category/difficulty filter params

## 4.3 Routing (go_router)

```dart
// Route structure
/splash
/onboarding
/signin
/signup
/home                    ← shell route (bottom nav / sidebar)
  /scenarios
    /scenarios/:id/brief
  /progress
  /course
  /settings
/conversation/:sessionId
/report/:sessionId
```

- [ ] **4.3.1** `GoRouter` with `redirect` for auth guard:
  - Not authenticated → redirect to `/signin`
  - Authenticated + onboarding not done → redirect to `/onboarding`
- [ ] **4.3.2** `ShellRoute` for bottom nav (mobile) / sidebar (desktop)
- [ ] **4.3.3** Route transitions: slide for forward nav, fade for tab switches
- [ ] **4.3.4** Deep link support (Android intent filters)

## 4.4 API Client (Dio + Retrofit)

- [ ] **4.4.1** Base Dio configuration:
  - `baseUrl` from env (debug/release)
  - `connectTimeout: 10s`, `receiveTimeout: 30s`
  - JSON headers
- [ ] **4.4.2** `AuthInterceptor`:
  - Attach `Authorization: Bearer {accessToken}` to all requests
  - On 401: call `POST /auth/refresh`, retry original request
  - On refresh failure: sign out
- [ ] **4.4.3** Generate Retrofit clients via build_runner

## 4.5 Responsive Layout

- [ ] **4.5.1** `LayoutBreakpoints`: mobile < 600px width, desktop ≥ 600px
- [ ] **4.5.2** `AppShell` widget: renders `MobileShell` or `DesktopShell` based on breakpoint
- [ ] **4.5.3** `MobileShell`: `Scaffold` with `BottomNavigationBar` (4 tabs: Home, Scenarios, Progress, Settings)
- [ ] **4.5.4** `DesktopShell`: `Row` with 240px sidebar + main content area
- [ ] **4.5.5** Content max-width 600dp on desktop, center-aligned
- [ ] **4.5.6** Sidebar items: Home, Scenarios, Progress, Course, Settings + Profile at bottom

## 4.6 Theme System

- [ ] **4.6.1** `AppColors` class with static maps for each theme:
  ```dart
  static const Map<String, ThemePalette> palettes = {
    'apricot': ThemePalette(primary: Color(0xFFE8956D), ...),
    'sage':    ThemePalette(primary: Color(0xFF7BAE92), ...),
    'iris':    ThemePalette(primary: Color(0xFF8B7EC8), ...),
    'obsidian':ThemePalette(primary: Color(0xFF3D3D4E), ...),
  };
  ```
- [ ] **4.6.2** `AppTypography`:
  - Display: Instrument Serif (Google Fonts)
  - UI: Plus Jakarta Sans (Google Fonts)
  - Mono: JetBrains Mono (Google Fonts)
  - CJK override: Noto Sans SC / Noto Sans KR
- [ ] **4.6.3** `AppTheme.build(palette, locale)` returns `ThemeData`
- [ ] **4.6.4** Persona accent colors applied to conversation header + avatar ring

## 4.7 Local Data Flow

```
API Response → Repository → Drift DAO (cache) → Riverpod Provider → UI
                                ↑
                         SQLite on disk
```

- [ ] **4.7.1** Repository pattern per feature (wraps API + Drift DAO)
- [ ] **4.7.2** Cache-first strategy: return cached data immediately, refresh in background
- [ ] **4.7.3** Offline mode: queue messages locally, sync when connectivity restored
- [ ] **4.7.4** Connectivity check via `connectivity_plus` package
