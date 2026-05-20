# 260520_1003 — Global QA pass: error-find and testpass across all three apps

## User prompt (verbatim)

> For from files 00-99 inside todoList\global folder, read it and do what they said.
> After you have done task, produce report what you have done and save as md format to "todoList_report\global\0520" folder.
> md filename can be xxx.md where xxx means the current todo file name.
> You are an expert fullstack developer
> Don't ask me anything. Go automatically without my choice or answer. You do it by yourself and by your desicion.
> You have many times. take it easy.
> Quality is important.

## Six todo files processed

```
todoList/global/70_backend_api_error_find
todoList/global/71_backend_api_testpass
todoList/global/80_android_error_find
todoList/global/81_android_testpass
todoList/global/90_admin_panel_error_find
todoList/global/91_admin_panel_testpass
```

Each one received its own report in
`todoList_report/global/0520/<name>.md`.

## What I did, by app

### Backend (NestJS) — tasks 70 / 71

* Installed missing `@types/*` packages (`bcrypt`, `passport-jwt`,
  `passport-local`, `passport`, `compression`) — these were the root cause
  of 22 ESLint "no-unsafe-*" errors.
* Removed dead casts and unused imports across
  `admin-scenarios.controller.ts`, `permissions/permission.guard.ts`,
  `auth/decorators/current-user.decorator.ts`,
  `ai/prompt-builder.service.ts`, `ai/providers/openai-compatible.provider.ts`,
  `conversations/conversations.service.ts`, `progress/progress.module.ts`,
  `guard/content-guard.service.ts`, `news/news.module.ts`.
* Replaced the default-scaffold `app.e2e-spec.ts` (which asserted `GET /`
  returns "Hello World!" and bootstrapped the full `AppModule` requiring a
  Postgres) with a small `/health` e2e that needs no DB.
* `npx tsc --noEmit` 0 / `npx nest build` 0 / `npx eslint` 0 errors / 6
  unit tests pass / 1 e2e test pass.

### Flutter app — tasks 80 / 81

* Real bug: `tutor_avatar.dart` had `AppConfig.logx('assets path', asset!)`
  where `asset` is nullable; the force-unwrap would have crashed the avatar
  for personas without a Rive asset, and made the downstream `asset != null`
  fallback dead code. Removed `!`, use `?? '(none)'` for the log line.
* Real bug: `model_registry.dart`'s `resolveModelRoot()` returned the
  override directly while the production branch appended `/models`. The
  test seam therefore did not represent production. Made both branches
  append `/models` — 5 failing tests became 10 passing.
* Style cleanup across 11 files (multi-underscore parameter lists for Dart
  3, redundant default args, duplicate `package:flutter/foundation.dart`
  import, `let → const`, etc.). `flutter analyze` from 24 issues → 0.

### Admin panel (Next.js) — tasks 90 / 91

* `tsc --noEmit` / `next lint` / `next build` — all clean; no defects to
  fix.
* No tests existed; added a minimal Jest + ts-jest harness and three test
  files for the pure-logic modules (`cn`, `flag-catalog`, env zod schema)
  totalling 15 cases, all passing.

## Files touched

Modified: 23
Added: 4 (jest.config, 3 test files)
Plus the 6 task reports in `todoList_report/global/0520/`.
