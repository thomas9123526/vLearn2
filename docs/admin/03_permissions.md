# Admin panel — Permissions

## Why

Sub-admins delegate a slice of work — moderate users, edit news, etc.
— without becoming a full superadmin. The permission system is
deliberately flat: a sub-admin holds a list of strings, each of the
form `<feature>.<action>`. A holder of `'*'` (superadmin) matches
everything.

## Storage

| Where              | What                                                             |
| ------------------ | ---------------------------------------------------------------- |
| `vl_admins`        | One row per admin / superadmin. `role` discriminator.            |
| `vl_admin_permissions` | One row per granted permission, keyed by `(user_id, permission)`. |
| JWT payload        | `permissions: string[]` for the lifetime of the token (15 min).   |

The JWT carrying the permissions is short-lived — granting / revoking
takes effect on the next refresh (≤ 15 min) without forcing a
sign-out.

## Granting

`PATCH /admin/admins/:id/permissions` takes a `{ permissions:
string[] }` body, replaces the rows in `vl_admin_permissions`
atomically, and writes an entry to `vl_admin_audit_log` with the
`old` and `new` lists.

In the admin panel: **Admins tab → row → Edit Permission** opens the
`EditPermissionsDialog`. The dialog renders the catalog
(`src/lib/permission-catalog.ts`) as a checkboxed list grouped by
feature.

## Enforcing

Two surfaces:

### Server (real enforcement)

Every admin endpoint is decorated with
`@RequirePermission('feature.action')`. `PermissionGuard` reads the
JWT, intersects against the decorator, throws 403 on miss.

```ts
@Post(':id/suspend')
@RequirePermission('users.suspend')
async suspend(...) { … }
```

### Client (UX gating)

`usePermission(name)` returns `boolean` for the JWT in storage.
Used to *hide* buttons and nav items the user can't act on. Not a
security boundary — never trust it.

## Catalog (current)

| Permission                | Granted to                  | Affects                                                         |
| ------------------------- | --------------------------- | --------------------------------------------------------------- |
| `*`                       | superadmin                   | Everything                                                      |
| `users.view`              | sub-admins (assignable)      | List + detail of app users                                      |
| `users.suspend`           | sub-admins (assignable)      | Suspend / restore an app user                                   |
| `users.reset_password`    | sub-admins (assignable)      | Reset an app user's password                                    |
| `admins.view`             | sub-admins (assignable)      | List sub-admins                                                 |
| `news.view`               | sub-admins (assignable)      | Read the news list                                              |
| `news.edit`               | sub-admins (assignable)      | Create / edit / publish / archive news                          |
| `prompts.view`            | sub-admins (assignable)      | Read prompt templates                                           |
| `prompts.edit`            | sub-admins (assignable)      | Edit prompt templates                                           |
| `scenarios.view`          | sub-admins (assignable)      | Read scenario list / detail                                     |
| `scenarios.edit`          | sub-admins (assignable)      | Create / edit / archive scenarios                               |
| `personas.view`           | sub-admins (assignable)      | Read personas                                                   |
| `personas.edit`           | sub-admins (assignable)      | Create / edit personas                                          |
| `audit.view`              | sub-admins (assignable)      | Read the audit log                                              |
| `config.view`             | sub-admins (assignable)      | Read layout / app config                                        |
| `config.edit`             | sub-admins (assignable)      | Edit layout / app config                                        |

## Adding a new permission

1. Pick the string `feature.action`.
2. Add it to `src/lib/permission-catalog.ts` so it shows up in the
   admin UI dialog.
3. Decorate the corresponding controller methods with
   `@RequirePermission('feature.action')`.
4. Re-deploy. Existing tokens won't carry the new permission until
   they refresh — no migration needed.

## Audit trail

Every `PATCH …/permissions` writes a `vl_admin_audit_log` row with
the previous and new sets. The Audit tab in the admin panel renders
this feed; sub-admins see only their own actions, superadmins see
the full stream.
