# Add `cmds/start_admin.bat`

## What this task did

Created [cmds/start_admin.bat](../cmds/start_admin.bat) — sibling of the
just-added [cmds/start_backend.bat](../cmds/start_backend.bat) that launches
the Next.js admin panel in dev mode (`npm run dev`, which after this morning's
edit resolves to `next dev -p 4000` with hot reload).

Same flow as the backend launcher:

- `pushd` into `admin_panel/`
- run `npm install` if `node_modules/` is missing
- print banner with the URL (`http://localhost:4000`) and the backend
  prerequisite reminder
- exec `npm run dev`
- no trailing `pause` so Ctrl+C closes cleanly

## Conversation summary

- User: *"what is the commands to start admin panel service? just make bat
  file inside cmds folder and i will start service manually with bat file"*
- Naming mirrors the backend script for consistency
  (`start_backend.bat` → `start_admin.bat`).
- The earlier port-pinning task (`-p 4000` in `package.json`) means we don't
  need to pass any port flag from the bat file — it's already baked into the
  npm script.

## Decisions / call-outs

- **Dev mode, not prod.** `npm run dev` runs `next dev -p 4000` which gives
  hot reload of React components. Production mode would need
  `cmds\build_admin.bat` first then `next start -p 4000`. If you want a
  prod runner I'll add `start_admin_prod.bat` separately.
- **No `.env.local` warning** unlike the backend's `.env` warning. The admin
  panel works fine without `.env.local` today — there's no required secret
  for the dev flow (the backend URL is hardcoded to `:3000` via
  `next.config.mjs`'s rewrites). If a future task introduces required env
  vars on the admin side, that warning gets added then.
- **Mentions the backend dependency in the banner.** New devs who run only
  this script will see the admin UI load but every data fetch will fail —
  surfacing the prerequisite up-front saves debugging time.

## How to verify

1. Make sure the backend is running: `cmds\start_backend.bat`.
2. In a second terminal: `cmds\start_admin.bat`.
3. Console prints `▲ Next.js 14.2.5` + `- Local: http://localhost:4000`.
4. Open `http://localhost:4000` in a browser → sign-in page renders.

## User prompt (verbatim)

> what is the commands to start admin panel service? just make bat file
> inside cmds folder and i will start service manually with bat file
