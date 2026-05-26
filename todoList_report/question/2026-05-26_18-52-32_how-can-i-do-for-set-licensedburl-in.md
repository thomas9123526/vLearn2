# how can i do for "Set LICENSE_DB_URL in backend .env"

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-26T09:52:32.700Z

## User

how can i do for "Set LICENSE_DB_URL in backend .env"

## Assistant

Your main DB uses individual variables (`DB_HOST`, `DB_USER`, etc.). `LICENSE_DB_URL` is a single connection string for the separate `vLearnLicense` database. Add this line to [backend/.env](backend/.env), using the same credentials:

```
# ─── License DB (vLearnLicense) ─────────────────────────────
LICENSE_DB_URL=postgresql://postgres:1234567890@localhost:5432/vLearnLicense
```

The format is:
```
postgresql://<DB_USER>:<DB_PASSWORD>@<DB_HOST>:<DB_PORT>/<database-name>
```

Matching your existing values:
- user: `postgres`
- password: `1234567890`
- host: `localhost`
- port: `5432`
- database name: `vLearnLicense` (the one you'll create with the schema SQL)

Do you want me to add it to the file now?
