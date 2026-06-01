# Conversation - Downgrade Node to 18 engines nvmrc

| Field | Value |
|---|---|
| Saved | 2026-06-02 02:37:18 |
| Commit | auto: pin Node.js to 18.20.8 via engines field and .nvmrc in backend and admin_panel |
| Project | C:\project\vLearn2 |

---

## User

I want downgrade node version of the backend and admin_panel from 22 to 18.20.8. I already installed node v18.20.8

## Assistant

Added `"engines": { "node": ">=18.20.8 <19 || >=20" }` to both `backend/package.json` and
`admin_panel/package.json`, and created `.nvmrc` with `18.20.8` in both directories.

The engines range allows Node 18.20.8+ and 20+ (skips the odd 19.x release), so CI or future
upgrades to Node 20 LTS still pass the engines check.

---

## Prompt

I want downgrade node version of the backend and admin_panel from 22 to 18.20.8. I already installed node v18.20.8
