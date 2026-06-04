# I get error like this src/admin/admin-scenarios.controller.ts:257:31 - error TS2

Session: `ec7e9529-1399-4642-b1c1-753f53834cc7`
Saved: 2026-06-04T12:31:39.255Z

## User

I get error like this

src/admin/admin-scenarios.controller.ts:257:31 - error TS2339: Property 'difficulty' does not exist on type 'ScenarioEntity'.

257             difficulty: saved.difficulty,
                                  ~~~~~~~~~~

[9:25:21 PM] Found 1 error. Watching for file changes.

but when i run test with '..\cmds\run-tests.ps1 -Suite backend'
it says there's no error. why this happens?

## Assistant

The tests use `ts-jest` which transpiles without full type checking — it only fails at runtime if the bad code actually runs. The TypeScript compiler in watch mode (`tsc --watch`) does the full static check and catches it.

The fix is in the audit log object after `create()`. Let me find and remove `saved.difficulty`:

## Assistant

Fixed. The audit log in the `create` handler still referenced `saved.difficulty` — replaced with `saved.cefr_level`.

**Why tests passed but `tsc` failed:** `ts-jest` (used by Jest) transpiles TypeScript to JavaScript without running a full type check — it only fails if the problematic code actually executes at runtime. The audit log path wasn't covered by any test, so it compiled and ran silently. `tsc --watch` does a complete static type analysis and catches it regardless of code coverage.
