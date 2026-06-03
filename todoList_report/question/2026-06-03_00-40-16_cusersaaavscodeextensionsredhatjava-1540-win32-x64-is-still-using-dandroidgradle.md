# c:\Users\aaa\.vscode\extensions\redhat.java-1.54.0-win32-x64 is still using D:\a

Session: `f56bdf13-4b13-4f2d-9e88-40dba40b3f91`
Saved: 2026-06-02T15:40:16.650Z

## User

c:\Users\aaa\.vscode\extensions\redhat.java-1.54.0-win32-x64 is still using D:\android\.gradle

## Assistant

Let me dig deeper — check the settings file content, system-level env var, and VS Code user settings.

## Assistant

The settings.json has over-escaped paths — `C:\\\\Users\\\\` instead of `C:\\Users\\`. The `-replace` doubled the backslashes. Let me fix the file now and fix the root cause in `setup.ps1`.

## Assistant

Good. Now fix `setup.ps1` to use `ConvertTo-Json` instead of the broken manual escaping:

## Assistant

Now do **Reload Window** in VS Code (`Ctrl+Shift+P` → `Developer: Reload Window`). The extension should pick up `C:\Users\aaa\.gradle`.

## Assistant

The root cause: `setup.ps1` was double-escaping backslashes (`C:\\\\Users\\\\` instead of `C:\\Users\\`), so VS Code read the path as invalid and fell back to its default `D:\android\.gradle`.

**Fixed:** `setup.ps1` now uses `ConvertTo-Json` for correct escaping, and `.vscode/settings.json` is already rewritten with the correct path.

Please do **Reload Window** (`Ctrl+Shift+P` → `Developer: Reload Window`) — after that the extension should use `C:\Users\aaa\.gradle`.
