# Add `backend/stop_start_service.bat`

## What this task did

Added [backend/stop_start_service.bat](../backend/stop_start_service.bat) — a one-shot Windows script that kills any process currently listening on the backend port, waits a beat for the socket to release, then runs `npm run start:dev`.

This fills a workflow gap: the existing [cmds/start_debug.bat](../cmds/start_debug.bat) and [cmds/start_service.bat](../cmds/start_service.bat) just start the backend — if the old `nest start --watch` is still wedged on port 3000 (which happens when ctrl-C doesn't fully tear down the child node process), the start scripts crash with `EADDRINUSE` and the user has to find + kill the PID manually before retrying.

### How it works

1. `pushd "%~dp0"` enters the script's own folder (backend/).
2. Defaults `PORT=3000`; respects an existing `PORT` env var (e.g. `set PORT=4000 && stop_start_service.bat`).
3. Installs `node_modules` if missing, warns if `.env` is missing — same pattern as the other backend scripts.
4. Calls PowerShell's `Get-NetTCPConnection -LocalPort %PORT% -State Listen` to find owners of the port, then `Stop-Process -Id ... -Force` on each.
5. `timeout /t 1` to let the OS release the socket before the new server tries to bind.
6. `call npm run start:dev` — same dev/watch entry as before.

## Decisions / call-outs

- **Used `Get-NetTCPConnection` instead of parsing `netstat`.** Exact port match — port 3000 will NOT accidentally kill a process listening on 30000, which is a real risk with `findstr ":3000"`. Available on Windows 8+, which is fine for this project.
- **Dev mode, not prod.** Conversation context just walked through `npm run start:dev` as the everyday command. The "stop and restart" workflow is iterative development, not a service redeploy. If someone wants the prod variant they can swap the last `call npm run start:dev` line for `start_service.bat`'s body.
- **Placed in `backend/` (per user request), not `cmds/`.** The existing convention in `cmds/` uses `pushd "%~dp0..\backend"` because those scripts sit one level up; the in-folder location means `pushd "%~dp0"` is enough.
- **Added the 1-second `timeout`.** Without it, Windows occasionally still has the socket in TIME_WAIT when `nest start` tries to bind, producing a different `EADDRINUSE` flavor. A short pause is much simpler than `SO_REUSEADDR` plumbing in the Nest bootstrap.
- **Did NOT touch `cmds/start_debug.bat`.** It's the canonical "just start it" script and people may want it to fail loudly if the port is already taken (signals an orphaned process worth investigating). The new script is the explicit "I know, just stomp on it and restart" variant.

## How to verify it works

1. Open one terminal, run `backend\stop_start_service.bat`. Output should include `(nothing to stop)` on first run.
2. Wait for `Nest application successfully started`.
3. Open a second terminal and re-run `backend\stop_start_service.bat`. This time it should print `killing PID <n> (node)` and then start cleanly.
4. Hit `curl http://localhost:3000/health` from a third terminal to confirm the new instance is serving.

## User prompt (verbatim)

> can u make backend\stop_start_service.bat to stop backend service already running and start backend service again?
