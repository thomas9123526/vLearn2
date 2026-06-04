# Conversation - Set up full test infrastructure for backend, admin panel, Flutter

| Field | Value |
|---|---|
| Saved | 2026-06-04 12:11:04 |
| Commit | Add full test infrastructure: backend e2e, admin Playwright, Flutter widget tests, combined runner |
| Project | C:\project\vLearn2 |

---

## User

yes setup for me and let me know how can i use it for each backend, admin panel, flutter.
I want mechanism to run the script so the script test all the cases and report about this.

Also for evaluation remember this: [5-dimension scoring rubric for fluency/accuracy/vocabulary/interaction/topic_adherence]

## Assistant

### What was built

**1. `autoLoadEntities: true` + `DB_SYNCHRONIZE` support** in `typeorm-config.factory.ts` — prevents the PromptVarEntity-class bug forever.

**2. Backend e2e tests** (`backend/test/`)
- `test/setup.ts` — loads `.env.test` before each test worker
- `test/helpers/test-app.ts` — boots full NestJS app pointed at `vlearn2_test` DB
- `test/helpers/auth.helper.ts` — creates real admin/user tokens via auth endpoints
- `test/health.e2e-spec.ts` — health check (no DB)
- `test/admin-prompt-vars.e2e-spec.ts` — CRUD for prompt vars (catches entity wiring bugs)
- `test/admin-prompt-templates.e2e-spec.ts` — prompt template list + patch
- `test/conversations.e2e-spec.ts` — session lifecycle: start → message → end → score poll
- `test/jest-e2e.json` — updated with setupFiles, timeout, forceExit
- `backend/.env.test.example` — template for test credentials

**3. Admin panel Playwright** (`admin_panel/`)
- `playwright.config.ts` — chromium, headless, auth state reuse
- `e2e/auth.setup.ts` — logs in once, saves storage state
- `e2e/smoke.spec.ts` — smoke tests for every page including the `/prompt-vars` crash page

**4. Flutter widget tests** (`flutter_app/test/features/report/`)
- `session_report_screen_test.dart` — tests score mapping, dot conversion, feedback filtering, state logic, widget rendering

**5. Combined runner** (`cmds/run-tests.ps1`)
- Runs all suites, auto-skips e2e if servers not running
- Color-coded pass/fail/skip report
- Saves `test-results/summary.json`

**6. Evaluation scoring rubric** added to `DEFAULT_EVALUATION_SYSTEM` and migration `1782800000000`

### How to run

```powershell
# All suites (skips admin e2e if servers not running)
.\cmds\run-tests.ps1

# Individual suites
.\cmds\run-tests.ps1 -Suite backend
.\cmds\run-tests.ps1 -Suite admin
.\cmds\run-tests.ps1 -Suite flutter

# Skip browser tests
.\cmds\run-tests.ps1 -Quick
```

**Backend e2e setup (one time):**
```powershell
cp backend/.env.test.example backend/.env.test
# edit backend/.env.test with your passwords
createdb vlearn2_test   # or via pgAdmin
cd backend && npm run test:e2e:setup
```

**Admin e2e (requires running servers):**
```powershell
# Terminal 1: cd backend && npm run start:dev
# Terminal 2: cd admin_panel && npm run dev
.\cmds\run-tests.ps1 -Suite admin
```

**Flutter:**
```powershell
cd flutter_app && flutter test
```

---

## Prompt

yes setup for me and let me know how can i use it for each backend, admin panel, flutter.
I want mechanism to run the script so the script test all the cases and report about this.
