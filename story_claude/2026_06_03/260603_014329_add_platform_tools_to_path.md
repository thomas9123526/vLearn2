# Conversation - Add platform-tools to PATH via env-local.ps1

| Field | Value |
|---|---|
| Saved | 2026-06-03 01:43:29 |
| Commit | feat: add Android platform-tools and cmdline-tools to PATH in env-local.ps1 |
| Project | C:\project\vLearn2 |

---

## User

PS D:\android\sdk\Sdk\platform-tools> adb.exe devices
adb.exe: The term 'adb.exe' is not recognized...

## Assistant

PowerShell doesn't include the current directory in PATH (unlike CMD), so `adb.exe` without `.\` fails. Fixed by appending `platform-tools` and `cmdline-tools\latest\bin` to `$env:PATH` in `env-local.ps1`, and updated `setup.ps1` to regenerate this line. Verified with `adb devices` — emulator-5554 detected.

---

## Prompt

PS D:\android\sdk\Sdk\platform-tools> adb.exe devices
adb.exe: The term 'adb.exe' is not recognized as a name of a cmdlet, function, script file, or executable program.
