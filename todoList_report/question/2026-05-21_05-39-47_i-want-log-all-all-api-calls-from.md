# I want log all all api calls from client side including auth info it has in its 

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-20T20:39:47.503Z

## User

I want log all all api calls from client side including auth info it has in its header for debugging

## Assistant

Adding a debug-only logging interceptor that prints method/URL, Authorization header, body, and response status for every request.

## Assistant

Now wire it into the Dio chain after `AuthInterceptor` (so the Bearer header is already attached when we log) and before `ErrorInterceptor`.

## Assistant

Clean. Commit + log.

## Assistant

Committed as `a975798`.

**What you'll see in the debug console** for every Dio request:

```
→ POST  https://.../auth/signin
   Authorization: (none)
   body: {cidUsername: sym1991123, password: aaAA11!!}
← 200 POST  https://.../auth/signin

→ GET   https://.../users/profile
   Authorization: Bearer eyJhbGciOiJIUzI1NiIs...<full token>
← 200 GET   https://.../users/profile

→ GET   https://.../app-config
   Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
✗ 401 GET   https://.../app-config
   response body: {message: Unauthorized, statusCode: 401}
```

**Key points:**
- Gated on `kDebugMode` — **nothing logs in release builds**, the bodies are tree-shaken out by the Dart compiler.
- Sits **after** `AuthInterceptor`, so the Bearer header you see is exactly what hits the wire.
- Full token, no redaction — debug-only, makes curl-repros easy.
- Body is logged as-is (including password) so you can finally see whether the signin payload matches what you typed. Use this to confirm the actual password being sent matches what's stored.

Hot-restart the Flutter app for the new interceptor to register, then try signin again. The console output will tell you exactly what's on the wire.
