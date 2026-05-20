# 260520_2200 — Fix admin-panel signup network error when accessed from another PC

## User prompt (verbatim)

> there's network error when signup admin panel on the another computer

## Diagnosis

When the Next.js admin panel is served from this machine and opened in a
browser on a **different** PC on the LAN, the signup POST to
`/admin/auth/signup` failed with a network error.

Root cause: the browser bundle's API base URL was baked to `localhost`.

* [admin_panel/.env.local](admin_panel/.env.local) had
  `NEXT_PUBLIC_API_BASE_URL=http://localhost:5101/api`. That string ships
  into the browser; `localhost` then resolves to the *other* PC, where
  nothing is listening on port 5101.
* [backend/.env](backend/.env) `CORS_ORIGINS` only listed
  `http://localhost:4101` — even with the URL fixed, the backend would
  reject requests whose `Origin` is `http://192.168.135.30:4101`.
* [admin_panel/next.config.mjs](admin_panel/next.config.mjs)
  `experimental.serverActions.allowedOrigins` likewise needed the LAN
  origin (otherwise any future server action POST is rejected).
* [cmds/stop.txt](cmds/stop.txt) instructed `npx next dev -p 4101` which
  binds to `127.0.0.1` only; the other PC can't reach it.

This machine's LAN IPv4 is **192.168.135.30** (Ethernet adapter, from
`Get-NetIPAddress`).

## Changes

* [admin_panel/.env.local](admin_panel/.env.local) — point both
  `NEXT_PUBLIC_API_BASE_URL` and `BACKEND_BASE_URL` at
  `http://192.168.135.30:5101`.
* [backend/.env](backend/.env) — append
  `http://192.168.135.30:4101` to `CORS_ORIGINS`.
* [admin_panel/next.config.mjs](admin_panel/next.config.mjs) — add
  `192.168.135.30:4101` to `experimental.serverActions.allowedOrigins`.
* [cmds/stop.txt](cmds/stop.txt) — change the dev-server launch to
  `npx next dev -p 4101 -H 0.0.0.0` so it accepts LAN connections.

## How to verify

1. Restart the backend on this PC (port 5101) — `.env` was changed so
   the running process must reload. Use
   `backend\stop_start_service.bat` from [cmds/stop.txt](cmds/stop.txt).
2. Restart the admin panel:
   `cd c:\project\vLearn2\admin_panel && npx next dev -p 4101 -H 0.0.0.0`
   (the `-H 0.0.0.0` is required so the *other* PC can reach Next).
3. On the other computer, open
   `http://192.168.135.30:4101/vAdmin/signup/` (the basePath is
   `/vAdmin` — see next.config.mjs:5).
4. The signup POST should now succeed instead of failing with
   "Network error".

## Notes / caveats

* If this PC's LAN IP changes (DHCP lease), the three pinned values
  above all need to be re-edited.
* Firewall: Windows Defender may need to allow inbound TCP 4101 and
  5101 the first time the other PC connects. If signup still hangs
  after the changes above, that's the next thing to check.
* The basePath `/vAdmin` is preserved — the other computer must include
  it in the URL.
