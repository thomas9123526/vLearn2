# vLearn2 — Admin panel source description (part 1)

Per-file walkthrough of `admin_panel/`. For the conceptual overview
of routing, auth, and permissions see `docs/admin/`.

## 1. Top-level layout

```
admin_panel/
  package.json
  next.config.js
  tsconfig.json
  .env.local                 // API_BASE_URL
  public/
  src/
    app/                     // Next.js 14 App Router
    components/              // shared UI primitives
    hooks/                   // React hooks
    lib/                     // pure-JS utilities
```

Stack: **Next.js 14 (App Router) + TypeScript + Tailwind + shadcn-
flavoured primitives + @tanstack/react-query + react-hook-form +
zod**. Builds to a static export served by `npm start` on port
4101 (default).

## 2. Routes (`src/app/`)

App Router conventions: `page.tsx` is the route, `layout.tsx` wraps
children, `loading.tsx` is the Suspense fallback, `error.tsx` is
the error boundary.

### 2.1 Top-level

| Path | Owns |
| --- | --- |
| `src/app/layout.tsx` | HTML shell. Loads global CSS, sets `<html lang>`, mounts the QueryClient provider. |
| `src/app/page.tsx` | Redirects to `/dashboard` or `/signin` based on the JWT in localStorage. |
| `src/app/signin/page.tsx` | Public sign-in form. POSTs `/admin/auth/signin`, stores tokens, redirects. |
| `src/app/signup/page.tsx` | Sub-admin invitation completion. Reads `?token=…`, POSTs to `/admin/admins/complete-signup`. |
| `src/app/loading.tsx` | Top-level spinner during navigation. |
| `src/app/error.tsx` | Top-level error boundary that re-renders on click. |

### 2.2 Protected dashboard (`src/app/(dashboard)/`)

`layout.tsx` mounts the sidebar + top bar, gates on the JWT, and
exposes a `QueryClientProvider`. Subroutes:

| Route | Owns |
| --- | --- |
| `(dashboard)/page.tsx` | Dashboard landing — counter cards + recent audit feed. |
| `(dashboard)/users/page.tsx` | App users list with search + status filter. Suspend/restore + reset-password buttons inline. |
| `(dashboard)/users/[id]/page.tsx` | Per-user detail — XP / level / sessions. |
| `(dashboard)/admins/page.tsx` | Sub-admins grid view. "Edit Permission" dialog. Invite form via "+ New admin". |
| `(dashboard)/news/page.tsx` | News list — Publish / Archive inline; "New post" link. (Per-row edit page pending.) |
| `(dashboard)/news/new/page.tsx` | New post form. |
| `(dashboard)/scenarios/page.tsx` | Scenarios list — title spans (no per-row edit route yet). |
| `(dashboard)/scenarios/new/page.tsx` | New scenario form with i18n title/body, role definitions, objectives. |
| `(dashboard)/scenarios/[id]/page.tsx` | Per-scenario edit. (Pending pattern — currently re-uses `new` page.) |
| `(dashboard)/personas/page.tsx` | Persona list with avatar preview. |
| `(dashboard)/personas/new/page.tsx` | New persona. |
| `(dashboard)/personas/[id]/page.tsx` | Edit persona. Pre-fills via react-hook-form `reset()` once the GET resolves. |
| `(dashboard)/prompt-templates/page.tsx` | Three templates editor: tutor_system / grammar / feedback. Save + restore-defaults + audit log. |
| `(dashboard)/categories/page.tsx` | Scenario categories CRUD. |
| `(dashboard)/leaderboard/page.tsx` | Top-N learners by XP / streak. |
| `(dashboard)/config/page.tsx` | Layout flag toggles (`tabs.home`, `tabs.scenarios`, …). |
| `(dashboard)/settings/page.tsx` | Operator-only settings (telemetry on/off, feature flags). |
| `(dashboard)/audit/page.tsx` | Audit log feed with actor + action + diff. |

### 2.3 Layout & nav

`(dashboard)/layout.tsx`:

* Reads the JWT from `localStorage`. Redirects to `/signin` if
  absent / expired.
* Mounts the left rail (`<Sidebar />`), the top bar
  (`<Topbar />`), and the active route as `{children}`.
* Wraps everything in `<QueryClientProvider>` and
  `<ToastProvider>`.

`src/components/sidebar.tsx` reads the JWT permissions and hides
items the user can't act on (`usePermission`).

## 3. Components (`src/components/`)

