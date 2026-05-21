# app-specific path means 룡마/가상외국어회화 ?

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-21T13:47:01.925Z

## User

app-specific path means 룡마/가상외국어회화 ?

## Assistant

**No** — those are different things. Let me clarify the terminology:

| Term | Path | Permission needed | Notes |
| --- | --- | --- | --- |
| **Public external storage** | `/sdcard/<anything>/` | `MANAGE_EXTERNAL_STORAGE` on Android 11+ | Where your existing `/sdcard/룡마/가상외국어회화/` config lives. **Already permitted in your manifest.** |
| **App-specific external storage** | `/sdcard/Android/data/<package>/files/` | None | Auto-managed by Android; deleted when the app is uninstalled. Path depends on package name. |

Your `룡마/가상외국어회화/` folder is in the **public** bucket, not app-specific.

Given that, the **cleanest path is to put `.ddp` files inside the folder you already use** — say `/sdcard/룡마/가상외국어회화/datapacks/`. Reasons:

- Same permission you already grant (`MANAGE_EXTERNAL_STORAGE` — the existing config folder access path).
- One folder for admins to navigate to (config + packs together).
- No new "please grant access" UX flow.
- No new `.ddp` folder to teach the admin about.

So my updated recommendation:

```
/sdcard/룡마/가상외국어회화/         ← existing app config (already there)
/sdcard/룡마/가상외국어회화/datapacks/  ← .ddp files dropped here by admin
```

The Flutter side already knows how to navigate to `/sdcard/룡마/가상외국어회화/`; Stage 9 just adds a `datapacks/` subdir scan to the existing first-run setup flow.

Want me to go with this — Stage 9 reads from `/sdcard/룡마/가상외국어회화/datapacks/`?
