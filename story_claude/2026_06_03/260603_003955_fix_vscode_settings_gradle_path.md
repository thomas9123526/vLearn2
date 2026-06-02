# Conversation - Fix over-escaped path in .vscode/settings.json

| Field | Value |
|---|---|
| Saved | 2026-06-03 00:39:55 |
| Commit | fix: use ConvertTo-Json in setup.ps1 to avoid double-escaped backslashes in settings.json |
| Project | C:\project\vLearn2 |

---

## User

c:\Users\aaa\.vscode\extensions\redhat.java-1.54.0-win32-x64 is still using D:\android\.gradle

## Assistant

Found `.vscode/settings.json` had over-escaped paths (`C:\\\\Users\\\\` instead of `C:\\Users\\`) due to `-replace '\\', '\\\\'` doubling backslashes. Fixed by switching `setup.ps1` to use `ConvertTo-Json` for correct automatic escaping. Rewrote the settings.json immediately.

---

## Prompt

c:\Users\aaa\.vscode\extensions\redhat.java-1.54.0-win32-x64 is still using D:\android\.gradle