| File | Owns |
| --- | --- |
| `ui/button.tsx` | shadcn `Button` (primary / outline / ghost / link variants). |
| `ui/card.tsx` | Container with subtle shadow + border. |
| `ui/dialog.tsx` | Portal-based modal — backdrop, Escape closes, header / body / footer slots. Built for the EditPermissionsDialog. |
| `ui/input.tsx`, `ui/label.tsx`, `ui/textarea.tsx` | Form primitives. |
| `ui/toast.tsx`, `ui/toaster.tsx` | shadcn-style toast system. Driven by `useToast()`. |
| `ui/field.tsx` | `forwardRef` wrapper around `Input` / `Textarea` so `react-hook-form`'s `reset()` populates the inputs. |
| `sidebar.tsx`, `topbar.tsx` | Dashboard chrome. |
| `permission-dialog.tsx` | EditPermissionsDialog used from admins page. |

## 4. Hooks (`src/hooks/`)

| Hook | What it does |
| --- | --- |
| `use-permission.ts` | Decodes the JWT in localStorage and returns `boolean` for a permission string. |
| `use-toast.ts` | Imperative `toast({ title, description, variant })` API for non-component code (mutations). |

## 5. Libraries (`src/lib/`)

| File | What |
| --- | --- |
| `api.ts` | `api<T>(path, init?)` — fetch wrapper that prepends `process.env.NEXT_PUBLIC_API_BASE_URL`, attaches the Bearer header from localStorage, handles 401 → refresh → retry once, throws `ApiError { status, i18nKey?, message }` on failure. |
| `auth.ts` | localStorage token helpers (`getAccess`, `getRefresh`, `setPair`, `clear`). Decodes the JWT payload for `usePermission`. |
| `permission-catalog.ts` | Single source of truth for permission strings. Used by `EditPermissionsDialog` + (on the server) `PermissionGuard`. |
| `flag-catalog.ts` | Layout flag string catalog used by `/config`. |
| `utils.ts` | `cn(...inputs)` Tailwind class concatenator. |

## 6. Permission model

Identical contract to the backend (see
`docs/admin/03_permissions.md`):

```
permission := `<feature>.<action>`
'*' := superadmin wildcard
```

Client only uses it to *hide* nav / buttons; server enforces.

## 7. How the panel connects to the backend

A typical "edit scenario title" flow:

```
ScenariosListPage  (src/app/(dashboard)/scenarios/page.tsx)
   │ tanstack/react-query useQuery({ queryKey: ['admin-scenarios'] })
   │   → api('/admin/scenarios')  → backend AdminScenariosController.list
   ▼
Renders rows
   │
   │ user clicks "Edit"
   ▼
ScenarioEditPage  (src/app/(dashboard)/scenarios/[id]/page.tsx)
   │ useQuery({ queryKey: ['admin-scenario', id] })
   │   → api(`/admin/scenarios/${id}`)
   │
   │ react-hook-form.reset(initial)  ← populates inputs
   │
   │ user types, submits
   ▼
useMutation({
   mutationFn: (body) => api(`/admin/scenarios/${id}`, { method: 'PATCH', body: JSON.stringify(body) }),
   onSuccess: () => qc.invalidateQueries(['admin-scenarios'])
})
   ▼
Backend: AdminScenariosController.update
   │ ValidationPipe over UpdateScenarioDto
   │ PermissionGuard: requires scenarios.edit
   ▼
DataSource.transaction:
   │ load + mutate ScenarioEntity
   │ AdminAuditLogService.record(...)
   ▼
Returns updated row
   │
   │ react-query invalidate → list refetches → toast.success
   ▼
ScenariosListPage re-renders
```

## 8. Auth & session

* Token storage: `localStorage` keys `admin.access`, `admin.refresh`.
* Refresh: `api.ts` catches 401, calls `POST /admin/auth/refresh`,
  retries the original request. A single in-flight refresh is
  guarded by a module-level `Promise<TokenPair> | null` so
  concurrent 401s share one refresh.
* Sub-admin invitation: `POST /admin/admins` returns a one-shot
  signup token. Recipient uses `/signup?token=…` to set a password.

## 9. Build & deploy

```
npm install
npm run build
npm start -p 4101
```

`next.config.js` enables `experimental.outputFileTracingRoot`
pointing at the workspace root so the standalone output picks up
the right `node_modules`. Service launcher under `cmds/`
(`start_service_windows.bat`) cold-builds + starts on port 4101.

---

That's part 1. Part 2 will cover the per-route component
breakdown, the editor patterns (forwardRef + react-hook-form +
zod), and the audit-log rendering pipeline.
