# Username or password is not correct

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-20T19:04:40.150Z

## User

Username or password is not correct

## Assistant

401 means the backend reached the DB and rejected the credentials. From [`auth.service.ts:72-99`](backend/src/auth/auth.service.ts#L72-L99), that narrows it to exactly two paths:

1. `findOne({ where: { cid_username: 'sym1991123' } })` returns **nothing** → no user with that *exact* `cid_username` (Postgres `varchar` is case-sensitive, so `Sym1991123` ≠ `sym1991123`).
2. `bcrypt.compare('aaAA11!!', stored_hash)` returns **false** → the row exists but the password hash doesn't match what you typed.

**Run this one query to pinpoint which:**

```sql
SELECT cid_username,
       length(password_hash) AS hash_len,
       password_hash LIKE '$2%' AS is_bcrypt
FROM users
WHERE cid_username ILIKE 'sym1991123';   -- ILIKE = case-insensitive
```

Three possible outcomes:

| Result | Means | Fix |
|---|---|---|
| **0 rows** | No such user. Either you never finished sign-up, or you're hitting the wrong DB (check `app_config.json` `backendBaseUrl`). | Sign up first, or point backend at the right DB. |
| **1 row, `cid_username` is `Sym1991123` or different casing** | Username exists but in a different case. Postgres comparison is case-sensitive. | Sign in using the **exact** case the DB has (or I can add a CITEXT migration to make this case-insensitive going forward). |
| **1 row, `cid_username = 'sym1991123'`, `hash_len = 60`, `is_bcrypt = true`** | User exists, valid bcrypt hash, but `aaAA11!!` doesn't match it. Password drifted from what you remember. | Reset via SQL — paste this back to me and I'll generate a fresh hash for `aaAA11!!` you can plug in. |

Paste the result of the SELECT and I'll act on it.
