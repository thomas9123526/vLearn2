# Conversation - Fix backend unit test failures

| Field | Value |
|---|---|
| Saved | 2026-06-04 13:27:19 |
| Commit | Fix backend unit tests: update spec mocks and fix $Results variable collision |
| Project | C:\project\vLearn2 |

---

## User

can you run the run-tests.ps1 for backend and find the errors. If found plz fix automatically

## Assistant

Ran `.\cmds\run-tests.ps1 -Suite backend`. Two failures found and fixed:

**1. `prompt-builder.service.spec.ts`** — stale after our earlier refactor:
- Missing mocks for `ConfigService` and `PromptVarEntity` repository (added as dependencies)
- `buildGrammarPrompt` test referenced a method we removed
- `expect(prompt).toContain('ko')` — native language no longer embedded in prompt
- Fixed: added mocks for all three dependencies, rewrote tests to match current API (DB template fallback, prompt var resolution, /no_think flag)

**2. `cmds/run-tests.ps1`** — `$Results` (directory path) collided with `$results` (tracking hash) — PowerShell is case-insensitive, so `Out-File (Join-Path $Results ...)` used the hash object as the path string.
- Fixed: renamed directory variable to `$ResultsDir`

Result after fix: **8 passed, 0 failed** (e2e skipped — needs .env.test)

---

## Prompt

can you run the run-tests.ps1 for backend and find the errors. If found plz fix automatically
