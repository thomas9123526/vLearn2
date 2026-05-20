# 260520_2245 — Add missing /admin/admins/me/permissions endpoint

## User prompt (verbatim)

> ok subadmin can see prompts, but he can't edit the prompt content on prompt tabs

## Root cause

A sub-admin with `prompts.edit` granted opened the Prompts tab and
found the textareas, the "Active" checkbox, the placeholder buttons,
and the Save button all disabled. The catalog list and the granted-
permission set in the database were both correct, so the bug was in
the frontend's permission lookup.

The Prompt Templates page gates editing on
[`usePermission('prompts.edit')`](admin_panel/src/app/(dashboard)/prompt-templates/page.tsx#L60).
That hook calls
[`GET /admin/admins/me/permissions`](admin_panel/src/hooks/use-permission.ts#L19)
to fetch the current user's effective permission set.

**The endpoint doesn't exist on the backend.**

`admin-admins.controller.ts` only defined: `GET catalog`, `GET ''`,
`POST ''`, `PUT :id/permissions`, `POST :id/permissions/:perm`,
`DELETE :id/permissions/:perm`, `POST :id/suspend`,
`POST :id/restore`, `DELETE :id`. The hook's request 404'd, the
query's `data` stayed undefined, and
`data?.includes('prompts.edit') ?? false` always returned `false`.

The same bug silently affected every other `usePermission(...)` call
for sub-admins — scenarios.edit, news.edit, courses.edit, etc.
Sub-admins could see the tabs (sidebar gating uses `usePermission` for
the *view* perm too, but the JWT's `permissions` claim was probably
masking it for view-only). Anything past the view bar — every edit
button, checkbox, textarea, Save — was disabled.

Superadmins were unaffected because the hook short-circuits on
`user.role === 'superadmin'` before the network call.

## Fix

Added [GET /admin/admins/me/permissions](backend/src/admin/admins/admin-admins.controller.ts#L62-L71):

* `@RequirePermission()` with no args — any authenticated admin /
  superadmin can read their own perms.
* For sub-admins: returns `[...permissions.getForUser(user.sub)]`,
  the same set used by the server-side `PermissionGuard`, so client
  and server agree on what's granted.
* For superadmins: returns the full `PERMISSION_KEYS` set (the
  frontend short-circuits this case but it's the right answer for
  any direct caller).

## How to verify

1. Restart the backend so the new route is registered.
2. Sign in as a sub-admin who has `prompts.edit` granted.
3. Open the Prompts tab. The "Active" checkbox should be enabled,
   the placeholder buttons should be clickable (and append to the
   textarea), the template textarea should be editable, and the
   Save button should enable as soon as you change anything.
4. Save → response 200, the "Saved {time}" footer appears.
5. As a regression check: same sub-admin signed in to a tab they
   *don't* have edit perms for (e.g. give them `scenarios.view`
   only) — that tab's Save / Edit buttons should still be disabled.
