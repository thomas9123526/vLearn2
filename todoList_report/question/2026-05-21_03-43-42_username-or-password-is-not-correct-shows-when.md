# username or password is not correct shows when sign in windows application

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-20T18:43:42.505Z

## User

username or password is not correct shows when sign in windows application

## Assistant

Let me check what the backend actually returns and look for clues — this could be a real credential mismatch or a configuration issue.

## Assistant

That message is the **401** path — backend returned `auth.invalid_credentials`. From [`backend/src/auth/auth.service.ts:72-99`](backend/src/auth/auth.service.ts#L72-L99) there are exactly three places it fires:

1. `findOne({ where: { cid_username } })` returns nothing → **the username doesn't exist** in `vl_users`.
2. The follow-up select-with-`password_hash` query returns nothing → racey deletion, essentially impossible.
3. `bcrypt.compare(typedPassword, stored.password_hash)` returns false → **the password doesn't match**.

Common real-world causes:

- **Typo** in the password (the input is `obscured` so easy to mis-type, especially since you can `Save my account` and we never validate the saved value matches what's in the DB after, say, a manual password change).
- **Case mismatch on the username.** Postgres compares `varchar` case-sensitively. If you signed up as `JohnDoe` and you type `johndoe` now, it's a different row → 401.
- **Account doesn't exist** for this username (you signed up under a different `cidUsername`, or the DB was re-seeded/cleared).
- **Backend pointing at a different DB** than the one your account lives in — check `app_config.json` `backendBaseUrl` matches the backend you actually ran sign-up against.

To pinpoint which one:

```sql
SELECT u.id, u.cid_username, u.cid, ui.status
FROM vl_users u
LEFT JOIN vl_user_info ui ON ui.user_id = u.id
WHERE u.cid_username ILIKE '<what-you-typed>';   -- ILIKE = case-insensitive
```

- **No rows** → cause #1 (or you're hitting the wrong DB).
- **Row found but `cid_username` casing differs from what you typed** → cause #2; sign in with the casing shown.
- **Row found, casing matches, `status = 'active'`** → cause #3 (wrong password). Reset it directly:

  ```sql
  -- Replace 'newpass' with what you want. The hash below is bcrypt('newpass', 10).
  -- Better: generate one yourself in a node REPL: bcrypt.hashSync('newpass', 10)
  UPDATE vl_users
  SET password_hash = '<new bcrypt hash>'
  WHERE cid_username = '<exact-username>';
  ```

Want me to add a `/auth/forgot-password` flow (CID-verified password reset) so users don't need DB access? Or just leave this as a one-off DB fix for now?
