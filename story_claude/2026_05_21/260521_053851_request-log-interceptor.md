# Add debug-only RequestLogInterceptor

## What this task did

Added `flutter_app/lib/core/api/interceptors/request_log_interceptor.dart`
and wired it into the Dio chain in
`flutter_app/lib/core/api/api_client.dart`. For every outgoing
request, response, and error it prints a one-line trace to the
console:

```
→ POST  https://api.../auth/signin
   Authorization: (none)            ← or "Bearer eyJhbGciOi..."
   body: {cidUsername: sym1991123, password: aaAA11!!}
← 200 POST  https://api.../auth/signin

→ GET   https://api.../users/profile
   Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
← 200 GET   https://api.../users/profile

→ GET   https://api.../app-config
   Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
✗ 401 GET   https://api.../app-config
   response body: {message: "Unauthorized", statusCode: 401}
```

All output is gated on `kDebugMode` from `package:flutter/foundation.dart`,
so the interceptor is a no-op in release builds — nothing logs, no
sensitive headers leak.

Placement in the chain matters and is intentional:

```dart
dio.interceptors.add(CompressionInterceptor(ref));     // adds Accept-Encoding
dio.interceptors.add(AuthInterceptor(...));            // adds Bearer header
dio.interceptors.add(RequestLogInterceptor());         // <-- now logs final headers
dio.interceptors.add(ErrorInterceptor());              // wraps DioException → ApiException
```

Logging after `AuthInterceptor` means the Bearer header is already
attached when we print, so you see exactly what hits the wire.

## Conversation summary

- User asked to log all API calls including auth header for
  debugging.
- Surveyed the existing interceptor chain (compression → auth →
  error) and added a new logging interceptor after auth so the
  Bearer header is visible at log time.
- Gated everything on `kDebugMode` so release builds stay quiet.
- Verified the analyzer is clean on both touched files.

## Decisions / call-outs

- **`kDebugMode` gate, not a runtime flag.** Logging auth bearers is
  fine for the developer console but should not ship. `kDebugMode`
  is a compile-time constant, so the Dart compiler tree-shakes the
  whole body out of release builds.
- **No redaction on bodies.** The user is debugging auth flows
  (passwords vs hash mismatch). If we redacted `password` we'd lose
  the signal. Debug-only, so the trade-off is acceptable.
- **Full Bearer token, not a prefix.** Easier to copy-paste into a
  curl repro when triaging. Again, debug-only.
- **`debugPrint`, not `developer.log`.** `debugPrint` flushes to the
  IDE console reliably on Windows and is the established pattern
  elsewhere in this codebase (e.g.,
  `polite_error.dart::logRawError`).
- **No-op interceptor instances are cheap.** Even though
  `kDebugMode` is `false` in release, the interceptor still gets
  added to the chain and its empty methods called per request.
  That's a constant-time no-op; not worth conditionally adding the
  interceptor itself.

## User prompt (verbatim)

> I want log all all api calls from client side including auth info it has in its header for debugging
