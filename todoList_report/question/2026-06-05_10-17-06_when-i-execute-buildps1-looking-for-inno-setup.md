# when i execute build.ps1  [....] Looking for Inno Setup compiler... [WARN] Inno 

Session: `1d61e3ee-f2ea-4568-b3a0-ec95b91de827`
Saved: 2026-06-05T01:17:06.051Z

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

Your `build.ps1` is trying to use it to wrap the compiled Flutter Windows release into a proper installer (like `vLearn2_setup.exe`) — but it's not installed on this machine, so that step is skipped.

The actual Flutter build succeeded; the release binaries are already at `flutter_app\build\windows\x64\runner\Release`. You just don't have a distributable installer yet.

**To get the installer:** download Inno Setup from `https://jrsoftware.org/isdl.php`, install it (default path is `C:\Program Files (x86)\Inno Setup 6\ISCC.exe`), then re-run `build.ps1` without any `-SkipInstaller` flag.
