#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
#  vLearn2 — Start backend + admin panel, one after the other (Linux/macOS)
#
#  Usage:   ./start_service_linux.sh [backendPort] [adminPort] [hot]
#  Default: backendPort=4101  adminPort=5101  hot=<off>
#
#  The 3rd argument is presence-only — pass anything (e.g. "hot", "1") to
#  enable hot reload. Omit to run in cold/production-ish mode.
#
#    HOT  (3rd arg given): backend `npm run start:dev` (nest --watch),
#                          admin   `next dev -p PORT`        (Next.js HMR)
#    COLD (default):       backend `npm run start`  (nest start, no watch),
#                          admin   `next build` then `next start -p PORT`
#                          ── cold admin rebuilds .next/ each launch, so
#                             expect ~30s before it's reachable.
#
#  For each port: scan with `lsof` (or `ss` fallback) and kill the listener,
#  then start the service in the background under `nohup`. Logs land in
#  <repo>/logs/{backend,admin}.log; PIDs in <repo>/logs/{backend,admin}.pid.
# ─────────────────────────────────────────────────────────────────────────
set -euo pipefail

BACKEND_PORT="${1:-4101}"
ADMIN_PORT="${2:-5101}"
HOT="${3:-}"

if [[ -n "$HOT" ]]; then
  MODE="hot"
  BACKEND_CMD=(npm run start:dev)
  ADMIN_CMD=(sh -c "npx next dev -p ${ADMIN_PORT}")
else
  MODE="cold"
  BACKEND_CMD=(npm run start)
  # Build first, then start. `set -e` inside the spawned shell would abort
  # admin start on build failure — we want that behaviour, so use `&&`.
  ADMIN_CMD=(sh -c "npx next build && npx next start -p ${ADMIN_PORT}")
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="$ROOT/backend"
ADMIN_DIR="$ROOT/admin_panel"
LOG_DIR="$ROOT/logs"

[[ -d "$BACKEND_DIR" ]] || { echo "[ERROR] backend folder not found: $BACKEND_DIR" >&2; exit 1; }
[[ -d "$ADMIN_DIR"   ]] || { echo "[ERROR] admin_panel folder not found: $ADMIN_DIR" >&2; exit 1; }
mkdir -p "$LOG_DIR"

kill_port() {
  local port="$1"
  local pids=""
  if command -v lsof >/dev/null 2>&1; then
    pids="$(lsof -ti "tcp:${port}" -sTCP:LISTEN 2>/dev/null || true)"
  elif command -v ss >/dev/null 2>&1; then
    pids="$(ss -ltnp "( sport = :${port} )" 2>/dev/null \
      | grep -oE 'pid=[0-9]+' | cut -d= -f2 | sort -u || true)"
  else
    echo "  [WARN] neither lsof nor ss available; cannot scan port ${port}" >&2
    return 0
  fi

  if [[ -z "$pids" ]]; then
    echo "  (nothing on port ${port})"
    return 0
  fi
  echo "  killing PIDs on port ${port}: ${pids}"
  # shellcheck disable=SC2086
  kill -9 ${pids} 2>/dev/null || true
  sleep 1
}

echo
echo "=== vLearn2 service launcher (mode: ${MODE}) ==="
echo "Backend:   http://localhost:${BACKEND_PORT}/api  (Swagger: /api/docs)"
echo "Admin:     http://localhost:${ADMIN_PORT}/vAdmin/"
echo "Logs:      ${LOG_DIR}/{backend,admin}.log"
if [[ "$MODE" == "cold" ]]; then
  echo "NOTE: cold mode runs 'next build' first — expect ~30s before reachable."
fi
echo

# ── Backend ─────────────────────────────────────────────────────────────
echo "--- Backend on port ${BACKEND_PORT} (${BACKEND_CMD[*]}) ---"
kill_port "$BACKEND_PORT"
echo "Launching backend → ${LOG_DIR}/backend.log"
(
  cd "$BACKEND_DIR"
  PORT="$BACKEND_PORT" nohup "${BACKEND_CMD[@]}" \
    >"$LOG_DIR/backend.log" 2>&1 &
  echo "$!" >"$LOG_DIR/backend.pid"
)
BACKEND_PID="$(cat "$LOG_DIR/backend.pid")"
echo "  backend pid ${BACKEND_PID}"

# Brief wait so it grabs the port before we proceed.
sleep 2

# ── Admin panel ─────────────────────────────────────────────────────────
echo
echo "--- Admin panel on port ${ADMIN_PORT} (${ADMIN_CMD[*]}) ---"
kill_port "$ADMIN_PORT"
echo "Launching admin panel → ${LOG_DIR}/admin.log"
(
  cd "$ADMIN_DIR"
  nohup "${ADMIN_CMD[@]}" \
    >"$LOG_DIR/admin.log" 2>&1 &
  echo "$!" >"$LOG_DIR/admin.pid"
)
ADMIN_PID="$(cat "$LOG_DIR/admin.pid")"
echo "  admin pid ${ADMIN_PID}"

echo
echo "Both services launched (${MODE} mode)."
echo "  Stop:  kill ${BACKEND_PID} ${ADMIN_PID}"
echo "  Tail:  tail -f ${LOG_DIR}/backend.log ${LOG_DIR}/admin.log"
