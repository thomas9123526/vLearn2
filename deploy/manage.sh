#!/usr/bin/env bash
# =============================================================================
# Virtual Foreign Language System — Management script
#
# Usage:
#   bash manage.sh <command> [args]
#
# Commands:
#   status              — show container status & health
#   start               — start all services
#   stop                — stop all services
#   restart [service]   — restart all or a single service
#   logs [service]      — tail logs (all or one service)
#   update              — git pull + rebuild + restart
#   backup              — dump PostgreSQL to backups/
#   restore <file>      — restore a database dump
#   shell <service>     — open a shell in a running container
# =============================================================================
set -euo pipefail

DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$DEPLOY_DIR")"
BACKUP_DIR="$DEPLOY_DIR/backups"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()  { echo -e "${CYAN}[INFO]${RESET}  $*"; }
ok()    { echo -e "${GREEN}[ OK ]${RESET}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
die()   { echo -e "${RED}[FAIL]${RESET}  $*" >&2; exit 1; }

cd "$DEPLOY_DIR"

# Load .env for DB credentials
[[ -f "$DEPLOY_DIR/.env" ]] && set -o allexport && source "$DEPLOY_DIR/.env" && set +o allexport

COMMAND="${1:-help}"

case "$COMMAND" in

  # ── status ────────────────────────────────────────────────────────────────
  status)
    echo -e "\n${BOLD}Container status:${RESET}"
    docker compose ps
    echo -e "\n${BOLD}Health checks:${RESET}"
    for svc in backend ai-mock postgres nginx; do
      STATE=$(docker inspect --format='{{.State.Health.Status}}' "vlfls-${svc}" 2>/dev/null || echo "not running")
      case "$STATE" in
        healthy)   echo -e "  ${GREEN}●${RESET} ${svc}: ${STATE}" ;;
        unhealthy) echo -e "  ${RED}●${RESET} ${svc}: ${STATE}" ;;
        *)         echo -e "  ${YELLOW}●${RESET} ${svc}: ${STATE}" ;;
      esac
    done
    echo
    ;;

  # ── start ─────────────────────────────────────────────────────────────────
  start)
    info "Starting all services..."
    docker compose up -d
    ok "All services started."
    ;;

  # ── stop ──────────────────────────────────────────────────────────────────
  stop)
    info "Stopping all services..."
    docker compose down
    ok "All services stopped."
    ;;

  # ── restart ───────────────────────────────────────────────────────────────
  restart)
    SERVICE="${2:-}"
    if [[ -n "$SERVICE" ]]; then
      info "Restarting ${SERVICE}..."
      docker compose restart "$SERVICE"
      ok "${SERVICE} restarted."
    else
      info "Restarting all services..."
      docker compose restart
      ok "All services restarted."
    fi
    ;;

  # ── logs ──────────────────────────────────────────────────────────────────
  logs)
    SERVICE="${2:-}"
    if [[ -n "$SERVICE" ]]; then
      docker compose logs -f --tail=100 "$SERVICE"
    else
      docker compose logs -f --tail=50
    fi
    ;;

  # ── update ────────────────────────────────────────────────────────────────
  update)
    info "Pulling latest code..."
    cd "$ROOT_DIR"
    git pull --ff-only

    info "Rebuilding and restarting containers..."
    cd "$DEPLOY_DIR"
    docker compose up -d --build --remove-orphans

    ok "Update complete."
    bash "$0" status
    ;;

  # ── backup ────────────────────────────────────────────────────────────────
  backup)
    mkdir -p "$BACKUP_DIR"
    STAMP=$(date +"%Y%m%d_%H%M%S")
    OUT="$BACKUP_DIR/vlearn2_${STAMP}.sql.gz"
    info "Dumping database to ${OUT}..."
    docker compose exec -T postgres \
      pg_dump -U "${DB_USER:-vlearn2}" "${DB_NAME:-vlearn2}" \
      | gzip > "$OUT"
    ok "Backup saved: $OUT"
    ls -lh "$BACKUP_DIR" | tail -5
    ;;

  # ── restore ───────────────────────────────────────────────────────────────
  restore)
    FILE="${2:-}"
    [[ -f "$FILE" ]] || die "Usage: bash manage.sh restore <path/to/dump.sql.gz>"
    warn "This will OVERWRITE the current database. Are you sure? (type yes)"
    read -r CONFIRM
    [[ "$CONFIRM" == "yes" ]] || die "Aborted."
    info "Restoring from $FILE..."
    gunzip -c "$FILE" | docker compose exec -T postgres \
      psql -U "${DB_USER:-vlearn2}" "${DB_NAME:-vlearn2}"
    ok "Restore complete."
    ;;

  # ── shell ─────────────────────────────────────────────────────────────────
  shell)
    SERVICE="${2:-backend}"
    info "Opening shell in ${SERVICE}..."
    docker compose exec "$SERVICE" sh
    ;;

  # ── help / default ────────────────────────────────────────────────────────
  help|*)
    echo -e "
${BOLD}Virtual Foreign Language System — manage.sh${RESET}

Usage: bash manage.sh <command> [args]

Commands:
  ${CYAN}status${RESET}               Show container status and health
  ${CYAN}start${RESET}                Start all services
  ${CYAN}stop${RESET}                 Stop all services
  ${CYAN}restart [service]${RESET}    Restart all or a single service
  ${CYAN}logs [service]${RESET}       Tail logs (Ctrl+C to exit)
  ${CYAN}update${RESET}               Git pull + rebuild + restart
  ${CYAN}backup${RESET}               Dump the database to backups/
  ${CYAN}restore <file>${RESET}       Restore a database dump
  ${CYAN}shell [service]${RESET}      Open a shell inside a container (default: backend)

Examples:
  bash manage.sh logs backend
  bash manage.sh restart ai-mock
  bash manage.sh backup
  bash manage.sh restore backups/vlearn2_20260604_120000.sql.gz
"
    ;;
esac
