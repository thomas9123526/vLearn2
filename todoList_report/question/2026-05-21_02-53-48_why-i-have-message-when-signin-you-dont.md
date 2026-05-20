# why i have message when signin , "you don't have permission to do that right now

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-20T17:53:48.760Z

## User

why i have message when signin , "you don't have permission to do that right now."

## Assistant

Let me find where that message is shown.

## Assistant

That message means the backend returned **HTTP 403** on sign-in. Per [`backend/src/auth/auth.service.ts:77-90`](backend/src/auth/auth.service.ts#L77-L90), the sign-in throws 403 in exactly two cases:

| Backend condition | i18n key |
|---|---|
| `vl_user_info.status = 'deleted'` | `account.deleted` |
| `vl_user_info.status = 'suspended'` AND (`suspended_until` is NULL **or** still in the future) | `account.suspended` |

The Flutter side then maps any 403 / `account.suspended` / `account.deleted` to the same polite string at [`polite_error.dart:86-89`](flutter_app/lib/core/errors/polite_error.dart#L86-L89).

So the account you're signing in as has been **flagged in the database** — not a code bug, a data state. To diagnose:

```sql
SELECT u.cid_username, ui.status, ui.suspended_until, ui.suspended_reason
FROM vl_users u
JOIN vl_user_info ui ON ui.user_id = u.id
WHERE u.cid_username = '<your-username>';
```

If you find `status = 'suspended'` or `'deleted'`, reset it with:

```sql
UPDATE vl_user_info
SET status = 'active', suspended_until = NULL, suspended_reason = NULL
WHERE user_id = (SELECT id FROM vl_users WHERE cid_username = '<your-username>');
```

Want me to also:
1. **Make the Flutter polite error more specific** so the message distinguishes "your account is suspended (reason: X, until: Y)" from "your account is deleted"? Right now both collapse to the generic line, which makes diagnosing hard.
2. **Add an admin-panel toggle** to flip the status back to active from the UI?
3. **Run the diagnostic SQL** for you? (I can if you tell me the username and we have a script that hits the DB.)
