# I want see user license status. If admin check "Enable License", users tabs shou

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-27T04:25:12.535Z

## User

I want see user license status.
If admin check "Enable License", users tabs should show the license status per user.
If admin uncheck "Enable License", license status information will be gone

## Assistant

Let me check what's on the existing license admin page and the app-config plumbing:

## Assistant

The `license.enabled` toggle and admin License page already exist — I just need to make the Users page react to it. Plan: query `license.enabled` and conditionally show the Platform + License columns:

## Assistant

Clean. Committing:

## Assistant

Done. Committed as `3c82f7e`.

**How it behaves now**:
- Open **License** in the admin panel — the existing "Enable License" checkbox controls `license.enabled` in `vl_app_config`.
- **Enabled** → Users tab grows two columns: **Platform** and **License**.
- **Disabled** → Both columns vanish from the table; admin sees a clean, non-license view.

**License-column states**:
| `license_valid_until` | Pill | Color |
| --- | --- | --- |
| `null` (never activated) | "Not activated" | muted |
| in the past | "Expired" | red |
| > 10,000 days out (~100 yr cert) | "Permanent" | violet |
| ≤ 7 days remaining | "Active · 3d" | amber (warning) |
| any other future date | "Active · 234d" | green |

Toggle on the License page → reload the Users page (or just wait for the next React Query refetch) → columns appear/disappear. The empty-state row's `colspan` adjusts too so the "No users." cell stays aligned.
