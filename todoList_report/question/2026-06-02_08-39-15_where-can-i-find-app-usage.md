# where can i find app usage?

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-01T23:39:15.335Z

## User

where can i find app usage?

## Assistant

Two places:

**1. Admin panel UI** — `http://172.86.121.43/vAdmin/`
Log in as admin and look for the dashboard/stats section. It shows:
- Total users, active users (last 30 days), total sessions, published scenarios

**2. Direct API endpoints** (also accessible via Swagger at `/vfls/docs`):

| What | Endpoint |
|---|---|
| Dashboard counters | `GET /api/admin/stats` |
| Sessions + network bytes by platform | `GET /api/admin/stats/usage` |
| User feedback / bug reports | `GET /api/admin/stats/reports` |
| Filter reports by type | `GET /api/admin/stats/reports?type=feedback` |

All require an admin JWT bearer token. The Swagger UI at `http://172.86.121.43/vfls/docs` lets you try them directly after pasting your token with the Authorize button.
