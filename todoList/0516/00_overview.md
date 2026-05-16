# vLearn2 – FreeTalk English Learning App
## Project Overview & Master Todo Index

**Target Platforms:** Android (Flutter) · Windows (Flutter)  
**Backend:** NestJS + PostgreSQL  
**App Local DB:** SQLite (via `drift` package)  
**AI Tutor Personas:** Maya · Leo · Sofia · Theo  
**Themes:** Apricot · Sage · Iris · Obsidian  
**i18n Languages:** English (en) · Korean (ko) · Chinese (zh)  
**Character Animation:** Rive (Flutter Rive package) — speaking / listening / thinking states  
**STT/TTS:** Deferred (placeholder hooks only)

---

## Todo File Index

| # | File | Scope |
|---|------|-------|
| 01 | [01_project_setup.md](01_project_setup.md) | Monorepo, tooling, CI scaffold |
| 02 | [02_database_schema.md](02_database_schema.md) | SQLite (app) + PostgreSQL (backend) schemas |
| 03 | [03_backend_api.md](03_backend_api.md) | NestJS modules, endpoints, business logic |
| 04 | [04_flutter_architecture.md](04_flutter_architecture.md) | App structure, state management, routing |
| 05 | [05_flutter_screens.md](05_flutter_screens.md) | All 12 screens implementation |
| 06 | [06_flutter_components.md](06_flutter_components.md) | Shared widgets & design system |
| 07 | [07_animation.md](07_animation.md) | Rive character animation integration |
| 08 | [08_i18n.md](08_i18n.md) | Internationalization (en/ko/zh) |
| 09 | [09_ai_integration.md](09_ai_integration.md) | Claude API conversation engine |
| 10 | [10_testing.md](10_testing.md) | Unit, widget, integration, API tests |
| 11 | [11_security_and_performance.md](11_security_and_performance.md) | Content guard (profanity filter) + conditional gzip compression |
| 12 | [12_admin_visibility.md](12_admin_visibility.md) | Layout visibility flags + remote-config system for future Next.js admin panel |
| 13 | [13_admin_content_and_users.md](13_admin_content_and_users.md) | Admin scenario/course/achievement CRUD + image uploads + user management + leaderboards + stats dashboard + unified audit log |
| 14 | [14_admin_permissions.md](14_admin_permissions.md) | Two-tier admin (Superadmin + Sub-admins) with granular permission catalog (RBAC) — single source of truth for `@RequirePermission()` on every admin endpoint |

---

## Delivery Phases

### Phase 1 — Foundation (Week 1-2)
- Project scaffold — two independent siblings: `backend/` (NestJS) and `flutter_app/` (Flutter), each runnable on its own
- Database schemas finalized
- Auth endpoints (sign-up, sign-in, JWT refresh)
- Flutter navigation shell + theme system
- i18n infrastructure

### Phase 2 — Core Features (Week 3-5)
- Onboarding / placement test
- Home dashboard with stats
- Scenario browser
- Conversation screen (chat mode) with Claude API
- Report screen
- All backend calculation endpoints

### Phase 3 — Polish (Week 6-7)
- Face-to-face mode with Rive animation
- Progress / analytics screens
- Course builder screen
- Settings (profile, tutor, theme, language)
- STT/TTS placeholder hooks

### Phase 4 — QA & Release (Week 8)
- End-to-end tests
- Performance audit
- Android APK + Windows MSIX builds
- CI/CD pipeline

---

## Technology Decisions

| Concern | Choice | Reason |
|---------|--------|--------|
| State management | Riverpod 2.x | Spec recommendation, compile-safe providers |
| Routing | go_router | Deep-link support, typed routes |
| HTTP client | Dio + retrofit | Interceptors for JWT, code-gen |
| Local DB | Drift (SQLite) | Type-safe, migrations, streams |
| Animation | Rive | Lightweight, state-machine driven |
| Backend ORM | TypeORM | NestJS native, PostgreSQL support |
| Auth | JWT (access 15m + refresh 7d) | Stateless, offline-friendly |
| AI | Anthropic Claude API (claude-sonnet-4-6) | Conversation engine |
| i18n (Flutter) | flutter_localizations + intl | Official, ARB format |
| i18n (NestJS) | nestjs-i18n | Middleware-based, JSON files |
