# Conversation - Remove persistent GRADLE_USER_HOME pointing to D:\android\.gradle

| Field | Value |
|---|---|
| Saved | 2026-06-03 00:35:50 |
| Commit | fix: delete persistent GRADLE_USER_HOME user env var and clear it in setup.ps1 |
| Project | C:\project\vLearn2 |

---

## User

i think c:\Users\aaa\.vscode\extensions\redhat.java-1.54.0-win32-x64 , source: Dart extension use D:\android\.gradle

## Assistant

Found `GRADLE_USER_HOME=D:\android\.gradle` set as a persistent user-level environment variable — VS Code reads this at launch and it overrides `.vscode/settings.json`. User chose to delete it entirely. Also updated `setup.ps1` to clear the persistent user-level var each time it runs, so it never drifts back.

After a VS Code Reload Window the extensions will use `C:\Users\aaa\.gradle` from `.vscode/settings.json`.

---

## Prompt

i think c:\Users\aaa\.vscode\extensions\redhat.java-1.54.0-win32-x64 , source: Dart extension use D:\android\.gradle
