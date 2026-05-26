# how to execute sql file on pgAdmin 4

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-26T09:44:21.991Z

## User

how to execute sql file on pgAdmin 4

## Assistant

Three quick ways in pgAdmin 4, easiest first:

## 1. Query Tool → Open File (the usual)

1. In the left tree, **right-click the target database** → **Query Tool** (or pick the DB then `Tools → Query Tool`).
2. In the Query Tool window, click the **folder/Open File icon** in the toolbar (`Open File` — shortcut `Ctrl + O`).
3. Pick `vlearn_license_schema.sql` → the contents load into the editor.
4. Run it with the **▶ Execute** button (or `F5`).

Watch the **Messages** tab at the bottom for `CREATE TABLE` lines and any `ERROR`s. If something fails partway, nothing in that statement is committed — fix it and re-run.

## 2. Restore (if it's a `pg_dump` file, not a hand-written schema)

`Tools → Restore` on the database, then point at the `.sql`. Only use this if the file was produced by `pg_dump`; hand-written schemas should use the Query Tool path above.

## 3. psql one-liner (if pgAdmin balks)

From PowerShell, with PostgreSQL's `bin` on PATH:

```powershell
psql -h localhost -U <user> -d <database> -f "C:\project\vLearn2\backend\src\database\vlearn_license_schema.sql"
```

It'll prompt for the password. Add `-1` to wrap the whole file in a single transaction (good for schema scripts — all-or-nothing).

## Couple of things worth checking before running

- **Connect to the right database first.** Schemas like `vlearn_license_schema.sql` are usually meant for the dedicated `vLearnLicense` DB (per the plan), not the main app DB. Create it first if it doesn't exist: right-click `Databases` → `Create → Database…` → name `vLearnLicense` → save.
- **Search path.** If the script uses an explicit schema (e.g. `CREATE TABLE license.verify_log`), make sure that schema exists or that the script creates it.
- **Idempotency.** Re-running an already-loaded schema will throw "relation already exists" unless the script uses `CREATE TABLE IF NOT EXISTS` / `CREATE OR REPLACE`. If you want to re-run cleanly, either edit the script or `DROP DATABASE` and recreate.
