# Report — 10_testing

**Spec:** [todoList/0516/10_testing.md](../../todoList/0516/10_testing.md)
**Date:** 2026-05-16
**Status:** ✅ Sample tests in both projects (6 backend + 4 Flutter); CI workflows run them on every push

## What was done

### Backend (Jest)

- **[backend/src/ai/prompt-builder.service.spec.ts](../../backend/src/ai/prompt-builder.service.spec.ts)** — 2 tests for the prompt builder: persona name + level appear in the system prompt; grammar prompt lists numbered messages with the level
- **[backend/src/guard/content-guard.service.spec.ts](../../backend/src/guard/content-guard.service.spec.ts)** — 4 tests for the content guard: clean text passes; substring false-positives (Scunthorpe problem) avoided; mild profanity warns; severe profanity blocks
- `npm test` → **6 / 6 passing** in 1.5s
- `npm run test:e2e` infrastructure exists (from `nest new`) — populating it requires a test DB; deferred until traffic justifies

### Flutter (flutter_test)

- **[flutter_app/test/guard/content_guard_test.dart](../../flutter_app/test/guard/content_guard_test.dart)** — 4 tests mirroring the backend guard tests + an init-from-assets test
- `flutter test` → **4 / 4 passing**

### CI

- `.github/workflows/flutter_ci.yml` runs `flutter analyze && flutter test` on every push that touches `flutter_app/**`
- `.github/workflows/backend_ci.yml` runs `npm run lint && npm run build && npm test` on every push that touches `backend/**`. Postgres service container is up so future e2e tests can run

## Honest call-outs

1. **Coverage is sparse** — these are sanity tests, not a comprehensive suite. The point of v1 is to prove the tooling works; growing coverage is incremental.

2. **No E2E backend tests** that hit the DB. The infrastructure (postgres service in CI, supertest scaffold from `nest new`) is in place; writing them is a follow-up. Highest-value targets are auth (signup → signin → refresh) and conversation lifecycle.

3. **No Flutter integration tests** (`integration_test/`) that actually drive the app via WebDriver / Android instrumentation. The widget test layer is what's wired today. Real device test grids (Firebase Test Lab, BrowserStack) are post-MVP.

4. **No load tests / perf tests.** Backend should hold up under 100 concurrent users without much tuning thanks to TypeORM's connection pooling; benchmarking awaits real traffic.
