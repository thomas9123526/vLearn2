# http://localhost:5101/api/admin/stats 401 (Unauthorized) in (dashboard)/page.tsx

Session: `2e7ba26d-029b-44a8-b16a-cf6ab073a185`
Saved: 2026-06-01T03:28:24.276Z

## User

http://localhost:5101/api/admin/stats 401 (Unauthorized) in (dashboard)/page.tsx

## Assistant

I see a 401 auth error from the admin stats endpoint. Let me check what's happening in the dashboard and the backend.

## Assistant

Let me find the admin panel and dashboard code:

## Assistant

The issue is likely that there's no valid access token in sessionStorage. The dashboard calls `/admin/stats` which requires JWT authentication (line 8 in the controller). Let me check if there's a login flow:

## Assistant

Check if you're logged in. The dashboard requires a valid JWT token from signing in at `/admin` (signin page). Here's the issue:

1. **No token**: If you haven't logged in, go to the signin page and authenticate with admin credentials. The token is stored in `sessionStorage` and sent with the `/admin/stats` request.

2. **Token expired/invalid**: The API will try to refresh using the refresh token. If that fails, tokens are cleared and you'll need to sign in again.

3. **Admin permissions**: The endpoint requires `role` to be `'admin'` or `'superadmin'` (checked in signin page line 45).

Are you logged in? If you're seeing this error in the browser console but the dashboard still renders, try:
- Open DevTools → Application → Session Storage
- Check if `vlearn2.admin.access` and `vlearn2.admin.refresh` keys exist
- If not, navigate to `/signin` and log in
