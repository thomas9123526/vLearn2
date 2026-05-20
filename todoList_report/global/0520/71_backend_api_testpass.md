# Task 71 — Backend API: find and verify testcases

## Scope
Locate every test in `backend/` and confirm they pass.

## Test inventory

### Unit specs (Jest, `npx jest`)
| File | Suite | Count |
| --- | --- | --- |
| `src/guard/content-guard.service.spec.ts` | `ContentGuardService` | 4 |
| `src/ai/prompt-builder.service.spec.ts` | `PromptBuilderService` | 2 |

What they cover:

* **ContentGuardService** — clean text passes, word boundaries prevent the
  Scunthorpe substring issue, mild profanity warns, severe profanity blocks.
* **PromptBuilderService** — tutor system prompt names persona / level /
  native language; grammar prompt numbers messages and includes level
  context.

### End-to-end specs (`backend/test/`, `npx jest --config ./test/jest-e2e.json`)
Existing `app.e2e-spec.ts` was the default Nest scaffold — it asserted
`GET /` returns `"Hello World!"`, which has not been true for this project
in many revisions. It also bootstrapped `AppModule`, which requires a real
Postgres and would hang in CI.

**Fix:** rewrote `app.e2e-spec.ts` to bootstrap a tiny test module
containing only `HealthController`. Asserts `GET /health` → 200 with
`{ status: 'ok', timestamp, uptime }`. No DB, no network, sub-second.

## Verification

```text
> npx jest
Test Suites: 2 passed, 2 total
Tests:       6 passed, 6 total

> npx jest --config ./test/jest-e2e.json
Test Suites: 1 passed, 1 total
Tests:       1 passed, 1 total
```

## Files modified
* `backend/test/app.e2e-spec.ts` — replaced stale scaffold test with a real
  `/health` e2e test.

## Summary
* Unit: 6/6 pass
* E2E:  1/1 pass
* Total: **7/7**.
