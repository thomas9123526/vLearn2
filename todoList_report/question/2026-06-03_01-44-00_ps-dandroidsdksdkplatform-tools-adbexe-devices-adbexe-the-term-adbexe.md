# PS D:\android\sdk\Sdk\platform-tools> adb.exe devices adb.exe: The term 'adb.exe

Session: `f56bdf13-4b13-4f2d-9e88-40dba40b3f91`
Saved: 2026-06-02T16:44:00.799Z

## User

PS D:\android\sdk\Sdk\platform-tools> adb.exe devices
adb.exe: The term 'adb.exe' is not recognized as a name of a cmdlet, function, script file, or executable program.
Check the spelling of the name, or if a path was included, verify that the path is correct and try again.

## Assistant

PowerShell doesn't include the current directory in `PATH` (unlike CMD). Use `.\` prefix:

```powershell
.\adb.exe devices
```

Or add platform-tools to your PATH permanently. Since `ANDROID_SDK_ROOT` is already in `env-local.ps1`, the cleanest fix is to add it to `env-local.ps1` so it loads automatically:

## Assistant

`ANDROID_SDK_ROOT` is `D:\android\sdk\Sdk`. I'll add `platform-tools` (and `cmdline-tools`) to PATH in both `env-local.ps1` and `setup.ps1` so it's permanent:

## Assistant

Now update `setup.ps1` so it regenerates this correctly:

## Assistant

Now dot-source it to activate in the current session and test:

## Assistant

`adb` works. Now commit:

## Assistant

`env-local.ps1` is gitignored (correct — it's machine-specific). Only `setup.ps1` and the story file need committing:

## Assistant

Done. `adb devices` shows `emulator-5554 device`.

**What changed:**
- `env-local.ps1` now prepends `platform-tools` and `cmdline-tools\latest\bin` to `PATH` when you dot-source it
- `setup.ps1` regenerates this line automatically for any machine

In any new shell, just run `. cmds\env-local.ps1` once and `adb` will work without needing `.\` or changing directories.
