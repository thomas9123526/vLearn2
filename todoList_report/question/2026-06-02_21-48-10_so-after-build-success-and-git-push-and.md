# so after build success and git push and on another computer i git pull and build

Session: `a02819f6-c563-4d87-a349-0daa998cc204`
Saved: 2026-06-02T12:48:10.655Z

## User

so after build success and git push and on another computer i git pull and build with vlaern2-online.ps1 on and then i switch off then build works?

## Assistant

Not quite — there's one gap. The offline init script (`D:\android\.gradle\init.d\offline.init.gradle`) only exists on THIS machine because we installed it manually. On the new machine it won't be there, so after you switch `off`, Gradle won't know to stay offline and will try the network for dependency version checks, causing failures.

The fix: make the `off` command automatically install the init script if it's missing. That way the user's exact workflow works with no extra steps.

## Assistant

Now commit this fix plus write a story update:

## Assistant

Yes, after this fix the exact workflow you described works on a new machine:

```powershell
git pull
.\cmds\vlearn2-online.ps1 on      # enable network
flutter build apk --debug          # downloads Gradle + Maven deps + pub packages
.\cmds\vlearn2-online.ps1 off      # clears network flag AND auto-installs init script
flutter build apk --debug          # works offline ✓
```

The `off` command now auto-installs `tools\gradle\init.d\offline.init.gradle` into `%GRADLE_USER_HOME%\init.d\` if it's missing. That file is in the repo, so it travels with every `git pull`. Without it Gradle would still try the network for version checks even with no internet; with it installed, Gradle enforces `--offline` mode automatically on every build where `VLEARN2_ONLINE` isn't set.
