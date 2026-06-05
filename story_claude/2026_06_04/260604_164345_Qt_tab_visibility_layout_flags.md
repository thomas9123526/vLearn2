# Conversation - Qt tab visibility via Layout flags

| Field | Value |
|---|---|
| Saved | 2026-06-04 16:43:45 |
| Commit | auto: gate Qt sidebar tabs by tabs.* Layout flags from /app-config |
| Project | C:\project\vLearn2 |

---

## User

I put logic to control tab visibility by checking Layout flags. So if i uncheck
Progress tab (tabs.progress — "Show Progress tab in the bottom nav bar / sidebar")
the progress tab is disappeared.

## Assistant

Matched the Flutter behavior. The Flutter app wraps each nav item in
`LayoutVisibility(configKey: 'tabs.x')`, which reads `layoutConfigProvider`:
flags come from `GET /api/app-config` → `{ version, flags: { "tabs.progress": bool,
... } }`, resolved as "visible unless the flag is explicitly false" (fallback
true). The endpoint requires a JWT.

Implemented in the Qt shell:
- ApiClient.getAppConfig() → GET /app-config (auth).
- After login, MainShell fetches app-config and calls applyTabFlags(flags):
  for each of tabs.home/scenarios/history/progress/settings, hide the nav button
  when the flag is present and false (default visible). If the current page was
  just hidden, fall back to the first visible tab.

Builds clean. Verified the live endpoint shape (`{version, flags}`, 401 without
auth — the app sends the token at runtime).

---

## Prompt

I put logic to control tab visibility by checking Layout flags. So if i uncheck
Progress tab (tabs.progress) the progress tab is disappeared.
