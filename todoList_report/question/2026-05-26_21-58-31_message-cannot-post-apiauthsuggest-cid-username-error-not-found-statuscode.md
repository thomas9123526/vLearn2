# {message: Cannot POST /api/auth/suggest-cid-username, error: Not Found, statusCo

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-26T12:58:31.553Z

## User

{message: Cannot POST /api/auth/suggest-cid-username, error: Not Found, statusCode: 404}

## Assistant

The 404 is from a **remote backend, not yours** — the Windows app's `app_config.json` has `baseurl=http://172.86.121.43:80/vfls`, and that server doesn't have the route yet.

The route exists locally — `backend/src/auth/auth.controller.ts:72` defines `@Public()` `@Post('suggest-cid-username')`, added in commit `3f42bf6` ("feat: suggest available cid_usernames when username is already taken"). Local source is correct. The remote at `172.86.121.43` is just behind on commits.

Two ways to unblock:

**A. Redeploy the backend to `172.86.121.43`** — push your `backend/` directory (or the built `dist/`) up and restart. Whatever the deploy process is for that box.

**B. Point the Windows app at a local backend** — edit `flutter_app/build/windows/x64/runner/Debug/app_config.json`:
```json
{"baseurl":"http://localhost:3000/api","reqTout":30,"tSync":60,"dev":"dev"}
```
…then in another terminal:
```bat
cd backend
npm run start:dev
```
Restart the Flutter app. The new route will resolve.

(Note: `baseurl` ends in `/vfls` on the remote vs `/api` locally — the remote has an nginx prefix that maps `/vfls` to the backend's `/api`. If you keep the remote URL after redeploy, no client change needed.)

Want me to also probe whether anything else in the local source is missing from the remote, while you're staging the deploy?
