#!/usr/bin/env bash
# Rebuild the admin_panel Next.js production bundle and restart it under PM2.
# Run after pulling new admin_panel source, or whenever /vAdmin/ returns 502
# with "Could not find a production build" in `pm2 logs vfls-admin --err`.
#
# Usage:  bash /root/vfls/vLearn2/cmds/rebuild_admin.sh

set -euo pipefail

ADMIN_DIR="/root/vfls/vLearn2/admin_panel"
PM2_NAME="vfls-admin"
PORT="4100"

cd "$ADMIN_DIR"

echo "──── building ${PM2_NAME} (${ADMIN_DIR}) ────"
npm run build

echo ""
echo "──── restarting PM2 process ────"
pm2 flush "$PM2_NAME" >/dev/null 2>&1 || true
pm2 restart "$PM2_NAME" --update-env

echo ""
echo "──── waiting for :${PORT} to accept requests ────"
for i in $(seq 1 30); do
  code=$(curl -sS -o /dev/null --max-time 1 -w "%{http_code}" \
    "http://127.0.0.1:${PORT}/vAdmin/" 2>/dev/null || echo "000")
  if [ "$code" = "200" ]; then
    echo "ready at t+${i}s — HTTP ${code}"
    nginx_code=$(curl -sS -o /dev/null -w "%{http_code}" \
      "http://127.0.0.1/vAdmin/" 2>/dev/null || echo "000")
    echo "through nginx: GET /vAdmin/  → HTTP ${nginx_code}"
    exit 0
  fi
  sleep 1
done

echo "FAILED: ${PM2_NAME} did not respond on :${PORT} within 30s" >&2
echo "Check: pm2 logs ${PM2_NAME} --lines 40 --nostream --err" >&2
exit 1
