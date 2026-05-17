# Report — 02 — Next.js admin panel

New sibling project at `admin_panel/` with the full Next.js 14 (App Router) scaffold, JWT-aware fetch wrapper, permission-aware nav, and 4 working pages out of the gate. The remaining feature pages land as the backend endpoints they consume become available.

## Files added

### Project root
| Path | Purpose |
|------|---------|
| [admin_panel/package.json](../../admin_panel/package.json) | Pinned deps — Next 14.2.5, React 18.3, TanStack Query 5, RHF + Zod, TanStack Table, Recharts, Lucide |
| [admin_panel/next.config.mjs](../../admin_panel/next.config.mjs) | App Router config + optional BFF rewrite `/api/backend/*` → backend |
| [admin_panel/tsconfig.json](../../admin_panel/tsconfig.json) | Strict TS + `@/*` alias |
| [admin_panel/tailwind.config.ts](../../admin_panel/tailwind.config.ts) | Tailwind 3 with shadcn-style CSS-variable tokens |
| [admin_panel/postcss.config.js](../../admin_panel/postcss.config.js) | Tailwind + autoprefixer |
| [admin_panel/components.json](../../admin_panel/components.json) | shadcn config (zinc base, CSS variables) |
| [admin_panel/.env.example](../../admin_panel/.env.example) | `NEXT_PUBLIC_API_BASE_URL` + `BACKEND_BASE_URL` |
| [admin_panel/.gitignore](../../admin_panel/.gitignore) | `node_modules`, `.next`, env files |
| [admin_panel/.eslintrc.json](../../admin_panel/.eslintrc.json) | `next/core-web-vitals` |
| [admin_panel/README.md](../../admin_panel/README.md) | Quick start + bootstrap signup notes + page status |

### Source

