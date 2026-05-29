# Conversation - Run adb server on host for VM emulator debugging

| Field | Value |
|---|---|
| Saved | 2026-05-29 09:50:32 |
| Commit | Add adb-host-server.bat for VM-to-host emulator debugging |
| Project | C:\project\vLearn2 |

---

## User

This is in vmware environment. I have start emulator-5554 on host and can i connect to it via adb? Then I can debug apk through adb.

## Assistant

Yes — but adb in the VM won't auto-discover devices on the host. Two approaches:

- **Option A (cleanest):** Share the host's adb server with the VM. On the host: `adb kill-server` then `adb -a -P 5037 nodaemon server start` to bind on all interfaces. In the VM: `set ANDROID_ADB_SERVER_ADDRESS=<host-ip>` + `set ANDROID_ADB_SERVER_PORT=5037`, then `adb devices` sees the emulator as if local. Flutter and the debugger work normally.
- **Option B:** Use `adb connect <host-ip>:5555` from the VM directly to the emulator's adb port — needs a port-forward because LDPlayer binds 127.0.0.1 by default.

Finding `<host-ip-from-vm>` depends on VMware network mode (NAT / Bridged). Firewall on the host must allow 5037/5555 from the VM's subnet.

## User

I'm on NAT

## Assistant

On NAT, the VM reaches the host via the **VMnet8 host IP** (e.g. `192.168.X.1`) — not the default gateway (`.2`, the VMware NAT gateway). Steps:

1. Find host IP: on the host, `ipconfig` → look at "VMware Network Adapter VMnet8" → IPv4 Address.
2. Restart adb on the host bound to all interfaces: `set ADB_SERVER_SOCKET=tcp:0.0.0.0:5037` then `adb start-server`.
3. Open firewall scoped to VMnet8 `/24` only: `New-NetFirewallRule -DisplayName "adb from VM (VMnet8)" -Direction Inbound -Protocol TCP -LocalPort 5037 -RemoteAddress 192.168.X.0/24 -Action Allow`.
4. In the VM: `set ANDROID_ADB_SERVER_ADDRESS=192.168.X.1` + `set ANDROID_ADB_SERVER_PORT=5037`. `adb devices` shows emulator-5554. Persist with `setx`.

Gotchas: LDPlayer auto-restarts its own adb on `:5037` and can kill your remote server. If `flutter` doesn't see the device in the VM, re-check env vars in the shell.

## User

i can't kill adb server by run 'adb kill-server' what happend?

## Assistant

Two failure modes on Windows:

- **Version mismatch:** LDPlayer ships its own (often older) `adb.exe` on `:5037`. Your client refuses to cleanly kill a server with a different protocol version. Confirm via `netstat -ano | findstr 5037` and `tasklist /fi "imagename eq adb.exe"`.
- **Watchdog respawn:** LDPlayer's helper process spawns a fresh `adb.exe` within milliseconds of `kill-server` succeeding.

Fixes (pick by symptom):
- `taskkill /F /IM adb.exe` then start *your* adb by full path.
- Replace LDPlayer's bundled `adb.exe` with `C:\tools\platform-tools\adb.exe` so versions match.
- Stop all LDPlayer windows before configuring adb, then relaunch.
- **Recommended for your setup:** Run your VM-facing server on a **different port** (`:5038`) so LDPlayer's `:5037` server is unaffected. `set ADB_SERVER_SOCKET=tcp:0.0.0.0:5038`, `adb -P 5038 start-server`, `adb -P 5038 connect 127.0.0.1:5555`. In the VM: `set ANDROID_ADB_SERVER_PORT=5038`. No fight with the watchdog.

## User

yes

## Assistant

Wrote `cmds\adb-host-server.bat`:

- Uses real local `C:\tools\platform-tools\adb.exe` (avoids the Z: crash per `vm-environment` memory).
- Auto-detects VMnet8 host IP via PowerShell `Get-NetIPAddress` and prints it so the user knows what to point the VM at.
- Kills only whatever is on `:5038` (the dedicated port) — does NOT touch LDPlayer's `:5037`.
- Adds a firewall rule scoped to the VMnet8 `/24` (admin-only; warns if not elevated and prints the manual command).
- Starts adb bound to `0.0.0.0:5038`, then `adb connect 127.0.0.1:5555` so LDPlayer's emulator registers with this server.
- Prints the exact `set ...` lines for the VM.

Usage: `cmds\adb-host-server.bat` on the host (admin recommended), then in the VM `setx ANDROID_ADB_SERVER_ADDRESS <printed-ip>` + `setx ANDROID_ADB_SERVER_PORT 5038`.

## User

adb devices show emulator-5554 on host machine. How can i flutter debug apk?

## Assistant

With remote adb set up, debugging is the same as if the emulator were local:

- **`flutter run -d emulator-5554`** — builds debug APK, installs, launches, attaches debugger, hot reload. `r` = hot reload, `R` = hot restart, `q` = quit. DevTools URL printed in console.
- **`flutter attach -d emulator-5554`** — for an already-installed debug APK.
- **VS Code:** pick the emulator in the device dropdown, F5 to start.

Must be a *debug* build — release APKs have no Dart VM service and can't be debugged (only `adb logcat`).

Likely first-run gotchas: long initial install over VMnet8, `adb forward` issues, and ABI mismatch (LDPlayer is typically x86_64 — build with `--target-platform android-x64` if needed; `cmds\build_apk_per_abi.bat` exists for split builds).

---

## Prompt

This is in vmware environment. I have start emulator-5554 on host and can i connect to it via adb? Then I can debug apk through adb.

(Subsequent prompts in this session refined the setup: NAT network mode, `adb kill-server` not killing LDPlayer's server, and how to debug from Flutter once the remote adb was working.)
