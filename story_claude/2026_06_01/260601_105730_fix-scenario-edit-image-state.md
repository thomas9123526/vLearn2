# Conversation - Fix scenario edit image state

| Field | Value |
|---|---|
| Saved | 2026-06-01 10:57:30 |
| Commit | Fix undefined setLogoImageFile in admin scenario edit page |
| Project | C:\project\vLearn2 |

---

## User

setLogoImageFile is not defined shows when i edit scenarios on http://localhost:4101/vAdmin/scenarios/2121c341-1f94-4c11-8396-ce26a5b147c8/

## Assistant

Found the broken legacy `setLogoImageFile` cleanup call in `admin_panel/src/app/(dashboard)/scenarios/[id]/page.tsx` and removed it, leaving only the current image state reset methods.

---

## Prompt

setLogoImageFile is not defined shows when i edit scenarios on http://localhost:4101/vAdmin/scenarios/2121c341-1f94-4c11-8396-ce26a5b147c8/
