# Conversation - Fix scenario preview image CORP and URL resolution

| Field | Value |
|---|---|
| Saved | 2026-06-01 13:43:23 |
| Commit | Fix scenario preview image CORP header and URL resolution |
| Project | C:\project\vLearn2 |

---

## User

in scenario edit screen on admin panel on browser (http://localhost:4101/vAdmin/scenarios)
I can't see preview image. the error logs on chrome are like this.

```
GET http://localhost:5101/api/admin/scenarios/2121c341-1f94-4c11-8396-ce26a5b147c8 401 (Unauthorized)
GET http://localhost:5101/uploads/scenarios/2121c341-...ce26a5b147c8.png net::ERR_BLOCKED_BY_RESPONSE.NotSameOrigin 304
GET http://localhost:5101/uploads/scenarios/2121c341-...ce26a5b147c8.background.png net::ERR_BLOCKED_BY_RESPONSE.NotSameOrigin 304
GET http://localhost:4101/uploads/scenarios/2121c341-...ce26a5b147c8.background.png 404 (Not Found)
GET http://localhost:4101/uploads/scenarios/2121c341-...ce26a5b147c8.png 404 (Not Found)
```

## Assistant

Two issues found:

1. **Preview section used raw `scenario.image_url` / `scenario.background_image_url`** (relative paths like `/uploads/...`) without calling `resolveUploadUrl()`. The browser resolved these against the Next.js origin (`localhost:4101`) which returns 404.

2. **`ERR_BLOCKED_BY_RESPONSE.NotSameOrigin`** is a `Cross-Origin-Resource-Policy` (CORP) issue — distinct from CORS. Helmet sets `Cross-Origin-Resource-Policy: same-origin` by default, blocking cross-origin image loads from `localhost:5101` into the admin panel on `localhost:4101`. Adding `Cross-Origin-Resource-Policy: cross-origin` to the `/uploads/` middleware fixes this.

**Fixes applied:**

- `admin_panel/src/app/(dashboard)/scenarios/[id]/page.tsx` lines 316, 326 — wrapped image `src` with `resolveUploadUrl()` so relative paths become absolute `http://localhost:5101/uploads/...` URLs.
- `backend/src/main.ts` — added response middleware after the CORS middleware for `/uploads/` to set `Cross-Origin-Resource-Policy: cross-origin`.

---

## Prompt

in scenario edit screen on admin panel on browser (http://localhost:4101/vAdmin/scenarios)
I can't see preview image. the error logs on chrome are like this.
