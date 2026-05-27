# Load .lic file still error DioException [unknown]:null Error:type 'List<dynamic>

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-27T04:16:01.434Z

## User

Load .lic file still error

DioException [unknown]:null
Error:type 'List<dynamic> is not a subtype of type 'String?' in type cast

## Assistant

Let me check the error interceptor — the cast failure smells like NestJS validation responses (where `message` is a `List<string>`, not a string):

## Assistant

Found it: line 16 unconditionally casts `body['message'] as String?`, but NestJS validation responses send `message` as `List<string>` (one entry per failed rule). Let me fix the interceptor to handle both shapes, then we'll see the actual validation message:

## Assistant

Now let me check the backend ValidationPipe config and what would actually be rejected here:

## Assistant

That's the smoking gun. The backend has `forbidNonWhitelisted: true`, so any property *not* declared in the DTO is rejected with:

```json
{ "message": ["property platform should not exist"], "statusCode": 400 }
```

That's a **List**, which is exactly what blew up the cast. Two parts to the fix:

1. **Interceptor** (just done) — accept `message` as either String or List.
2. **Backend restart** — the new `platform` field was added to `VerifyLicenseDto` in commit `3dd4f76`, but only takes effect once the running NestJS process picks up the new code. Until then, every request including `platform` gets rejected.

## Assistant

Committed as `359d41c`. To finish this off:

1. **Restart the NestJS backend** so it picks up `1781100000000-users-license-platform` migration + the new `platform` DTO field. From the backend directory:
   ```bat
   npm run migration:run
   ```
   …then restart your `npm run start:dev` (or whatever you use to run it).

2. **Hot-restart the Flutter app** (not just hot-reload — interceptor change is in non-widget code).

3. Tap **Load .lic file** again. With the interceptor fix in place, *any* future validation error will now show you the real reason (e.g. "machineId must be a string"), not a cast crash.
