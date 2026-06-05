# Conversation - Download and install Inno Setup for offline VM

| Field | Value |
|---|---|
| Saved | 2026-06-05 11:11:50 |
| Commit | auto: add download_win_tools and install_win_tools scripts for offline VM |
| Project | C:\project\vLearn2 |

---

## User

when i execute build.ps1

[....] Looking for Inno Setup compiler...
[WARN] Inno Setup (ISCC.exe) not found.
[WARN] Download from: https://jrsoftware.org/isdl.php
[WARN] Then re-run without -SkipInstaller.
[WARN] Skipping installer packaging — release files are in:
[WARN]   C:\project\vLearn2\flutter_app\build\windows\x64\runner\Release

shows.

so what is ISCC.exe?

## Assistant

Inno Setup Compiler (`ISCC.exe`) is the command-line tool for **Inno Setup**, a free Windows installer creator. It takes an `.iss` script file and packages your app into a single `.exe` installer for end users.

Your `build.ps1` is trying to use it to wrap the compiled Flutter Windows release into a proper installer — but it's not installed on this machine, so that step is skipped.

The actual Flutter build succeeded; the release binaries are already at `flutter_app\build\windows\x64\runner\Release`. You just don't have a distributable installer yet.

**To get the installer:** download Inno Setup from jrsoftware.org, install it (default path is `C:\Program Files (x86)\Inno Setup 6\ISCC.exe`), then re-run `build.ps1`.

---

## User

I have this project as same version in the vmware but it has no internet.
Can you make a script to download those windows installer package and setup environment for both this machine and vmware?
Is it possible?

## Assistant

Yes — created two scripts following the existing bundle workflow:

- `cmds/download_win_tools.ps1` — runs on the host (internet), downloads Inno Setup into `tools/installers/`
- `cmds/install_win_tools.ps1` — runs on either machine (offline), silently installs from that folder

**Workflow:**
1. Host: `.\cmds\download_win_tools.ps1` → saves `tools\installers\innosetup-6-latest.exe`
2. Host: commit the file, then `.\cmds\make_bundle.ps1` → creates bundle
3. Copy bundle to VM → `.\cmds\apply_bundle.ps1`
4. VM (and host): `.\cmds\install_win_tools.ps1` → silent install, no internet needed

---

## Prompt

I have this project as same version in the vmware but it has no internet.
Can you make a script to download those windows installer package and setup environment for both this machine and vmware?
Is it possible?
