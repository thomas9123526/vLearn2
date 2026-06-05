# You considered about server deployment. Then how about flutter windows applicati

Session: `40c2c32e-4bcc-4826-8449-440738f22ef6`
Saved: 2026-06-05T00:18:03.142Z

## User

You considered about server deployment.
Then how about flutter windows application?

## Assistant

Good question — Windows desktop is a different distribution problem. Let me look at the Flutter app first to understand how it currently handles the backend URL, then I can recommend the right approach.

## Assistant

The app already reads `app_config.json` from the same folder as the `.exe` — that's perfect for an installer. Let me check the executable name:

## Assistant

Executable is `flutter_app.exe`, built to `flutter_app/build/windows/x64/runner/Release/`. The plan:

- **`deploy/windows/build.ps1`** — runs `flutter build windows --release`, then compiles the Inno Setup installer
- **`deploy/windows/installer.iss`** — Inno Setup script: prompts for the server URL during install, writes `app_config.json` next to the exe automatically

## Assistant

Now commit with the story:

## Assistant

Done. Here's the full picture:

---

### How it works

The Flutter app already reads `app_config.json` from next to the `.exe` on Windows — so the installer just needs to write that file with the correct server URL. No source code changes needed.

**[deploy/windows/build.ps1](deploy/windows/build.ps1)** — run this on your dev machine:
```powershell
# Basic: build + package
powershell -File deploy\windows\build.ps1 -ServerUrl http://YOUR_SERVER_IP

# Build only (no installer)
powershell -File deploy\windows\build.ps1 -SkipInstaller

# Package only (if already built)
powershell -File deploy\windows\build.ps1 -SkipFlutterBuild -ServerUrl http://...
```

**[deploy/windows/installer.iss](deploy/windows/installer.iss)** — the Inno Setup script:
- Adds a "Server Connection" wizard page where users can confirm/change the URL
- After installation writes `app_config.json` automatically
- Produces `output/vlfls-setup-1.0.0.exe`

---

### Full distribution workflow

```
1. Deploy server  →  sudo bash deploy/install.sh   →  http://203.0.113.5
2. Build Windows  →  build.ps1 -ServerUrl http://203.0.113.5
3. Distribute     →  vlfls-setup-1.0.0.exe   (users double-click)
4. Distribute APK →  Android: Flutter build apk (unchanged)
```

### What you need to install first (one-time on your dev machine)
- **Inno Setup 6**: [jrsoftware.org/isdl.php](https://jrsoftware.org/isdl.php) — free, ~5 MB installer
