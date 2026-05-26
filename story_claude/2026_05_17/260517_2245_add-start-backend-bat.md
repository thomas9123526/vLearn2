# Add `cmds/start_backend.bat`

## What this task did

Created [cmds/start_backend.bat](../cmds/start_backend.bat) — a single-purpose
launcher that starts the NestJS backend in dev mode (`npm run start:dev` =
watch + auto-restart on file change). Same convention as the existing
`cmds/build_backend.bat`:

- `pushd` into `backend/`
- run `npm install` once if `node_modules/` is missing
- warn if `backend/.env` doesn't exist
- print where the server will be reachable (`http://localhost:3000/api`,
  Swagger at `/api/docs`)
- exec `npm run start:dev`

## Conversation summary

- User: *"what is the commands to start backend service? just make bat file
  inside cmds folder and i will start service manually with bat file"*
- The user has trimmed `cmds/` down to just `build_admin.bat`,
  `build_backend.bat`, and `make_cmd.txt` — the various `start_debug_*`
  scripts I added earlier in the session are gone. So they want a fresh,
  minimal "start backend" script that they can double-click.
- I picked **dev mode** (`start:dev` with watch) rather than production
  mode (`node dist/main`) because the user is actively developing and dev
  mode handles the typical "edit code → see changes" loop without needing
  a separate build step first.

## Decisions / call-outs

- **Dev mode, not prod.** Watch mode means edits to backend `src/` files
  hot-restart the server automatically. The production runner
  (`npm run start:prod`) would require running `cmds\build_backend.bat`
  first every time. If you want a prod-mode variant, I'll add
  `start_backend_prod.bat` separately.
- **`.env` warning, not error.** If `backend/.env` is missing the script
  still tries to start — Nest will boot, then the first DB query fails
  with a clear connection error. That's more useful than the bat file
  silently refusing to launch.
- **Doesn't auto-start Postgres or LM Studio.** Those are external
  prerequisites; the script just calls them out in the header comment.
  Auto-starting feels presumptuous and easy to break.
- **No `pause` at the end.** A `pause` would hold the window open after
  Ctrl+C, but for a long-running server we want the window to stay open
  *while* the server runs and close when Ctrl+C kills it. That's the
  default behavior without `pause`.
- **Mirrors `build_backend.bat`'s style** for `node_modules` check,
  `pushd`/`popd`, errorlevel propagation — keeps the cmds/ folder
  visually consistent.

## How to verify

```powershell
cmds\start_backend.bat
```

Should print the banner, then NestJS boot logs, then
`vLearn2 backend listening on http://localhost:3000` and stay running.
Ctrl+C exits cleanly.

## User prompt (verbatim)

> what is the commands to start backend service? just make bat file inside
> cmds folder and i will start service manually with bat file
