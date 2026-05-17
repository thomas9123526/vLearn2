# Admin panel on port 4000

## What this task did

Moved the Next.js admin panel from its implicit `3001` convention to an
explicit `4000`, per user request.

Four edits:

- [admin_panel/package.json](../admin_panel/package.json) — `dev` script is
  now `next dev -p 4000`; `start` script is `next start -p 4000`. (`build`,
  `lint`, `typecheck` are port-agnostic, untouched.)
- [admin_panel/next.config.mjs](../admin_panel/next.config.mjs) —
  `experimental.serverActions.allowedOrigins` flipped from `'localhost:3001'`
  to `'localhost:4000'` so server-action POSTs from the dev UI aren't
  rejected as cross-origin.
- [admin_panel/README.md](../admin_panel/README.md) — quick-start command now
  shows `# http://localhost:4000`.
- [backend/.env.example](../backend/.env.example) — `CORS_ORIGINS` allow-list
  now includes `http://localhost:4000` instead of `3001`. Same change made to
  the local `backend/.env` so the running backend trusts the new origin
  without a manual edit.

## Conversation summary

- User: *"I want admin panel use 4000 port"*
- The admin panel was previously assumed to run on `3001` (per `next.config.mjs`
  comments and the README) but the `package.json` scripts didn't pin a port —
  `next dev` would just grab `3000`, which collides with the backend. So this
  task both fixes the unpinned port AND switches the chosen port to `4000`.

## Decisions / call-outs

- **`-p 4000` baked into npm scripts** rather than relying on `PORT=4000` env
  var or `.env.local`. Reasons: (1) script-level flag is visible in
  `package.json` so future contributors can't miss it; (2) avoids needing
  another `.env` file for what's a single fixed value in dev; (3) it works
  identically for `next start` (production).
- **`next.config.mjs` `allowedOrigins`** is needed for App Router server
  actions in Next 14 — Next rejects cross-origin POSTs unless the origin is
  in this list. Without updating it, any future server-action-based form on
  the admin panel would 403 on submit.
- **Updated `backend/.env` too**, not just `.env.example`. The running backend
  reads `.env`, so editing only the example wouldn't have any runtime effect
  — admin requests to the backend would fail CORS preflight.
- **Did NOT keep `3001` as a fallback origin**. CORS allow-lists should be
  exact. If you ever genuinely want both, just add it back as a comma-separated
  entry.
- **Did NOT touch [todoList_report/0517_v2/02_admin_panel_nextjs.md:87](../todoList_report/0517_v2/02_admin_panel_nextjs.md#L87)**
  which still says `3001`. That file is a historical report of what task 02
  did; rewriting it would make the report dishonest. The current README is
  the source of truth.
- **Did NOT touch the unrelated `3001` matches in
  `vLearn2Spec/.../FreeTalk (standalone).html`** — they're coincidental
  numeric occurrences in a design reference, not port references.
- **Did NOT rebuild** — `next build` is port-agnostic; the port is only
  consumed by `dev`/`start` at runtime. `cmds/build_admin.bat` will continue
  to succeed without changes.

## How to verify

```powershell
cd c:\project\vLearn2
cmds\start_admin_debug.bat
```

Console should print `Local: http://localhost:4000`. Open that URL → sign-in
page renders. From the backend's terminal, requests from the panel should now
pass CORS (no `Origin http://localhost:4000 not allowed` errors).

If the backend was running before this change, it needs a restart so it
picks up the new `CORS_ORIGINS` from `.env`.

## User prompt (verbatim)

> I want admin panel use 4000 port
