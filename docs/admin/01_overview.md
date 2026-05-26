# Admin panel — Overview

The admin panel is a **Next.js 14 (App Router)** project under
`admin_panel/`. It is a separate deployable from the backend and
talks to it over `/admin/*` routes using JWT tokens with `actor:
'admin'`.

## Folder shape

```
admin_panel/src/
  app/
    (dashboard)/              // protected, layout includes left rail
      admins/
      audit/
      categories/
      config/
      leaderboard/
      news/
      personas/
      prompt-templates/
      scenarios/
      settings/
      signup/                  // sub-admin invitation flow
      users/
      layout.tsx               // the rail + nav
      page.tsx                 // dashboard landing
    signin/
      page.tsx
  components/
    ui/                        // shadcn-flavoured primitives
  hooks/
    use-permission.ts          // reads the JWT payload claims
    use-toast.ts
  lib/
    api.ts                     // tiny fetch wrapper + base URL
    flag-catalog.ts            // catalog of layout / feature flags
    permissions.ts             // permission strings
```

## Routing model

* `app/signin/page.tsx` — public route. Posts to
  `/admin/auth/signin`. On success, stores the JWT pair in
  `localStorage` and redirects to `/`.
* `app/(dashboard)/**` — guarded by `app/(dashboard)/layout.tsx`. The
  layout reads the JWT, redirects to `/signin` on absence/expiry,
  and renders the sidebar nav.
* `lib/api.ts` attaches `Authorization: Bearer <access>` from
  storage and handles the refresh-on-401 dance the same way the
  Flutter app does.

## Permission model

Each tab gates its visibility on a permission string:

| Tab               | Permission         |
| ----------------- | ------------------ |
| Users             | `users.view`       |
| Suspend user      | `users.suspend`    |
| Reset password    | `users.reset_password` |
| Admins            | `admins.view`      |
| News              | `news.view`        |
| Prompt templates  | `prompts.view`     |
| Scenarios         | `scenarios.view`   |
| Audit log         | `audit.view`       |
| Config            | `config.view`      |

`'*'` (held by `superadmin`) matches everything. Permissions are
checked in two places:

* **Client side** via the `usePermission(name)` hook — used to hide
  buttons / nav items the user can't act on. This is UX-only,
  not security.
* **Server side** via the `PermissionGuard` decorator on every admin
  endpoint. This is the real enforcement.

## Editor stack

Most editor pages use **react-hook-form + zod** for forms and
**@tanstack/react-query** for fetch / mutate. Inputs are wrapped
in a `Field` component (`forwardRef` is mandatory — react-hook-form
calls `setValue` via the ref). Two notable conventions:

* Mutations call `qc.invalidateQueries` on success so the list view
  refetches.
* List rows do **not** wrap titles in `<Link>` until the matching
  `/feature/[id]/page.tsx` exists. Currently `scenarios` and `news`
  use plain `<span>`s pending the per-row edit pages.

## Audit log

Every write inside an admin controller passes through
`AdminAuditLogService.record({ actor, action, target, old, new })`
inside the same TypeORM transaction. The Audit tab
(`app/(dashboard)/audit/page.tsx`) renders the rolling feed; a
sub-admin sees only their own actions, a superadmin sees everyone.
