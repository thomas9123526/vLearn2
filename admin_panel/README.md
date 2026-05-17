# vLearn2 admin panel

Next.js 14 (App Router) admin UI for the vLearn2 backend. Sibling project to `../backend/` and `../flutter_app/`.

## Tech

- Next.js 14 (App Router, server components opt-in)
- Tailwind CSS 3 + shadcn/ui conventions (zinc base, CSS variables)
- TanStack Query for server state
- React Hook Form + Zod for forms
- TanStack Table for tabular admin views
- Recharts for the stats dashboard
- Lucide icons

## Quick start

```bash
cp .env.example .env.local
npm install
npm run dev    # http://localhost:4000
```

The backend must be running on `http://localhost:3000` (or whatever you set as `NEXT_PUBLIC_API_BASE_URL`).

## Bootstrap signup

Before the first admin exists, hit the backend's `POST /api/admin/auth/signup` directly (e.g. via `curl`). After the first admin is created, that endpoint auto-closes and subsequent admin accounts must be created from the **Admins** page in this panel.

## Auth

Email + password against `POST /auth/signin`. Tokens are stored in `sessionStorage` (deliberate trade-off — see [todoList/0517_v2/02 §2.11.2](../todoList/0517_v2/02_admin_panel_nextjs.md)).

A user without `admin` or `superadmin` role is bounced to `/signin` after authentication.

## Pages today

| Path | Status |
|------|--------|
| `/signin` | ✅ Sign-in form |
| `/` | ✅ Stats overview (gracefully degrades if `/admin/stats` isn't built yet) |
| `/news` | ✅ List + publish/archive (motivates the news CRUD endpoints from task 03) |
| `/config` | ✅ Visibility-flag toggles by category |

The remaining pages (scenarios / users / leaderboard / audit / admins) are deferred to follow-ups — backend endpoints land first, then the UI for each.

## Build scripts

The repo's `cmds/` folder will gain `build_admin.bat` + `start_admin_debug.bat` in a follow-up. Today: `npm run build` and `npm run dev` work directly.

## CI

A path-filtered workflow at `.github/workflows/admin_ci.yml` will run lint + typecheck + build on every push that touches `admin_panel/**`.
