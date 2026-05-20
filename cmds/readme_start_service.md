# `start_service_*` — backend + admin panel launchers

Two scripts in this folder start the vLearn2 NestJS backend **and** the
Next.js admin panel one after the other:

| File | Platform |
| --- | --- |
| [start_service_windows.bat](start_service_windows.bat) | Windows |
| [start_service_linux.sh](start_service_linux.sh) | Linux / macOS |

Both have the same CLI shape, defaults, and behaviour. The Windows version
launches each service in its own console window; the Linux version
backgrounds each one under `nohup` and writes to `<repo>/logs/*.log`.

---

## CLI

```
start_service_windows.bat [backendPort] [adminPort] [hot]
./start_service_linux.sh  [backendPort] [adminPort] [hot]
```

| Arg | Default | Meaning |
| --- | --- | --- |
| `backendPort` | `4101` | Port for the NestJS backend (`PORT=` env var). |
| `adminPort`   | `5101` | Port for the Next.js admin panel (`next … -p`). |
| `hot`         | *(off)* | **Presence-only.** Pass any value (`hot`, `1`, `true`) to enable hot reload. Omit for cold/production-ish mode. |

---

## Modes

| Mode | Backend command | Admin command | Reachable after |
| --- | --- | --- | --- |
| **HOT** (3rd arg given) | `npm run start:dev` (nest `--watch`) | `npx next dev -p N` (Next.js HMR) | seconds |
| **COLD** (default) | `npm run start` (no watch) | `npx next build && npx next start -p N` | **~30 s** while the admin build runs |

Edit `.ts` / `.tsx` files in HOT mode and the running process reloads
automatically. In COLD mode you'd kill and re-run the script (which
re-builds the admin panel) to pick up changes.

---

## What the script does for each port

1. **Scan and kill** anything listening on the port.
   * Windows: `Get-NetTCPConnection -LocalPort N -State Listen` (exact
     match — port `4101` does **not** also kill `41010`) → `Stop-Process
     -Force`.
   * Linux: `lsof -ti tcp:N -sTCP:LISTEN` (or `ss -ltnp` fallback) →
     `kill -9`.
2. Wait ~1 second so the OS releases the socket.
3. **Launch** the service:
   * Windows: `start "title" cmd /k "...; npm run …"` opens a fresh
     console window. The launcher exits; the service window keeps
     running until you Ctrl+C it.
   * Linux: `nohup … >logs/<name>.log 2>&1 &` runs the service in the
     background; PID written to `logs/<name>.pid`.

After both have been launched, the backend gets a 2-second head-start
before the admin panel begins (so it has its port before any admin code
tries to call it).

---

## Examples

```bat
:: Windows, defaults (cold, ports 4101 / 5101)
cmds\start_service_windows.bat

:: Windows, hot reload on defaults
cmds\start_service_windows.bat 4101 5101 hot

:: Windows, custom ports, hot reload
cmds\start_service_windows.bat 3000 4000 1
```

```sh
# Linux/macOS, defaults
./cmds/start_service_linux.sh

# Linux/macOS, hot reload on defaults
./cmds/start_service_linux.sh 4101 5101 hot

# Linux/macOS, custom ports, hot reload
./cmds/start_service_linux.sh 3000 4000 1
```

---

## URLs once running (defaults)

| | URL |
| --- | --- |
| Backend API | `http://localhost:4101/api` |
| Backend Swagger | `http://localhost:4101/api/docs` |
| Admin panel | `http://localhost:5101/vAdmin/` |

The admin panel has `basePath: '/vAdmin'` and `trailingSlash: true` in
[`admin_panel/next.config.mjs`](../admin_panel/next.config.mjs), so the
root URL is `…/vAdmin/` — **not** `/`. Browsing to `/` returns 404; that
is by design (it lets nginx mount the admin panel under `/vAdmin/` in
prod without rewrites).

---

## Stopping

* **Windows** — Ctrl+C inside each spawned console window, or just close
  the window. Re-running the launcher also kills whatever is on those
  ports first.
* **Linux/macOS** — `kill $(cat logs/backend.pid) $(cat logs/admin.pid)`.
  Or just re-run the script — its first step on each port is to kill
  whatever's there.

---

## Where the backend URL for the Flutter app comes from

Unrelated to these scripts but worth noting: the Flutter app reads its
backend URL from **`app_config.json` at runtime** (see
[`ConfigFileService`](../flutter_app/lib/core/config/app_config.dart)).
The Windows desktop build scripts
([`build_debug_windows.bat`](../flutter_app/build_debug_windows.bat),
[`build_release_windows.bat`](../flutter_app/build_release_windows.bat))
do **not** pass `--dart-define=API_BASE_URL=…`, so end users (and you)
can edit the JSON without a rebuild. The compile-time override still
exists in [`api_client.dart`](../flutter_app/lib/core/api/api_client.dart)
for CI use if you ever need it.

---

## Files

* [start_service_windows.bat](start_service_windows.bat)
* [start_service_linux.sh](start_service_linux.sh)
* Existing related helpers in this folder:
  [start_backend.bat](start_backend.bat),
  [start_admin.bat](start_admin.bat),
  [stop.txt](stop.txt) (PowerShell snippets for freeing a port).
