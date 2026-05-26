#!/usr/bin/env bash
# Linux counterpart of reset_vlearn2_data.bat — runs reset_vlearn2_data.sql
# against the local Postgres `vlearn2` database. Wipes user/session data
# while keeping reference content (personas, scenarios, achievements, …).
#
# Usage:
#   ./reset_vlearn2_data.sh
#
# Override defaults via env vars, e.g.:
#   DB_USER=postgres DB_NAME=vlearn2 ./reset_vlearn2_data.sh
#
# On Debian/Ubuntu, postgres uses peer auth by default — if you aren't
# logged in as the `postgres` OS user, run this with `sudo -u postgres`,
# or set PGPASSWORD / ~/.pgpass for TCP-auth.

set -euo pipefail

DB_USER="${DB_USER:-myuser}"
DB_NAME="${DB_NAME:-vlearn2}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_FILE="$SCRIPT_DIR/reset_vlearn2_data.sql"

if [[ ! -f "$SQL_FILE" ]]; then
  echo "ERROR: SQL file not found: $SQL_FILE" >&2
  exit 1
fi

# ── Locate psql ────────────────────────────────────────────────────────────
# PATH first, then the usual non-PATH install locations (RHEL/PGDG packages
# install to /usr/pgsql-<version>/bin; source builds default to /usr/local).
PSQL=""
if command -v psql >/dev/null 2>&1; then
  PSQL="$(command -v psql)"
else
  for cand in /usr/pgsql-*/bin/psql /usr/local/pgsql/bin/psql; do
    if [[ -x "$cand" ]]; then
      PSQL="$cand"
      break
    fi
  done
fi

if [[ -z "$PSQL" ]]; then
  cat >&2 <<'EOF'
ERROR: psql not found.
       Install the PostgreSQL client and try again:
         Debian/Ubuntu:  sudo apt install postgresql-client
         RHEL/Fedora:    sudo dnf install postgresql
         Arch:           sudo pacman -S postgresql-libs
       Or add psql to PATH.
EOF
  exit 1
fi

echo "Using psql: $PSQL"

# ── Confirm ────────────────────────────────────────────────────────────────
cat <<EOF

 WARNING: This will DELETE all user/session data in "$DB_NAME".
 Reference data (personas, scenarios, achievements, etc.) is kept.

EOF

read -r -p "  Type YES to continue: " CONFIRM
if [[ "$CONFIRM" != "YES" ]]; then
  echo "Aborted."
  exit 1
fi

# ── Run ────────────────────────────────────────────────────────────────────
echo
"$PSQL" -U "$DB_USER" -d "$DB_NAME" -f "$SQL_FILE"
echo
echo "Done."
