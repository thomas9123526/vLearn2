# in scenario edit screen on admin panel on browser (http://localhost:4101/vAdmin/

Session: `d506161a-a027-47af-a3ba-75104b012999`
Saved: 2026-06-01T04:43:55.185Z

## User

in scenario edit screen on admin panel on browser (http://localhost:4101/vAdmin/scenarios)
I can't see preview image. the error logs on chrome are like this.

api.ts:67 
 GET http://localhost:5101/api/admin/scenarios/2121c341-1f94-4c11-8396-ce26a5b147c8 401 (Unauthorized)
hot-reloader-client.js:187 [Fast Refresh] rebuilding
:5101/uploads/scenar…-ce26a5b147c8.png:1 
 GET http://localhost:5101/uploads/scenarios/2121c341-1f94-4c11-8396-ce26a5b147c8.png net::ERR_BLOCKED_BY_RESPONSE.NotSameOrigin 304 (Not Modified)
:5101/uploads/scenar…c8.background.png:1 
 GET http://localhost:5101/uploads/scenarios/2121c341-1f94-4c11-8396-ce26a5b147c8.background.png net::ERR_BLOCKED_BY_RESPONSE.NotSameOrigin 304 (Not Modified)
hot-reloader-client.js:44 [Fast Refresh] done in 704ms
2121c341-1f94-4c11-8…c8.background.png:1 
 GET http://localhost:4101/uploads/scenarios/2121c341-1f94-4c11-8396-ce26a5b147c8.background.png 404 (Not Found)
2121c341-1f94-4c11-8…-ce26a5b147c8.png:1 
 GET http://localhost:4101/uploads/scenarios/2121c341-1f94-4c11-8396-ce26a5b147c8.png 404 (Not Found)

## Assistant

Two separate issues here: a 401 on the API call, and the image CORS block (`NotSameOrigin`) causing the browser to retry on the wrong port. Let me look at the relevant code.

## Assistant

Clear picture now. There are two distinct issues:

1. **Preview section uses raw `scenario.image_url`** (relative path `/uploads/...`) instead of `resolveUploadUrl()` — browser loads from `localhost:4101` which 404s
2. **`ERR_BLOCKED_BY_RESPONSE.NotSameOrigin`** — this is a `Cross-Origin-Resource-Policy` (CORP) issue, not just CORS. Even with CORS headers, the browser blocks cross-origin image loads unless the response includes `Cross-Origin-Resource-Policy: cross-origin`

Let me fix both.

## Assistant

Now I can see exactly what needs fixing. Let me also check where `resolveUploadUrl` is defined in the page component.

## Assistant

Both fixes are clear. Making them now:

**Fix 1**: Preview section uses raw URLs — wrap with `resolveUploadUrl()`

**Fix 2**: Backend CORP header — add `Cross-Origin-Resource-Policy: cross-origin` to the uploads middleware

## Assistant

Now commit and save the story.

## Assistant

Two fixes committed:

1. **[page.tsx:316,326](admin_panel/src/app/(dashboard)/scenarios/[id]/page.tsx#L316)** — preview images now go through `resolveUploadUrl()`, so `/uploads/...` becomes `http://localhost:5101/uploads/...` instead of resolving against `localhost:4101`.

2. **[main.ts:93](backend/src/main.ts#L93)** — added `Cross-Origin-Resource-Policy: cross-origin` response header on the `/uploads/` route. The `NotSameOrigin` error was Helmet's default CORP policy blocking cross-origin image loads — unrelated to CORS headers.

Restart the NestJS backend to pick up the header change, then the previews should load.
