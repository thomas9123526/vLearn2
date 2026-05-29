# Conversation - adb direct TCP to LDPlayer for Flutter debugger

| Field | Value |
|---|---|
| Saved | 2026-05-29 13:27:18 |
| Commit | Add adb-host-portproxy.bat + adb-vm-tcp-connect.bat for debugger |
| Project | C:\project\vLearn2 |

---

## User

I have run flutter apk on android studio, it recognizes the emulator-5554 outside this vmware machine. emulator is running on host machine. this is the message in androidstudio log

(...log showing build → install → app start → "Connecting to the VM Service is taking longer than expected" → SocketException to 127.0.0.1:NNNNN errno 1225...)

## Assistant

**Root cause.** `adb forward tcp:<vm-service-port>` runs in the adb SERVER's process, not the client's. Earlier this session we set up a shared adb server on the host (port :5038 via `cmds\adb-host-server.bat`), so when Flutter tool inside the VM asks for a forward, the listener lands on the HOST's 127.0.0.1, not the VM's. Flutter tool then connects to its own 127.0.0.1 — empty → errno 1225.

Build / install / `adb logcat` / `adb shell` work fine because those are device-direction commands; no host-side listener needed. Debugger attach is the one path that breaks.

**Fix.** Give the VM its OWN adb server, with a TCP connection to LDPlayer via VMnet8. Now `adb forward` runs in the VM's adb instance, on the VM's 127.0.0.1, exactly where Flutter tool looks.

Two scripts added:

1. **`cmds\adb-host-portproxy.bat`** (run on host, admin):
   - Auto-detects the VMnet8 host IP via `Get-NetIPAddress`.
   - `netsh interface portproxy delete` (idempotent) + `add v4tov4 listenaddress=<vmnet8-ip> listenport=5555 connectaddress=127.0.0.1 connectport=5555` — exposes LDPlayer's loopback-bound adb-TCP port on VMnet8.
   - Adds an inbound firewall rule scoped to the VMnet8 `/24` only.
   - Prints the IP + the exact follow-up command for the VM.
   - Optional port arg for non-default LDPlayer instances.

2. **`cmds\adb-vm-tcp-connect.bat <host-vmnet8-ip> [port]`** (run in VM):
   - Clears `ANDROID_ADB_SERVER_ADDRESS` / `ANDROID_ADB_SERVER_PORT` for THIS shell (warns first if they're set, so the user knows it's overriding the shared-server setup).
   - `adb kill-server` + `adb start-server` — fresh local adb server (default :5037).
   - `adb connect <ip>:5555`.
   - Lists devices + tells the user what to expect in Android Studio.
   - Doesn't touch `setx` values — the shared-server mode is still available in fresh cmd windows.

**Workflow tradeoff:**

| Setup | Build / install | logcat / shell | Flutter debugger |
|---|---|---|---|
| `cmds\adb-host-server.bat` (shared server :5038) | ✓ | ✓ | ✗ (this bug) |
| `cmds\adb-host-portproxy.bat` + `adb-vm-tcp-connect.bat` (direct TCP) | ✓ | ✓ | ✓ |

Most workflows now want the new pair. The shared-server one's only advantage is leaving LDPlayer's `:5037` untouched.

---

## Prompt

(User said "yes" in response to two questions: commit the pending build_apk_per_abi.bat work and write the adb-host-portproxy/adb-vm-tcp-connect scripts. Pending work turned out to already be in `a3f7713` — went straight to the scripts.)
