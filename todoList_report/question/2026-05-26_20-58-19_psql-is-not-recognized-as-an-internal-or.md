# 'psql' is not recognized as an internal or external command, operable program or

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-26T11:58:19.076Z

## User

'psql' is not recognized as an internal or external command,
operable program or batch file.

## Assistant

Found it — PostgreSQL 16 is at `C:\Program Files\PostgreSQL\16\bin\psql.exe` but the bin folder isn't in PATH. I'll update the bat to find it automatically.

## Assistant

Updated. The bat now auto-finds psql at `C:\Program Files\PostgreSQL\16\bin\psql.exe` without needing it in PATH. Try running [reset_vlearn2_data.bat](datamanage/reset_vlearn2_data.bat) again.

If it prompts for a password, set `PGPASSWORD=1234567890` before running, or create a `%APPDATA%\postgresql\pgpass.conf` file — but on a local dev machine it usually skips the password for the `postgres` user if `pg_hba.conf` uses `trust` or `md5` with a stored credential.
