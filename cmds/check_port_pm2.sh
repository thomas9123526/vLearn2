#!/usr/bin/env bash
# Show which TCP port each PM2 service is listening on.
#
# PM2 wraps each app with `npm` → `sh` → `node`, so the listening socket
# belongs to a grandchild of the PID PM2 reports. We map each PM2 process
# to its descendant node PIDs, then look those PIDs up in `ss -tlnp`.

set -euo pipefail

command -v pm2 >/dev/null || { echo "pm2 not found in PATH" >&2; exit 1; }
command -v ss  >/dev/null || { echo "ss (iproute2) not found in PATH" >&2; exit 1; }

# Collect all listening TCP sockets once: "pid<TAB>addr:port"
listeners=$(
  ss -H -tlnp 2>/dev/null \
  | awk '{
      addr=$4; users=$NF;
      while (match(users, /pid=[0-9]+/)) {
        pid=substr(users, RSTART+4, RLENGTH-4);
        print pid "\t" addr;
        users=substr(users, RSTART+RLENGTH);
      }
    }'
)

# Recursively collect a PID and all its descendants.
descendants() {
  local pid=$1
  echo "$pid"
  for child in $(pgrep -P "$pid" 2>/dev/null); do
    descendants "$child"
  done
}

printf '%-16s %-9s %-8s %-22s %s\n' NAME STATUS PID PORT CWD
printf '%-16s %-9s %-8s %-22s %s\n' ---- ------ --- ---- ---

pm2 jlist 2>/dev/null \
| python3 -c '
import json, sys
for p in json.load(sys.stdin):
    env = p.get("pm2_env", {})
    print("\t".join([
        p.get("name", ""),
        env.get("status", ""),
        str(p.get("pid") or 0),
        env.get("pm_cwd", ""),
    ]))
' \
| while IFS=$'\t' read -r name status pid cwd; do
    ports="-"
    if [[ "$pid" != "0" && -n "$pid" ]]; then
      pids=$(descendants "$pid" | sort -u)
      matched=$(
        while read -r p; do
          [[ -z "$p" ]] && continue
          echo "$listeners" | awk -v want="$p" '$1==want {print $2}'
        done <<< "$pids" | sort -u | paste -sd, -
      )
      [[ -n "$matched" ]] && ports="$matched"
    fi
    printf '%-16s %-9s %-8s %-22s %s\n' "$name" "$status" "$pid" "$ports" "$cwd"
done