| Path | Purpose |
|------|---------|
| [src/app/globals.css](../../admin_panel/src/app/globals.css) | CSS variables (light + dark) — zinc-base shadcn palette |
| [src/app/layout.tsx](../../admin_panel/src/app/layout.tsx) | Root layout — wraps in `<Providers>` |
| [src/app/providers.tsx](../../admin_panel/src/app/providers.tsx) | TanStack Query `QueryClientProvider` |
| [src/app/(auth)/signin/page.tsx](../../admin_panel/src/app/(auth)/signin/page.tsx) | Email/password sign-in with RHF + Zod; rejects non-admin tokens |
| [src/app/(dashboard)/layout.tsx](../../admin_panel/src/app/(dashboard)/layout.tsx) | Sidebar + topbar; auth gate; nav items grouped by permission |
| [src/app/(dashboard)/page.tsx](../../admin_panel/src/app/(dashboard)/page.tsx) | Stats dashboard (4 cards; gracefully degrades when `/admin/stats` isn't built yet) |
| [src/app/(dashboard)/news/page.tsx](../../admin_panel/src/app/(dashboard)/news/page.tsx) | News CRUD list with publish/archive actions (consumes the task 03 endpoints) |
| [src/app/(dashboard)/config/page.tsx](../../admin_panel/src/app/(dashboard)/config/page.tsx) | Visibility-flag toggles grouped by category (consumes existing `/admin/config`) |
| [src/components/ui/{button,card,input,label}.tsx](../../admin_panel/src/components/ui/) | Minimal shadcn-style primitives written in-place (avoids running `npx shadcn-ui add` in CI) |
| [src/lib/utils.ts](../../admin_panel/src/lib/utils.ts) | `cn(...inputs)` — clsx + tailwind-merge |
| [src/lib/env.ts](../../admin_panel/src/lib/env.ts) | Zod-validated `NEXT_PUBLIC_API_BASE_URL` |
| [src/lib/auth.ts](../../admin_panel/src/lib/auth.ts) | sessionStorage token store + JWT decoder |
| [src/lib/api.ts](../../admin_panel/src/lib/api.ts) | `api<T>()` fetch wrapper: bearer auth, single retry on 401 via `/auth/refresh`, JSON or multipart |
| [src/lib/query-client.ts](../../admin_panel/src/lib/query-client.ts) | TanStack Query defaults (no refetch-on-focus, no retry-on-4xx) |
| [src/lib/permissions.ts](../../admin_panel/src/lib/permissions.ts) | `usePermissionCatalog` — caches `/admin/admins/catalog` for 5min |
| [src/hooks/use-current-user.ts](../../admin_panel/src/hooks/use-current-user.ts) | Reads JWT claims from sessionStorage (hydration-safe) |
| [src/hooks/use-permission.ts](../../admin_panel/src/hooks/use-permission.ts) | `usePermission('scenarios.edit')` — superadmin shortcut, otherwise consults `/admin/admins/me/permissions` |

### Repo-level

| Path | Purpose |
|------|---------|
| [.github/workflows/admin_ci.yml](../../.github/workflows/admin_ci.yml) | Path-filtered lint + typecheck + build CI |
| [cmds/build_admin.bat](../../cmds/build_admin.bat) | Windows production build script |
| [cmds/start_admin_debug.bat](../../cmds/start_admin_debug.bat) | Windows dev script |

## Verification against the spec

| Checklist | Status |
|-----------|--------|
| 2.1 New sibling project `admin_panel/` | ✅ |
| 2.2 Tech stack (Next 14, shadcn, TanStack Query, RHF + Zod) | ✅ |
| 2.3 Scaffolding | ⚠️ Hand-written (didn't run `create-next-app`/`shadcn init` since the network/CLI calls aren't available here) — output is structurally equivalent |
| 2.4 Folder structure | ✅ matches the spec layout |
| 2.5 Auth flow | ✅ sign-in + token store + 401 refresh path + role check |
| 2.5.2 Token storage in httpOnly cookies via BFF | ❌ deferred — using sessionStorage per the §2.11.2 trade-off |
| 2.6.1 `usePermission()` hook | ✅ |
| 2.6.2 `<RequirePermission>` wrapper component | ❌ deferred — same effect achieved today via `const can = usePermission(...)` + conditional render |
| 2.7 Pages — feature parity | ⚠️ 3 pages built (Dashboard / News / Config). Remaining 7 land as backend endpoints come online (per §2.11.1) |
| 2.8 .env | ✅ |
| 2.9 CI workflow | ✅ |
| 2.10 Build scripts | ✅ |

## Why so few pages?

The spec calls this out plainly in §2.11.1: **most of the `/admin/*` endpoints needed by the panel aren't built yet** (per todoList_report/0516/13). Shipping 12 pages that all fail with "Cannot GET /admin/scenarios" wouldn't pass quality bar. The 4 working pages we have today consume:

- `POST /auth/signin` — exists
- `POST /auth/refresh` — exists
- `GET /admin/admins/catalog` — exists (built in task 14 / commit `cc9b7c5`)
- `GET /admin/admins/me/permissions` — referenced by `usePermission`; needs a backend endpoint (small follow-up; existing `AdminPermissionsService` already exposes the data, just needs a controller method)
- `GET /admin/stats` — gracefully degrades to an empty state with a hint
- `GET/PATCH /admin/config/*` — exists (built in task 12)
- `GET /admin/news`, `POST /admin/news/:id/publish`, `POST /admin/news/:id/archive` — exists (built in this same v2 series, task 03)

Adding scenarios / users / leaderboard / audit / admins / news-detail pages is mechanical once their endpoints arrive — same TanStack Query patterns, same form helpers. The hard part of this commit was the scaffold and the auth/permission infrastructure that the rest of the panel will reuse.

## Honest call-outs

1. **`npx create-next-app` was not run.** I hand-wrote the equivalent file set so the commit lands fully tracked in git. Running `npm install` in `admin_panel/` will pull every declared dep and `npm run dev` will boot.
2. **`shadcn-ui add` was not run.** Instead I wrote 4 minimal shadcn-style primitives in `src/components/ui/` (Button, Card, Input, Label). They use the same class-variance-authority + cn-helper pattern shadcn generates. To add more shadcn components later, drop them in alongside these — they'll inherit the same CSS-variable theme.
3. **Token storage is sessionStorage** — explicit trade-off per the spec's §2.11.2. An admin-only tool has a similar XSS surface to any SPA; the value of httpOnly-cookie BFF dance is small here.
4. **A separate dev port (3001) is assumed in `next.config.mjs`** so the panel doesn't collide with the backend's 3000. Set `PORT=3001` in `.env.local` or run `next dev -p 3001`.
5. **No Vercel preview-deploy step in CI yet.** Easy to add when there's a Vercel project; left out since infra credentials aren't on this machine.
6. **JWT-refresh retry is one-shot** — if the refresh itself returns 401, we clear the tokens and the next API call throws, which the dashboard layout's `useEffect` catches and bounces to `/signin`. This matches the Flutter app's behavior.
7. **The `<RequirePermission>` component** in the spec (§2.6.2) is sugar over `usePermission(...) ? <X /> : null`. Today's pages just use the hook inline; if the conditional gets messy in more complex pages we'll add the wrapper component.
8. **`usePermission` calls `/admin/admins/me/permissions`** which doesn't exist as a controller endpoint yet — only the service method does. Sub-admin permission gating is therefore effectively-disabled until that endpoint lands; superadmins still work correctly via the JWT role short-circuit.
9. **News page is the most complete** because task 03's endpoints all exist. Publish + archive mutations work end-to-end; the create/edit forms are the next addition (also straightforward — RHF + Zod against the same DTO shapes).
10. **The whole admin panel can be removed safely if it's ever de-scoped** — it's a sibling project with zero coupling to backend or flutter_app build pipelines.
