# {"message":"Cannot GET /api/auth/suggest-cid-username","error":"Not Found","stat

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-26T13:32:49.100Z

## User

{"message":"Cannot GET /api/auth/suggest-cid-username","error":"Not Found","statusCode":404}

## Assistant

Let me actually verify whether the Flutter app is somehow sending GET — check the interceptor chain.

## Assistant

I need to know where the 404 is coming from. Let me check if the local backend is even running right now.

## Assistant

Backend is up and the POST works perfectly. Got `200 OK` back with **6 suggestions**:

```json
{"suggestions":["sym12607","sym607","sym120607","sym07612","sym126","sym60712"]}
```

So your `404 "Cannot GET"` is from **a GET request**, not the Flutter app. The Flutter `_dio.post` works — I just proved it from here with the same payload. Three places that could be issuing GET:

1. **A browser tab/address bar** — pasted the URL → browser sends GET → 404
2. **Postman / Insomnia / VS Code REST Client** with the method dropdown left on GET
3. **`curl <url>`** (no `-X POST`) — defaults to GET

The Flutter app sends POST via `_dio.post`. The route is `@Post('suggest-cid-username')`. There is no GET handler — that's intentional, because the request carries a JSON body.

**To confirm the app works**: with the backend still running, click the wand icon in the running Flutter window. You should see 6 chips appear under the CID Username field: `sym12607`, `sym607`, `sym120607`, `sym07612`, `sym126`, `sym60712`. If you don't, look at the backend terminal — every request gets logged. The line should read `POST /api/auth/suggest-cid-username 200`.

If you're trying to verify the endpoint *outside* the Flutter app, use:

```powershell
$body = '{"displayName":"신영명","birthday":"2012-06-07"}'
$bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
Invoke-WebRequest -Uri 'http://localhost:5101/api/auth/suggest-cid-username' -Method POST -Body $bytes -ContentType 'application/json; charset=utf-8'
```

Or in Swagger UI at `http://localhost:5101/api/docs` (if it's enabled) — find the route and click "Try it out", which sends the correct method.
