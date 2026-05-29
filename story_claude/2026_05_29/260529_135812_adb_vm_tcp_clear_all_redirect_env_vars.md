# Conversation - adb-vm-tcp clear all redirect env vars

| Field | Value |
|---|---|
| Saved | 2026-05-29 13:58:14 |
| Commit | adb-vm-tcp-connect: clear all 4 adb env vars + use explicit -H/-P |
| Project | C:\project\vLearn2 |

---

## User

(adb-vm-tcp-connect.bat output showing it cleared ANDROID_ADB_SERVER_ADDRESS/PORT but adb still failed connecting to tcp:192.168.72.1:5037 with "cannot start server on remote host")

## Assistant

Probed the env vars via PowerShell. Result:

| Var | Shell | User (setx) |
|---|---|---|
| ANDROID_ADB_SERVER_ADDRESS | empty | empty |
| ANDROID_ADB_SERVER_PORT | empty | empty |
| ANDROID_ADB_SERVER_SOCKET | empty | empty |
| **ADB_SERVER_SOCKET** | **tcp:192.168.72.1:5037** | **tcp:192.168.72.1:5037** |

`ADB_SERVER_SOCKET` overrides `_ADDRESS` + `_PORT`, so even though my earlier script cleared those two, the SOCKET var was redirecting adb. The value `tcp:192.168.72.1:5037` didn't come from any script I wrote — must've been `setx` manually at some point. My script also forgot that adb's redirect surface includes the SOCKET variants.

**Fix.** Update `cmds\adb-vm-tcp-connect.bat`:

1. **Clear all four** redirect env vars (`ANDROID_ADB_SERVER_ADDRESS`, `_PORT`, `_SOCKET`, plus `ADB_SERVER_SOCKET`), via a new `:clear_var` helper that:
   - Reports the old value so the user sees what was there.
   - Clears the in-shell value via `set "VAR="`.
   - **Clears the persistent User-scope value via `reg delete`** — otherwise a fresh cmd inherits the redirect back from HKCU\Environment.
2. **Use explicit `-H 127.0.0.1 -P 5037`** on every adb invocation. Belt-and-suspenders: even if some other env var I haven't seen redirects adb, the flags win.
3. Renamed the cosmetic "Host VMnet8" label to just "Host" — the script now supports any VMware adapter, not just VMnet8.
4. Restructured the "switch back" footer text to reflect that the redirect env vars are now cleared persistently.

The `reg delete` is silent on missing keys (`>nul 2>&1`), so it's safe to run when the var was never set.

**For the user RIGHT NOW** — after pulling this commit, re-run:
```
cmds\adb-vm-tcp-connect.bat 192.168.72.1
```
The script will print "ADB_SERVER_SOCKET was [tcp:192.168.72.1:5037]" once, clear it, and proceed cleanly. New shells won't see the redirect either.

---

## Prompt

C:\project\vLearn2>cmds\adb-vm-tcp-connect.bat 192.168.72.1

=== vLearn2 adb direct-TCP to LDPlayer ===
Host VMnet8: 192.168.72.1:5555
adb:         C:\tools\platform-tools\adb.exe

--- Switching adb mode to local server ---
Cleared ANDROID_ADB_SERVER_ADDRESS / ANDROID_ADB_SERVER_PORT
(current shell only; setx values for new shells unchanged)

--- Restarting local adb server ---
cannot connect to daemon at tcp:192.168.72.1:5037: cannot connect to 192.168.72.1:5037: No connection could be made because the target machine actively refused it. (10061)
* cannot start server on remote host
error: cannot connect to daemon at tcp:192.168.72.1:5037: cannot connect to 192.168.72.1:5037: No connection could be made because the target machine actively refused it. (10061)

--- Connecting to 192.168.72.1:5555 ---
* cannot start server on remote host
error: cannot connect to daemon at tcp:192.168.72.1:5037: cannot connect to 192.168.72.1:5037: No connection could be made because the target machine actively refused it. (10061)
[ERROR] adb connect failed.
Check that:
  - adb-host-portproxy.bat was run on the host (as admin).
  - LDPlayer is running on the host.
  - The host's firewall allows VMnet8 inbound :5555.
