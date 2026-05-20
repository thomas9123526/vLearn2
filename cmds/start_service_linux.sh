#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
#  vLearn2 — Start backend + admin panel, one after the other (Linux/macOS)
#
#  Usage:   ./start_service_linux.sh [backendPort] [adminPort]
#  Default: backendPort=4101  adminPort=5101
#
#  For each port:
#    1) scan with `lsof` (or `ss` as fallback) and kill the listener,
#    2) launch the service in the background under `nohup` so this
#       script can move on to the next one.
#
#  Logs land in <repo>/logs/{backend,admin}.log. PIDs are printed at the
#  end so you can `kill <pid>` later.
# ─────────────────────────────────────────────────────────────────────────
set -euo pipefail

BACKEND_PORT="${1:-4101}"
ADMIN_PORT="${2:-5101}"

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
    # Parse `users:(("node",pid=12345,fd=20))` out of `ss -ltnp`.
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
echo "=== vLearn2 service launcher ==="
echo "Backend:   http://localhost:${BACKEND_PORT}/api  (Swagger: /api/docs)"
echo "Admin:     http://localhost:${ADMIN_PORT}/vAdmin/"
echo "Logs:      ${LOG_DIR}/{backend,admin}.log"
echo

# ── Backend ─────────────────────────────────────────────────────────────
echo "--- Backend on port ${BACKEND_PORT} ---"
kill_port "$BACKEND_PORT"
echo "Launching backend (PORT=${BACKEND_PORT}) → ${LOG_DIR}/backend.log"
(
  cd "$BACKEND_DIR"
  PORT="$BACKEND_PORT" nohup npm run start:dev \
    >"$LOG_DIR/backend.log" 2>&1 &
  echo "$!" >"$LOG_DIR/backend.pid"
)
BACKEND_PID="$(cat "$LOG_DIR/backend.pid")"
echo "  backend pid ${BACKEND_PID}"

# Brief wait so it grabs the port before we proceed.
sleep 2

# ── Admin panel ─────────────────────────────────────────────────────────
echo
echo "--- Admin panel on port ${ADMIN_PORT} ---"
kill_port "$ADMIN_PORT"
echo "Launching admin panel (-p ${ADMIN_PORT}) → ${LOG_DIR}/admin.log"
(
  cd "$ADMIN_DIR"
  nohup npx next dev -p "$ADMIN_PORT" \
    >"$LOG_DIR/admin.log" 2>&1 &
  echo "$!" >"$LOG_DIR/admin.pid"
)
ADMIN_PID="$(cat "$LOG_DIR/admin.pid")"
echo "  admin pid ${ADMIN_PID}"

echo
echo "Both services launched."
echo "  Stop:  kill ${BACKEND_PID} ${ADMIN_PID}"
echo "  Tail:  tail -f ${LOG_DIR}/backend.log ${LOG_DIR}/admin.log"
