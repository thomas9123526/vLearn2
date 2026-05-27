# {"message":"Cannot GET /api/auth/suggest-cid-username","error":"Not Found","stat

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-26T13:30:52.166Z

## User

{"message":"Cannot GET /api/auth/suggest-cid-username","error":"Not Found","statusCode":404}

## Assistant

The error says "Cannot GET" — but the route is `@Post`. Either the Flutter app is sending GET (bug) or you opened the URL in a browser to test (browsers send GET → expected 404). Let me confirm what the Flutter code is sending.

## Assistant

Flutter is definitely sending POST (`_dio.post` at [auth_api.dart:73](flutter_app/lib/core/api/auth_api.dart#L73)). Let me confirm whether the local backend is now up.

## Assistant

The `"Cannot GET"` message is NestJS's default 404 when the HTTP method doesn't match — and the route is `@Post('suggest-cid-username')`, not `@Get`. So whoever made that request used **GET**, not POST.

Two scenarios:

**Scenario A — you opened the URL in a browser to test.**
That's the most likely explanation: browsers send GET when you paste a URL into the address bar. The route only accepts POST, so you get this 404. It's not actually a bug — the backend is reachable, the route exists, you just hit it with the wrong verb.

To test the endpoint from outside Flutter, use a POST instead:
```powershell
$body = @{ displayName = '신영명'; birthday = '2012-06-07' } | ConvertTo-Json -Compress
Invoke-WebRequest -Uri 'http://localhost:5101/api/auth/suggest-cid-username' -Method POST -Body $body -ContentType 'application/json; charset=utf-8'
```
Expected: `200 OK` with `{"suggestions":["sym121267","sym67",...]}`.

**Scenario B — the Flutter app itself sent GET.**
Highly unlikely — `auth_api.dart:73` calls `_dio.post`. But to be sure, when you click Suggest in the running app, check the backend terminal. You should see:
```
[Nest] LOG  [HTTP] POST /api/auth/suggest-cid-username 200
```
If it shows `GET` instead, something is rewriting the verb (interceptor, proxy, weird Dio config).

**Quick sanity check from where I am**: `Get-NetTCPConnection -LocalPort 5101 -State Listen` returned nothing, so the local backend currently has no listener. If you ran `npm run start:dev` and got the 404 above, that means the backend was up briefly (long enough to answer a request) but isn't right now — possibly it crashed on startup or you stopped it. Tail the start-up output for errors (migration failure, port already in use, missing env var) and report what you see.
