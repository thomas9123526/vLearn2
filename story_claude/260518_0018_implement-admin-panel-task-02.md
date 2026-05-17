# Implement 02_admin_panel_nextjs — Next.js sibling scaffold

## What this task did

Created a new sibling project at `admin_panel/` per [todoList/0517_v2/02_admin_panel_nextjs.md](../todoList/0517_v2/02_admin_panel_nextjs.md). The scaffold is fully hand-written (no `npx create-next-app` / no `shadcn-ui add` in this environment), but matches the spec's tooling, structure, and conventions so `npm install && npm run dev` boots a working panel.

### Scaffold
- package.json, next.config.mjs, tsconfig.json, tailwind.config.ts, postcss.config.js, components.json, .env.example, .gitignore, .eslintrc.json
- globals.css with zinc-base shadcn CSS variables (light + dark)
- Root layout + Providers (TanStack Query)
- 4 minimal shadcn-style UI primitives: Button, Card, Input, Label

### Infrastructure
- `src/lib/api.ts` — bearer-auth fetch wrapper with 401-refresh retry
- `src/lib/auth.ts` — sessionStorage token store + JWT decoder
- `src/lib/env.ts` — Zod-validated `NEXT_PUBLIC_API_BASE_URL`
- `src/lib/query-client.ts` — TanStack Query defaults
- `src/lib/utils.ts` — `cn(...)` helper
- `src/lib/permissions.ts` — `usePermissionCatalog`
- `src/hooks/use-current-user.ts` — hydration-safe JWT-claim reader
- `src/hooks/use-permission.ts` — superadmin shortcut + sub-admin perms fetch

### Pages
- `/signin` — RHF + Zod sign-in, rejects non-admin tokens
- `/` (dashboard) — 4 stat cards; gracefully degrades when `/admin/stats` is missing
- `/news` — list with publish/archive actions (consumes task 03 endpoints)
- `/config` — visibility-flag toggles grouped by category (consumes existing `/admin/config`)

### Repo-level
- `.github/workflows/admin_ci.yml` — path-filtered lint + typecheck + build
- `cmds/build_admin.bat` + `cmds/start_admin_debug.bat`

The remaining feature pages (scenarios / users / leaderboard / audit / admins / news-detail) are deferred until their backend endpoints come online — same pattern, same hooks, mechanical adds.

## Report

[todoList_report/0517_v2/02_admin_panel_nextjs.md](../todoList_report/0517_v2/02_admin_panel_nextjs.md)

## User prompt (verbatim)

> For every txt files inside todoList\\0517_v2 folder, plz do the todo List one by one.
> After you have done task, produce report what you have done and save as md format to "todoList_report\\0517_v2" folder.
> md filename can be xxx.md where xxx means the current todo file name.
> You are an expert fullstack developer
> Don't ask me anything. Go automatically without my choice or answer. You do it by yourself and by your desicion.
> You have many times. take it easy.
> Quality is important.
