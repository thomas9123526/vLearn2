# Conversation - Fix Users Actions Dropdown Clipped by Card overflow-hidden

| Field | Value |
|---|---|
| Saved | 2026-06-01 18:31:13 |
| Commit | fix: render Actions dropdown via portal to escape Card overflow-hidden clipping |
| Project | C:\project\vLearn2 |

---

## User

(screenshot of admin panel /vAdmin/users/ with Actions dropdown open, red circle around clipped area)
I can see more actions indicated in png

## Assistant

Misunderstood initially. Clarified:

## User

You misunderstand my request. The Actions dropdown is working, I know. But the dropdown list is hidden by some others so I can choose the last item for dropdown list. this is ui problem on admin panel for this link http://localhost:4101/vAdmin/users/

## Assistant

Root cause: `<Card className="overflow-hidden">` wraps the `<table>`, causing the absolute-positioned dropdown to be clipped at the card boundary. Bottom items (Block/Restore/Reset password) were invisible when the dropdown opened near the bottom of the card.

Fix: switched `ActionsMenu` to render the dropdown via `createPortal(…, document.body)` with `position: fixed` coordinates taken from `btnRef.current.getBoundingClientRect()`. The menu now escapes all parent overflow constraints.

Changed file: `admin_panel/src/app/(dashboard)/users/page.tsx`
- Added `import { createPortal } from 'react-dom'`
- Added `btnRef` and `pos` state to track button position
- `handleToggle` captures `getBoundingClientRect()` before opening
- Dropdown rendered at `document.body` level with `position: fixed` + `zIndex: 9999`

---

## Prompt

You misunderstand my request. The Actions dropdown is working, I know. But the dropdown list is hidden by some others so I can choose the last item for dropdown list. this is ui problem on admin panel for this link http://localhost:4101/vAdmin/users/
