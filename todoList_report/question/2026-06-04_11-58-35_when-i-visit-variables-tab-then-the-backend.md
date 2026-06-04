# when i visit variables tab then the backend crashed like this. ERROR [Exceptions

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-04T02:58:35.776Z

## User

when i visit variables tab then the backend crashed like this.

ERROR [ExceptionsHandler] EntityMetadataNotFoundError: No metadata for "PromptVarEntity" was found.
    at DataSource.getMetadata (C:\project\vLearn2\backend\node_modules\typeorm\data-source\src\data-source\DataSource.ts:451:30)
    at Repository.get metadata (C:\project\vLearn2\backend\node_modules\typeorm\repository\src\repository\Repository.ts:55:40)
    at Repository.find (C:\project\vLearn2\backend\node_modules\typeorm\repository\src\repository\Repository.ts:581:39)
    at AdminPromptVarsController.list (C:\project\vLearn2\backend\src\admin\admin-prompt-vars.controller.ts:77:22)
    at C:\project\vLearn2\backend\node_modules\@nestjs\core\router\router-execution-context.js:38:29
    at InterceptorsConsumer.transformDeferred (C:\project\vLearn2\backend\node_modules\@nestjs\core\interceptors\interceptors-consumer.js:31:33)
    at C:\project\vLearn2\backend\node_modules\@nestjs\core\interceptors\interceptors-consumer.js:18:86
    at AsyncResource.runInAsyncScope (node:async_hooks:203:9)
    at bound (node:async_hooks:235:16)

So I have to test all the cases for the backend, admin panel and flutter application.
What proper way to automate this test all cases?
Suggest me

## Assistant

Two things: fix the crash first (quick), then I'll give you a concrete testing strategy.

The error means `PromptVarEntity` isn't connected to the TypeORM data-source. Let me find why.

## Assistant

The entity is in `forFeature()` — the issue is in the TypeORM config. Let me check.

## Assistant

Found it — entities must be in the `ALL_ENTITIES` array. Let me check the index.

## Assistant

`PromptVarEntity` is missing from `ALL_ENTITIES`. One-line fix:

## Assistant

Now commit the fix, then answer the testing question:

## Assistant

Bug fixed. Now for the testing question:

---

## Testing strategy for vLearn2

This is a practical recommendation, not a "write 500 tests" plan. The right approach is **layered** — each layer catches a different class of bug.

### The core insight

The bug you just hit (`PromptVarEntity` not in `ALL_ENTITIES`) is a **wiring** bug — no unit test would catch it, only an integration test that actually boots the NestJS app and talks to the DB. This tells you where to focus.

---

### Layer 1 — Backend integration tests (highest value here)

**Tool:** Jest + Supertest + a real test Postgres DB (Docker)

**What to test:** Every API endpoint — does it return the right shape? Does the DB get updated correctly? Does auth/permission work?

```
backend/test/
  admin-prompt-vars.e2e-spec.ts   ← the bug you just hit
  admin-scenarios.e2e-spec.ts
  conversations.e2e-spec.ts
  ...
```

Each test:
1. Boots the full NestJS app (`@nestjs/testing` + `supertest`)
2. Hits the real endpoint with real HTTP
3. Checks status code + response shape
4. Rolls back DB after each test (transactions or `beforeEach` truncate)

This catches: entity registration bugs, migration mismatches, DTO validation failures, permission errors.

**Effort:** Medium. NestJS has built-in support for this. One `global.setup.ts` to start the app, then each spec is ~20-30 lines.

---

### Layer 2 — Admin panel API contract tests (low effort, high catch rate)

**Tool:** Playwright or Vitest + MSW (mock service worker)

**What to test:** Does each page load? Does the form submit? Does the table render rows?

Since Next.js admin panel is thin (fetch → display → edit), the highest-value tests are:
- **Page smoke tests**: does `/prompt-vars` load without crashing?
- **Form submit**: does editing a variable call the right endpoint?

Not worth mocking individual components — the pages are the unit.

**Effort:** Low. Playwright can record tests by clicking through the UI.

---

### Layer 3 — Flutter widget tests (for the session report screen)

**Tool:** Flutter's built-in `flutter_test` + `mockito`

**What to test:** Does `SessionReportScreen` render the session feedback prose? Does `_TurnFeedbackItem` show with the right severity color? Does polling stop after max attempts?

```dart
// test/features/report/session_report_screen_test.dart
testWidgets('shows session feedback before scores', (tester) async {
  final fakeScore = {
    'sessionFeedback': 'The learner demonstrated...',
    'cefrEstimate': 'B1',
    'fluencyScore': 80,
    ...
  };
  // pump the widget with fake data, verify order
});
```

This catches: null-check crashes from new fields, conditional display logic errors.

**Effort:** Low per widget, but requires setting up `mockito` for the API provider.

---

### What to do RIGHT NOW (prioritized)

| Priority | Test | Why |
|---|---|---|
| 1 | NestJS e2e: boot app, hit `/admin/prompt-vars` | Catches the exact class of bug you just hit |
| 2 | NestJS e2e: `POST /conversations/sessions` → end → poll score | Full evaluation pipeline |
| 3 | Flutter widget: `SessionReportScreen` with mock score data | Catches null crashes from new fields |
| 4 | Admin panel: Playwright smoke — all pages load | Catches wiring/import errors |

---

### The wiring bug prevention rule (no tests needed)

The root cause pattern is: **new entity added to a module's `forFeature()` but not to `ALL_ENTITIES`**. You can prevent the whole class by adding `autoLoadEntities: true` to the TypeORM config:

```typescript
// typeorm-config.factory.ts
export const typeormConfigFactory = (config: ConfigService): TypeOrmModuleOptions => ({
  ...
  autoLoadEntities: true,   // ← add this; entities array becomes optional
  entities: ALL_ENTITIES,   // keep as backup / for migrations CLI
```

With `autoLoadEntities: true`, any entity registered in ANY module's `forFeature()` is automatically added to the DataSource — so this bug can't happen again regardless of tests.

Want me to implement any of these? The e2e test setup for the NestJS backend is the most valuable and I can scaffold it now.
