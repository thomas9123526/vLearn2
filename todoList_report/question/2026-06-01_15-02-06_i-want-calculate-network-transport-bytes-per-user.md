# I want calculate network transport bytes per user. On Users tab on the admin pan

Session: `d506161a-a027-47af-a3ba-75104b012999`
Saved: 2026-06-01T06:02:06.777Z

## User

I want calculate network transport bytes per user.
On Users tab on the admin panel, http://localhost:4101/vAdmin/users/, I want put 'reset password' and 'block' action in one button likst 'Actions' per user. when admin click 'Actions' then drop downlist shows for 'reset password' and 'block'.
I want put one more action for view details.
If click view details, I want show full information and plus 4 fields.

Byte Uploaded(Android): the bytes transported from the android app.
Byte Uploaded(Windows): the bytes transported from the windows application.
Byte Download(Android): the bytes transported from the backend api to the android application.
Byte Download(Windows): the bytes transported from the backend api to the windows application.

## Assistant

This touches three codebases. Let me explore the current state of all three before writing any code.

## Assistant

Good picture. Here's the plan before writing code:

- **Backend** — new `vl_user_network_stats` table, a NestJS interceptor that counts request/response bytes per user + platform, update `GET /admin/users/:id` to include stats
- **Flutter** — add `X-Platform` header to Dio so the interceptor knows which platform
- **Admin panel** — collapse the three per-row buttons into an "Actions" dropdown + add "View Details" that opens a detail sheet with the 4 byte fields

Let me read the exact files I'll touch before writing anything.

## Assistant

Let me check the app module structure and the existing entity registration pattern.

## Assistant

`synchronize: false` — need a migration. Let me check the migration pattern.

## Assistant

I have the full picture. Let me implement everything in order: backend → Flutter → admin panel.

**Backend:** migration + entity + service + interceptor + module
**Flutter:** add `X-Platform` header
**Admin panel:** Actions dropdown + View Details modal

## Assistant

Now create the service, interceptor, and module.

## Assistant

Register in AppModule and update the admin users controller.

## Assistant

Now update the admin users controller `GET /:id` to include network stats and inject `NetworkStatsService`.

## Assistant

`NetworkStatsService` is `@Global()`, so no need to add it to the admin module imports. Now add `X-Platform` to the Flutter client.

## Assistant

Now rewrite the admin panel users page — Actions dropdown + View Details modal.

## Assistant

Now commit everything with the story file.

## Assistant

Done. Here's a summary of everything:

**Run the migration first** (backend):
```bash
npm run migration:run
```
This creates the `vl_user_network_stats` table.

---

**How bytes are tracked:**

1. Flutter now sends `X-Platform: android` or `X-Platform: windows` on every request ([api_client.dart](flutter_app/lib/core/api/api_client.dart))
2. The `NetworkStatsInterceptor` ([network-stats.interceptor.ts](backend/src/network-stats/network-stats.interceptor.ts)) fires globally on every route — reads `Content-Length` for upload bytes, serializes the response body for download bytes, then calls the service fire-and-forget (never delays the response)
3. `NetworkStatsService.addBytes()` does an atomic `INSERT … ON CONFLICT DO UPDATE` to accumulate totals per user+platform

**Admin panel changes** ([users/page.tsx](admin_panel/src/app/(dashboard)/users/page.tsx)):
- Each row now has a single **Actions** button that opens a dropdown: View details / Reset password / Block / Restore
- **View Details** opens a modal with 5 sections — Identity, Progress, Preferences, License, and **Network traffic** showing the 4 byte fields formatted as B/KB/MB/GB
