# Conversation - Auto-install offline init script on vlearn2-online off

| Field | Value |
|---|---|
| Saved | 2026-06-02 21:47:41 |
| Commit | fix: auto-install offline init script when switching off |
| Project | C:\project\vLearn2 |

---

## User

so after build success and git push and on another computer i git pull and build with vlearn2-online.ps1 on and then i switch off then build works?

## Assistant

Not quite. The offline init script (`D:\android\.gradle\init.d\offline.init.gradle`) only exists on the current machine because it was installed manually. On the new machine after git pull, it won't be there. So after switching `off`, Gradle won't know to stay offline and will try the network for dependency checks, causing failures.

Fix: modified the `off` command to automatically install the init script if it's missing. The `off` action now:
1. Clears `VLEARN2_ONLINE`
2. Checks if `$GRADLE_USER_HOME\init.d\offline.init.gradle` exists
3. If missing, copies it from `tools\gradle\init.d\offline.init.gradle` (which IS in the repo)

So the workflow on a new machine is exactly what you described — no extra steps:
```
git pull
.\cmds\vlearn2-online.ps1 on           # enable network
flutter build apk --debug              # downloads Gradle + Maven + pub deps
.\cmds\vlearn2-online.ps1 off          # clears VLEARN2_ONLINE + auto-installs init script
flutter build apk --debug              # works offline
```

---

## Prompt

so after build success and git push and on another computer i git pull and build with vlearn2-online.ps1 on and then i switch off then build works?
