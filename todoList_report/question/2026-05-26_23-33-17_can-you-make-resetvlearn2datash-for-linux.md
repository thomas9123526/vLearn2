# can you make reset_vlearn2_data.sh for linux

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-26T14:33:17.004Z

## User

can you make reset_vlearn2_data.sh for linux

## Assistant

Done — committed as `af79f58`, file is `100755` (executable bit set in git, so a fresh clone on Linux will be runnable directly).

## How it mirrors the `.bat`

| `.bat` step | `.sh` equivalent |
|---|---|
| `set DB_USER`, `DB_NAME` | `DB_USER="${DB_USER:-postgres}"` (env-overridable) |
| `where /q psql` | `command -v psql` |
| Walk `C:\Program Files\PostgreSQL\*` | Walk `/usr/pgsql-*/bin` and `/usr/local/pgsql/bin` (RHEL PGDG / source-install paths) |
| `set /p CONFIRM=…` + `if not "==YES"` | `read -r -p` + `if [[ … != "YES" ]]` |
| `"%PSQL%" -U %DB_USER% -d %DB_NAME% -f "%SCRIPT%"` | `"$PSQL" -U "$DB_USER" -d "$DB_NAME" -f "$SQL_FILE"` |

`set -euo pipefail` at the top means it bails on any error (mirrors the `errorlevel 1` check in the bat).

## Usage on Linux

```bash
# After cloning fresh:
./datamanage/reset_vlearn2_data.sh

# Override DB name/user via env:
DB_NAME=vlearn2_dev ./datamanage/reset_vlearn2_data.sh

# Debian/Ubuntu peer-auth (most common case):
sudo -u postgres ./datamanage/reset_vlearn2_data.sh

# With password via .pgpass (or PGPASSWORD inline):
PGPASSWORD=secret ./datamanage/reset_vlearn2_data.sh
```

The header comment in the script spells out the peer-auth situation — that's the #1 thing that trips people up porting Windows Postgres scripts to Linux.
