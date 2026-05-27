# Add granular build + start scripts (Flutter compile-only, backend prod/debug/release)

## What this task did

Added 9 batch scripts under [`cmds/`](../cmds/) splitting build (compile-only) from start (launch interactively):

**Flutter:**
- [`build_android.bat`](../cmds/build_android.bat) — `flutter build apk --debug` (compile, no launch). Produces `app-debug.apk`
- [`build_windows.bat`](../cmds/build_windows.bat) — `flutter build windows --debug` (compile, no launch)
- [`start_debug_android.bat`](../cmds/start_debug_android.bat) — `flutter run --debug` (launch with hot reload)
- [`start_debug_windows.bat`](../cmds/start_debug_windows.bat) — `flutter run -d windows --debug`

**Backend:**
- [`start_service.bat`](../cmds/start_service.bat) — `npm run start:prod` (assumes pre-built `dist/`); sets `NODE_ENV=production`; errors out clearly if `dist/main.js` missing
- [`start_debug.bat`](../cmds/start_debug.bat) — `npm run start:debug` (`nest start --debug --watch`); Node inspector on :9229; auto-installs deps if `node_modules/` missing
- [`build_backend.bat`](../cmds/build_backend.bat) — `npm run build` (one-shot `nest build` → `dist/`); auto-installs deps
- [`build_backend_debug.bat`](../cmds/build_backend_debug.bat) — verify-compile then launch debug+watch (2-step: build → start:debug)
- [`build_backend_release.bat`](../cmds/build_backend_release.bat) — production deploy build: clean `dist/`, `npm ci` (lockfile-strict), `nest build`. Comments document the post-build slim-down (`npm prune --omit=dev`) and how to launch via `start_service.bat`

All 9 share the same patterns from the prior set:
- `pushd "%~dp0..\<project>"` so they work from any cwd
- `errorlevel` checks with clear failure messages
- `pause` on terminal scripts so double-click users see results
- API base URL configurable via `--dart-define` for the Flutter ones

## Conversation summary

**User** asked (one message, 9 scripts in a flat list):

- Flutter: `build_android.bat` + `build_windows.bat` (both build-only), `start_debug_android.bat` + `start_debug_windows.bat` (both launch in debug)
- Backend: `start_service.bat` (prod), `start_debug.bat` (debug), `build_backend.bat` (compile), `build_backend_debug.bat` (compile + start debug), `build_backend_release.bat` (production release build)

This is essentially a refactor / expansion of the previous 4 batch scripts (`build_debug_*` and `build_release_*` from commit `790a54f`). The new naming convention is clearer:
- `build_*` = compile, no launch
- `start_*` = launch (debug or service)
- `build_*_release.bat` = production-grade compile

## Decisions / call-outs

- **Did not delete the previous `build_debug_*.bat` scripts** (which did build+run combined). They're still valid one-shot dev shortcuts. The user can decide whether to keep them or remove. New scripts coexist.
- **`build_backend_debug.bat`** runs `npm run build` first even though `npm run start:debug` doesn't strictly need it. Interpreted "build backend service AND start debug" as the user wanting an explicit compile-check before launching. Otherwise the script would just be a wrapper around `start_debug.bat`.
- **`start_service.bat` requires a prior build.** Errors out cleanly if `dist/main.js` is missing rather than silently failing. Tells the user which build script to run first.
- **`build_backend_release.bat` uses `npm ci`** (not `npm install`) for reproducible builds from `package-lock.json`. Cleans `dist/` first to avoid stale artifacts.
- **Both backend scripts that start the server** warn if `backend\.env` is missing rather than failing cryptically.
- **`NODE_ENV=production` only set in `start_service.bat`.** The debug/dev scripts intentionally leave it unset (defaults to development) so dev-only behaviors (verbose logging, etc.) stay on.
- **Inspector port 9229** is the Node default. Documented in `start_debug.bat` and `build_backend_debug.bat` for VS Code / Chrome DevTools attach.
- **No `start_service_release.bat`** — `start_service.bat` already runs production mode. A separate release-launch script would just duplicate it.

## User prompt (verbatim)

> give me cmds/build_android.bat which build flutter android.
>
> give me cmds/build_windows.bat which build flutter windows.
>
> give me cmds/start_debug_android.bat which start android debug.
>
> give me cmds/start_debug_windows.bat which start windows debug.
>
> backend.
>
> give me cmds/start_service.bat which start backend service.
>
> give me cmds/start_debug.bat which start debug for backend service.
>
> give me cmds/build_backend.bat which build backend.
>
> give me cmds/build_backend_debug.bat which build backend service and start debug.
>
> give me cmds/build_backend_release.bat which build release version of backend api.
