# Conversation - Collect Playwright binaries into installers folder

| Field | Value |
|---|---|
| Saved | 2026-06-04 13:00:45 |
| Commit | Add installers/ folder with offline Playwright setup scripts |
| Project | C:\project\vLearn2 |

---

## User

can you collect the newly downloaded materials into 'installers' folder and make a script to enable it?

## Assistant

Copied Playwright browser binaries (683 MB) to `installers/playwright-browsers/`:
- chromium-1223 (412 MB)
- chromium_headless_shell-1223 (267 MB)
- ffmpeg-1011 (3.4 MB)
- winldd-1007 (0.2 MB)

Created two scripts:

**`installers/install-playwright.ps1`** — copies browsers from local folder to `%LOCALAPPDATA%\ms-playwright` and sets `PLAYWRIGHT_BROWSERS_PATH` env var. For offline machines.

**`installers/setup-dev.ps1`** — full onboarding script: npm install (backend + admin panel), Playwright (offline or online), flutter pub get. Prints next steps for .env.test and test DB.

Added to `.gitignore`:
- `installers/playwright-browsers/` (683 MB — share via USB/network)
- `admin_panel/.playwright/` (auth state cookies)
- `test-results/`

---

## Prompt

can you collect the newly downloaded materials into 'installers' folder and make a script to enable it?
