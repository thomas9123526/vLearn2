# Conversation - PowerShell version of vlearn2 online toggle

| Field | Value |
|---|---|
| Saved | 2026-05-29 15:25:30 |
| Commit | Add cmds\vlearn2-online.ps1 (PowerShell-callable counterpart) |
| Project | C:\project\vLearn2 |

---

## User

```
PS C:\project\vLearn2> .\cmds\vlearn2-online.bat on
VLEARN2_ONLINE = 1   (this shell only; gradle will use the network)
PS C:\project\vLearn2> .\cmds\vlearn2-online.bat
=== VLEARN2_ONLINE status ===
Current shell:     off  (offline; default)
Persistent (User):  off / unset
```
is this correct works?

## Assistant

It worked exactly as designed; the **invocation was wrong**. When PowerShell runs a `.bat` file, it spawns a child `cmd.exe` to execute it. The batch sets `VLEARN2_ONLINE=1` in that child cmd's environment, prints the message, then `cmd` exits and the env var change dies with it. PowerShell (the parent process) never sees the change. The status check in PS that follows correctly reports `off`.

This is the fundamental difference: in **cmd**, `cmds\vlearn2-online.bat on` runs the batch in the same shell's environment — change persists. In **PowerShell**, every batch invocation goes through a child cmd — change is lost. The "no setlocal" trick in the `.bat` only solves the in-cmd case.

**Fix.** Added `cmds\vlearn2-online.ps1` — a PowerShell native counterpart. Subcommands are identical: `on`, `off`, `status` (default), `persist-on`, `persist-off`. Because the script runs in PowerShell's own process, `$env:VLEARN2_ONLINE = '1'` actually persists into the calling prompt.

Implementation notes:

- `param` with `[ValidateSet(...)]` for the action — gets validation + tab-completion for free.
- For `on`: `$env:VLEARN2_ONLINE = '1'`.
- For `off`: `Remove-Item Env:VLEARN2_ONLINE` (more idempotent than `$env:VAR = ''` — leaves no empty-string entry).
- For `status`: three-way display (matches the .bat). Persistent value via `[Environment]::GetEnvironmentVariable($name, 'User')`.
- For `persist-on`/`-off`: `[Environment]::SetEnvironmentVariable($name, $val, 'User')` instead of shelling out to `setx`/`reg delete`.
- Single-quoted strings everywhere so the embedded literal apostrophes/quotes don't need backtick escapes.
- Comment at the top warns about execution-policy errors (`Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` is the typical one-time fix).

**Smoke test verified the round-trip:** seeded `$env:VLEARN2_ONLINE = '1'` externally, ran `status` (saw `ON`), ran `off` and re-checked (`[$env:VLEARN2_ONLINE]` printed `[]`), ran `on` and re-checked (`[1]`). Each subcommand correctly modifies the calling PS process's env.

**Now the user can:**
```
.\cmds\vlearn2-online.ps1 on
flutter pub get
.\cmds\vlearn2-online.ps1 off
.\cmds\verify_offline_build.bat
```

The `.bat` and `.ps1` versions coexist — pick whichever your shell is. Cmd users get the .bat (no PS overhead), PowerShell users get the .ps1 (no child-process pitfall).

---

## Prompt

ok, can you explain about this?

PS C:\project\vLearn2> .\cmds\vlearn2-online.bat on
VLEARN2_ONLINE = 1   (this shell only; gradle will use the network)
PS C:\project\vLearn2> .\cmds\vlearn2-online.bat
=== VLEARN2_ONLINE status ===
Current shell:     off  (offline; default)
Persistent (User):  off / unset
PS C:\project\vLearn2>

is this correct works?
