# Conversation - Add Windows installer build scripts

| Field | Value |
|---|---|
| Saved | 2026-06-05 09:17:30 |
| Commit | auto: add deploy/windows installer scripts (Inno Setup + build.ps1) |
| Project | C:\project\vLearn2 |

---

## User

You considered about server deployment.
Then how about flutter windows application?

## Assistant

Checked the Flutter app config system — found that on Windows the app already reads
`app_config.json` from the same directory as the `.exe` (flutter_app/lib/core/config/app_config.dart).
Executable name is `flutter_app.exe` (from windows/CMakeLists.txt).

Created two files in `deploy/windows/`:

**build.ps1** — PowerShell build + packaging script:
- Runs `flutter build windows --release`
- Writes a default `app_config.json` into the Release folder
- Optionally runs Inno Setup (ISCC.exe) to produce a single `.exe` installer
- Supports flags: `-SkipFlutterBuild`, `-SkipInstaller`, `-ServerUrl`

**installer.iss** — Inno Setup 6 script:
- Bundles everything from the Release folder
- Adds a custom wizard page asking for the server URL before installation
- After file installation, writes `app_config.json` next to the exe with the entered URL
- Creates desktop shortcut and Start Menu entry
- Uninstaller included

**Distribution flow:**
1. Operator sets up server with `deploy/install.sh`, gets a URL
2. Developer runs `build.ps1 -ServerUrl http://THAT_URL` → produces `vlfls-setup-1.0.0.exe`
3. Distribute the `.exe` to Windows users — they just double-click and install

---

## Prompt

You considered about server deployment.
Then how about flutter windows application?
