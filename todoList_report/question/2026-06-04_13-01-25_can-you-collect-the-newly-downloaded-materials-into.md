# can you collect the newly downloaded materials into 'installers' folder and make

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-04T04:01:25.384Z

## User

can you collect the newly downloaded materials into 'installers' folder and make a script to enable it?

## Assistant

Let me read that file first to understand the context, and also check what was downloaded.

## Assistant

The Playwright browsers are 683 MB total. I'll copy them to `installers/playwright-browsers/` and create an install script so any machine can set up without internet. The folder goes in `.gitignore` — you share it via USB/network drive, not git.

## Assistant

Now write the install script and the gitignore entry:

## Assistant

Also create a general dev-setup script that ties everything together:

## Assistant

Now add the binary folder to `.gitignore` (it's 683 MB — never goes in git):

## Assistant

Now commit the scripts (not the 683 MB binaries):

## Assistant

Done. Here's the layout:

```
installers/
  playwright-browsers/     ← 683 MB browser binaries (gitignored, share via USB)
    chromium-1223/
    chromium_headless_shell-1223/
    ffmpeg-1011/
    winldd-1007/
  install-playwright.ps1   ← tracked in git ✓
  setup-dev.ps1            ← tracked in git ✓
```

### How to use on a new machine

**With internet** (downloads Chromium fresh):
```powershell
.\installers\setup-dev.ps1
```

**Without internet** (copy `installers/playwright-browsers/` from USB first):
```powershell
.\installers\setup-dev.ps1 -Offline
```

**Just browsers, already have npm set up:**
```powershell
.\installers\install-playwright.ps1
```

The scripts in `installers/` are in git. Only the 683 MB binary folder is excluded — copy that manually via USB drive or network share to offline machines.
