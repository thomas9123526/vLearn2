# /root/.pm2/logs/vfls-admin-error.log last 30 lines: 0|vfls-adm |     at async in

Session: `8d92f8df-87dc-4445-9439-b132351a0dcd`
Saved: 2026-06-01T16:28:36.321Z

## User

/root/.pm2/logs/vfls-admin-error.log last 30 lines:
0|vfls-adm |     at async initialize (/root/vfls/vLearn2/admin_panel/node_modules/next/dist/server/lib/router-server.js:61:23)
0|vfls-adm |     at async Server.<anonymous> (/root/vfls/vLearn2/admin_panel/node_modules/next/dist/server/lib/start-server.js:249:36)
0|vfls-adm | Error: Could not find a production build in the '.next' directory. Try building your app with 'next build' before starting the production server. https://nextjs.org/docs/messages/production-start-no-build-id
0|vfls-adm |     at setupFsCheck (/root/vfls/vLearn2/admin_panel/node_modules/next/dist/server/lib/router-utils/filesystem.js:151:19)
0|vfls-adm |     at async initialize (/root/vfls/vLearn2/admin_panel/node_modules/next/dist/server/lib/router-server.js:61:23)
0|vfls-adm |     at async Server.<anonymous> (/root/vfls/vLearn2/admin_panel/node_modules/next/dist/server/lib/start-server.js:249:36)
0|vfls-adm | Error: Could not find a production build in the '.next' directory. Try building your app with 'next build' before starting the production server. https://nextjs.org/docs/messages/production-start-no-build-id
0|vfls-adm |     at setupFsCheck (/root/vfls/vLearn2/admin_panel/node_modules/next/dist/server/lib/router-utils/filesystem.js:151:19)
0|vfls-adm |     at async initialize (/root/vfls/vLearn2/admin_panel/node_modules/next/dist/server/lib/router-server.js:61:23)
0|vfls-adm |     at async Server.<anonymous> (/root/vfls/vLearn2/admin_panel/node_modules/next/dist/server/lib/start-server.js:249:36)
0|vfls-adm | Error: Could not find a production build in the '.next' directory. Try building your app with 'next build' before starting the production server. https://nextjs.org/docs/messages/production-start-no-build-id
0|vfls-adm |     at setupFsCheck (/root/vfls/vLearn2/admin_panel/node_modules/next/dist/server/lib/router-utils/filesystem.js:151:19)
0|vfls-adm |     at async initialize (/root/vfls/vLearn2/admin_panel/node_modules/next/dist/server/lib/router-server.js:61:23)
0|vfls-adm |     at async Server.<anonymous> (/root/vfls/vLearn2/admin_panel/node_modules/next/dist/server/lib/start-server.js:249:36)
0|vfls-adm | Error: Could not find a production build in the '.next' directory. Try building your app with 'next build' before starting the production server. https://nextjs.org/docs/messages/production-start-no-build-id
0|vfls-adm |     at setupFsCheck (/root/vfls/vLearn2/admin_panel/node_modules/next/dist/server/lib/router-utils/filesystem.js:151:19)
0|vfls-adm |     at async initialize (/root/vfls/vLearn2/admin_panel/node_modules/next/dist/server/lib/router-server.js:61:23)
0|vfls-adm |     at async Server.<anonymous> (/root/vfls/vLearn2/admin_panel/node_modules/next/dist/server/lib/start-server.js:249:36)
0|vfls-adm | Error: Could not find a production build in the '.next' directory. Try building your app with 'next build' before starting the production server. https://nextjs.org/docs/messages/production-start-no-build-id
0|vfls-adm |     at setupFsCheck (/root/vfls/vLearn2/admin_panel/node_modules/next/dist/server/lib/router-utils/filesystem.js:151:19)
0|vfls-adm |     at async initialize (/root/vfls/vLearn2/admin_panel/node_modules/next/dist/server/lib/router-server.js:61:23)
0|vfls-adm |     at async Server.<anonymous> (/root/vfls/vLearn2/admin_panel/node_modules/next/dist/server/lib/start-server.js:249:36)
0|vfls-adm | Error: Could not find a production build in the '.next' directory. Try building your app with 'next build' before starting the production server. https://nextjs.org/docs/messages/production-start-no-build-id
0|vfls-adm |     at setupFsCheck (/root/vfls/vLearn2/admin_panel/node_modules/next/dist/server/lib/router-utils/filesystem.js:151:19)
0|vfls-adm |     at async initialize (/root/vfls/vLearn2/admin_panel/node_modules/next/dist/server/lib/router-server.js:61:23)
0|vfls-adm |     at async Server.<anonymous> (/root/vfls/vLearn2/admin_panel/node_modules/next/dist/server/lib/start-server.js:249:36)
0|vfls-adm | Error: Could not find a production build in the '.next' directory. Try building your app with 'next build' before starting the production server. https://nextjs.org/docs/messages/production-start-no-build-id
0|vfls-adm |     at setupFsCheck (/root/vfls/vLearn2/admin_panel/node_modules/next/dist/server/lib/router-utils/filesystem.js:151:19)
0|vfls-adm |     at async initialize (/root/vfls/vLearn2/admin_panel/node_modules/next/dist/server/lib/router-server.js:61:23)
0|vfls-adm |     at async Server.<anonymous> (/root/vfls/vLearn2/admin_panel/node_modules/next/dist/server/lib/start-server.js:249:36)

## Assistant

The admin panel is crashing because Next.js can't find a production build — `next build` was never run on the server. I'll check if there's a deploy script first.

## Assistant

There's already a `rebuild_admin.sh` script on the server for exactly this. You need to SSH into the server and run it:

```bash
ssh root@172.86.121.43 "bash /root/vfls/vLearn2/cmds/rebuild_admin.sh"
```

This script will:
1. `cd` into `/root/vfls/vLearn2/admin_panel`
2. Run `npm run build` to create the `.next` production bundle
3. Restart the `vfls-admin` PM2 process
4. Poll `http://127.0.0.1:4100/vAdmin/` for up to 30 s and confirm HTTP 200 through nginx

The build takes a few minutes. Run it from your local machine (or wherever you have the SSH key) and it will report success or failure.
