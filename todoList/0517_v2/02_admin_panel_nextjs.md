# 02 — Next.js Admin Panel

Separate sibling project at `admin_panel/` that consumes the existing `/admin/*` API. Backend is already in place; this is a pure-frontend project.

## 2.1 Repository layout addition

```
vLearn2/
├── backend/
├── flutter_app/
├── admin_panel/           ← NEW
│   ├── src/
│   ├── public/
│   ├── package.json
│   ├── next.config.mjs
│   ├── tsconfig.json
│   ├── tailwind.config.ts
│   ├── components.json    ← shadcn config
│   ├── .env.example
│   └── README.md
└── ...
```

Same "independent sibling" pattern as backend + flutter_app. Own `package.json`, own README, own `.gitignore`, own CI workflow.

## 2.2 Tech stack

| Concern | Choice | Reason |
|---------|--------|--------|
| Framework | Next.js 14 (App Router) | Modern, server components, fast |
| UI | [shadcn/ui](https://ui.shadcn.com) | Editorial design vibe matches the Flutter app's apricot-tone aesthetic |
| Styling | Tailwind CSS 3.x | Comes with shadcn |
| State | TanStack Query (React Query) | Server-state cache; pairs nicely with the backend API |
| Auth | Same JWT pair as Flutter app | Reuse `/auth/signin` + token refresh; role-check via decoded JWT `role` claim |
| Forms | `react-hook-form` + `zod` | Validation matching backend DTOs |
| Tables | `@tanstack/react-table` | Sortable, filterable, paginated tables for users / scenarios / audit |
| Charts | `recharts` | Stats dashboard |
| Icons | `lucide-react` | Ships with shadcn |
| Image handling | `sharp` (via next/image) | Optimized image preview for scenario uploads |

## 2.3 Scaffolding

- [ ] **2.3.1** `cd admin_panel && npx create-next-app@latest .` with: TypeScript, ESLint, Tailwind, App Router, no `src/` flag (we use `src/` anyway), import alias `@/*`
- [ ] **2.3.2** `npx shadcn-ui@latest init` — pick zinc base color (works well in light + dark), CSS variables, defaults for the rest
- [ ] **2.3.3** Install initial shadcn components: `button`, `input`, `card`, `dialog`, `dropdown-menu`, `table`, `tabs`, `toast`, `select`, `switch`, `badge`, `checkbox`, `form`, `label`, `separator`, `sheet`, `skeleton`
- [ ] **2.3.4** Add packages: `@tanstack/react-query`, `@tanstack/react-table`, `react-hook-form`, `zod`, `@hookform/resolvers`, `recharts`, `lucide-react`, `date-fns`

## 2.4 Folder structure

```
admin_panel/src/
├── app/
│   ├── (auth)/
│   │   ├── signin/page.tsx
│   │   └── signup/page.tsx          ← bootstrap only; UI checks if signup is open
│   ├── (dashboard)/
│   │   ├── layout.tsx               ← sidebar + topbar; auth-gated
│   │   ├── page.tsx                 ← /admin home: stats overview
│   │   ├── scenarios/
│   │   │   ├── page.tsx             ← list + filters
│   │   │   ├── new/page.tsx
│   │   │   └── [id]/page.tsx        ← edit + image upload
│   │   ├── courses/...
│   │   ├── achievements/...
│   │   ├── users/
│   │   │   ├── page.tsx             ← search + filters
│   │   │   └── [id]/page.tsx        ← drill-down
│   │   ├── leaderboard/page.tsx
│   │   ├── news/...                 ← see todoList/0517_v2/03
│   │   ├── config/page.tsx          ← visibility flags
│   │   ├── audit/page.tsx           ← admin_audit_log search + export
│   │   ├── admins/page.tsx          ← sub-admin management
│   │   └── settings/page.tsx        ← session, theme
│   ├── api/                         ← thin BFF routes for any non-bearer flows (optional)
│   ├── layout.tsx                   ← TanStack Query + auth provider wrappers
│   └── globals.css
├── components/
│   ├── ui/                          ← shadcn-generated
│   ├── data-table/                  ← shared TanStack-table wrapper
│   ├── forms/                       ← scenario/persona/course/etc form components
│   ├── permission-checkbox-grid.tsx ← renders the catalog as checkboxes
│   ├── stats-cards.tsx
│   └── audit-log-row.tsx
├── lib/
│   ├── api.ts                       ← fetch wrapper with JWT + refresh
│   ├── auth.ts                      ← token store + decode + role check
│   ├── permissions.ts               ← mirrors the backend PERMISSION_CATALOG (or fetches it once and caches)
│   ├── query-client.ts              ← TanStack Query setup
│   └── env.ts                       ← validated public env (NEXT_PUBLIC_API_BASE_URL)
└── hooks/
    ├── use-current-user.ts
    ├── use-permission.ts            ← const can = usePermission('scenarios.edit')
    └── use-paginated-table.ts
```

## 2.5 Auth flow

- [ ] **2.5.1** Sign-in form posts `{email, password}` to `POST /api/auth/signin` (same endpoint as Flutter)
- [ ] **2.5.2** Stores `accessToken` + `refreshToken` in `httpOnly` cookies via a Next.js Route Handler (avoids `localStorage` XSS risk)
- [ ] **2.5.3** Bootstrap signup: `/admin/auth/signup` page that calls `POST /api/admin/auth/signup`; if it returns 403 (already-bootstrapped), redirect to `/signin` with a friendly note
- [ ] **2.5.4** Decoded JWT `role` claim drives visibility of nav items. `user` role gets the admin-panel "you don't have access" screen even if they manage to navigate here
- [ ] **2.5.5** Refresh: on 401, the API wrapper calls `POST /api/auth/refresh` once before failing
- [ ] **2.5.6** Sign-out: `POST /api/auth/signout` then clear cookies + redirect to `/signin`

## 2.6 Permission-aware UI

The catalog from `GET /api/admin/admins/catalog` drives:
- Which nav items appear (a sub-admin without `users.view` doesn't see the Users link)
- Which buttons are enabled (Edit button shows for `scenarios.edit` holders)
- Which form fields are editable (role-change requires `users.edit_role`, hidden otherwise)

- [ ] **2.6.1** `usePermission('scenarios.edit')` hook returns `boolean`. Superadmin always returns true (their JWT has `permissions: ['*']`)
- [ ] **2.6.2** `<RequirePermission perm="scenarios.edit">…</RequirePermission>` wrapper component
- [ ] **2.6.3** Server-side enforcement is already in backend's `PermissionGuard` — UI hiding is just UX, never security

## 2.7 Pages — feature parity with the backend `/admin/*` API

| Page | Endpoints used | Notes |
|------|----------------|-------|
| Dashboard | `GET /admin/stats` | Stat cards + recharts time series |
| Scenarios list | `GET /admin/scenarios?...` | Filters + bulk select |
| Scenario edit | `GET/PATCH /admin/scenarios/:id`, `POST /:id/image` | Image upload via dropzone; live preview |
| Courses | `GET/POST/PATCH /admin/courses/*` + scenario membership ordering | Drag-and-drop reorder |
| Achievements | `GET/POST/PATCH /admin/achievements` + manual grant | |
| Users list | `GET /admin/users?...` | TanStack table with server-side pagination |
| User detail | `GET /admin/users/:id` + drill-down endpoints | Tabs: Profile · Sessions · Skills · Violations · (Transcripts — superadmin only with warning modal) |
| Leaderboard | `GET /admin/leaderboard?metric=...` | Metric dropdown + language/timeframe filters |
| News | see [todoList/0517_v2/03](03_news_feature.md) | Inherits scenario-CRUD pattern |
| Config (flags) | `GET/PATCH /admin/config/*` | Grouped by `category`; type-aware editors (bool / string / number / object JSON) |
| Audit log | `GET /admin/audit` + export | Filter by user / action / target_type / date |
| Admins (subadmins) | `GET/POST /admin/admins`, perm grant/revoke | Permission catalog rendered as a checkbox grid grouped by category |

## 2.8 .env

```
NEXT_PUBLIC_API_BASE_URL=http://localhost:3000/api
```

That's it. JWT secrets live in the backend; the admin panel only needs the API base URL.

## 2.9 CI

- [ ] **2.9.1** New `.github/workflows/admin_ci.yml` path-filtered to `admin_panel/**`
- [ ] **2.9.2** Steps: `npm ci && npm run lint && npm run build && npm test`
- [ ] **2.9.3** Optional: deploy preview via Vercel CLI on PR

## 2.10 Build scripts

- [ ] **2.10.1** Add to `cmds/`: `build_admin.bat` (Next.js production build) and `start_admin_debug.bat` (`next dev`)

## 2.11 Honest call-outs

1. **The backend's admin content endpoints aren't fully built yet** — per [todoList_report/0516/13](../../todoList_report/0516/13_admin_content_and_users.md), only AdminAuth + AdminAdmins + AppConfig + AdminAdmins are wired. Scenarios/courses/users/leaderboards/stats endpoints need controller methods added. **Build the admin panel and these endpoints in parallel** — each panel page motivates the corresponding endpoint.
2. **Storage of JWT in `httpOnly` cookies** requires a thin BFF route in Next.js (since the backend issues bearer tokens, not Set-Cookie headers). The route signs the response with the cookie itself. Simpler alternative: store in `sessionStorage` and accept the XSS risk for an admin-only tool.
3. **Transcript viewer is privacy-sensitive.** Per [0516/13 §13.6.5](../0516/13_admin_content_and_users.md), it's superadmin-only + audited + shows a warning modal before fetching. Don't reduce the friction.
4. **Image uploads through Next.js → backend** — the panel uses `FormData` + `multipart/form-data` to hit `POST /admin/scenarios/:id/image`. Backend handles validation + compression (already in [0516/13 §13.3](../0516/13_admin_content_and_users.md) plan; `sharp` already installed).
5. **Hosting** — Vercel is the path of least resistance for Next.js. The backend stays on its own host (could be the same VPS, with CORS configured for the admin-panel origin).
