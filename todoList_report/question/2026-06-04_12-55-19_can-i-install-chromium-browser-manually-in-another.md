# can i install Chromium browser manually in another computer?

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-04T03:55:19.354Z

## User

can i install Chromium browser manually in another computer?

## Assistant

Yes. Playwright downloads its own isolated Chromium — it doesn't use your system Chrome. The command is the same on any machine:

```powershell
# From the admin_panel directory:
cd c:\project\vLearn2\admin_panel
npx playwright install chromium
```

That's it. It downloads to `%LOCALAPPDATA%\ms-playwright\` (~280 MB) and is ready to use.

---

### Other options

**Install all browsers at once** (Chromium + Firefox + WebKit):
```powershell
npx playwright install
```

**Install for CI / Linux (includes OS dependencies):**
```bash
npx playwright install chromium --with-deps
```

**Offline / air-gapped machine** — download the archive on a connected machine and copy it:
```powershell
# On connected machine: find where it downloaded
npx playwright install chromium
# Then copy the entire folder:
#   %LOCALAPPDATA%\ms-playwright\chromium-*
# to the same path on the offline machine
```
After copying, set this env var so Playwright finds it:
```powershell
$env:PLAYWRIGHT_BROWSERS_PATH = "$env:LOCALAPPDATA\ms-playwright"
```

**Specify a custom download location** (useful for shared CI agents):
```powershell
$env:PLAYWRIGHT_BROWSERS_PATH = "D:\playwright-browsers"
npx playwright install chromium
```
Then set the same env var when running tests.

---

The browser binary is **never committed to git** — each developer/CI machine runs `npx playwright install chromium` once after cloning.
