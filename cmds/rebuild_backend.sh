#!/usr/bin/env bash
# Rebuild the NestJS backend (dist/) and restart it under PM2.
# Run after pulling new backend source, or whenever /vfls/* returns 502 /
# nest fails to boot.
#
# Usage:  bash /root/vfls/vLearn2/cmds/rebuild_backend.sh
#
# Notes:
#   - The PM2 entry currently runs `npm run start:dev` (ts-node watch mode),
#     so the build step here only refreshes dist/ — useful if you ever
#     switch the entry to `npm run start:prod` (which serves dist/main).
#   - First-boot probe waits up to 60s because nest start --watch is slow
#     to compile under ts-node.

set -euo pipefail

BACKEND_DIR="/root/vfls/vLearn2/backend"
PM2_NAME="vfls-backend"
PORT="5100"
READY_PATH="/api/docs-json"   # cheap GET that's only 200 once Nest finished bootstrap
NGINX_PATH="/vfls/docs-json"
BOOT_TIMEOUT_SECS=60

cd "$BACKEND_DIR"

echo "──── building ${PM2_NAME} (${BACKEND_DIR}) ────"
npm run build

echo ""
echo "──── restarting PM2 process ────"
pm2 flush "$PM2_NAME" >/dev/null 2>&1 || true
pm2 restart "$PM2_NAME" --update-env

echo ""
echo "──── waiting for :${PORT}${READY_PATH} ────"
for i in $(seq 1 "$BOOT_TIMEOUT_SECS"); do
  code=$(curl -sS -o /dev/null --max-time 1 -w "%{http_code}" \
    "http://127.0.0.1:${PORT}${READY_PATH}" 2>/dev/null || echo "000")
  if [ "$code" = "200" ]; then
    echo "ready at t+${i}s — HTTP ${code}"
    nginx_code=$(curl -sS -o /dev/null -w "%{http_code}" \
      "http://127.0.0.1${NGINX_PATH}" 2>/dev/null || echo "000")
    echo "through nginx: GET ${NGINX_PATH}  → HTTP ${nginx_code}"
    exit 0
  fi
  sleep 1
done

echo "FAILED: ${PM2_NAME} did not respond on :${PORT}${READY_PATH} within ${BOOT_TIMEOUT_SECS}s" >&2
echo "Check: pm2 logs ${PM2_NAME} --lines 40 --nostream --err" >&2
exit 1
