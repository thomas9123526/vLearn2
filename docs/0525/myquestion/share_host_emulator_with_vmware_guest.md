# Share host Android emulator with a VMware Windows 10 guest over ADB

## Goal

Run the Android emulator on the host (Windows + Android Studio). Use `adb` **inside** a VMware Windows 10 guest VM to talk to that emulator — so the guest can install APKs, run `adb shell`, debug, etc., without running its own emulator.

## Architecture

```
[Host: emulator] ←→ [Host: adb server on TCP 5037] ←→ [Guest VM: adb client]
   (port 5555)          (must listen on 0.0.0.0,           (env var
                         not just 127.0.0.1)                ADB_SERVER_SOCKET
                                                            points at host)
```

By default, the host's adb server binds only to `127.0.0.1`, so the guest can't reach it. The fix is to restart the adb server with `-a` (listen on all interfaces) and point the guest's adb at the host.

---

## Step 1 — On HOST: start the emulator

PowerShell on the host:

```powershell
emulator -list-avds                 # see what AVDs you have
emulator -avd Pixel_XL              # start one (replace with your AVD)
```

Wait until the Android home screen appears. Verify it registered with adb:

```powershell
adb devices
# Expected: emulator-5554    device
```

If it shows `offline`, the VM is still booting — wait a bit longer.

## Step 2 — On HOST: find the IP the guest will use

```powershell
ipconfig
```

Look at the VMware adapter IPs:

| Adapter | Typical IP | Use when VM network mode is |
| --- | --- | --- |
| VMware Network Adapter VMnet8 | `192.168.X.1` | NAT (default for new VMs) |
| VMware Network Adapter VMnet1 | `192.168.Y.1` | Host-only |
| Ethernet (LAN)                | LAN IP        | Bridged |

**Important caveat (the one we hit in this session):** if VMware's "Connect a host virtual adapter to this network" option is **unchecked** for VMnet8, the NAT-side host IP (`192.168.X.1`) is **not reachable from guests** even though it appears in `ipconfig`. The fix is to use a different reachable host IP (the VMnet1 host-only IP usually works, because NAT forwards the packet through the host's routing table).

Diagnostic — from inside the guest, ping each candidate host IP. Whichever responds is the one to use.

```powershell
ping 192.168.158.1        # VMnet8 host IP
ping 192.168.72.1         # VMnet1 host IP
```

## Step 3 — On HOST: restart adb server bound to all interfaces

```powershell
adb kill-server
# In a SEPARATE PowerShell window (must stay open):
adb -a -P 5037 nodaemon server
```

`-a` makes adb listen on **all** network interfaces (`0.0.0.0`), not just localhost. The `nodaemon` form runs in the foreground so it dies cleanly when you close the window.

Verify in another PowerShell:

```powershell
netstat -an | findstr :5037
# Good:  TCP    0.0.0.0:5037   0.0.0.0:0   LISTENING
# Bad:   TCP    127.0.0.1:5037 ...

adb devices
# Should still show emulator-5554    device
```

## Step 4 — On HOST: Windows Firewall

If Windows Firewall is **enabled**, allow inbound TCP 5037. In an **elevated** PowerShell:

```powershell
New-NetFirewallRule -DisplayName "ADB server for VM guests" `
    -Direction Inbound -Protocol TCP -LocalPort 5037 -Action Allow
```

If your firewall is fully disabled (as on this host), this step is a no-op.

### Side issue we hit: Astrill VPN

A VPN client running on the host can install network filter drivers that silently break host↔VM traffic on VMware NAT. If you see `Test-NetConnection` failing despite adb listening correctly, quit any VPN client and retest. Some VPNs let you configure split-tunnel exclusions for the VMware subnets.

## Step 5 — In GUEST: install platform-tools

Inside the VMware Windows 10 VM:

1. Download `platform-tools-latest-windows.zip` from
   <https://dl.google.com/android/repository/platform-tools-latest-windows.zip>
2. Extract to e.g. `C:\platform-tools`
3. Add to User PATH (no admin needed):

   ```powershell
   [Environment]::SetEnvironmentVariable(
       'Path',
       "$env:Path;C:\platform-tools",
       'User'
   )
   ```
4. Close the PowerShell window, open a fresh one, verify:

   ```powershell
   adb version
   ```

## Step 6 — In GUEST: point adb at the host's adb server

Use the working host IP from Step 2 (in our session, `192.168.72.1`):

```powershell
[Environment]::SetEnvironmentVariable(
    'ADB_SERVER_SOCKET',
    'tcp:192.168.72.1:5037',
    'User'
)
```

Close the PowerShell window and open a fresh one (env-var changes don't apply to existing sessions).

Verify:

```powershell
echo $env:ADB_SERVER_SOCKET   # tcp:192.168.72.1:5037
Test-NetConnection 192.168.72.1 -Port 5037   # TcpTestSucceeded : True
```

## Step 7 — In GUEST: list devices

```powershell
adb devices
```

Expected:

```text
List of devices attached
emulator-5554   device
```

Every `adb` command in the guest from this point on talks to the host's emulator transparently — `adb install app.apk`, `adb shell`, `adb logcat`, etc.

---

## Troubleshooting cheat sheet

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `adb devices` in guest is empty | Guest's local adb daemon hijacked the port | Run `adb kill-server` in guest, then re-run `adb devices` (it'll reconnect using the env var). |
| `Test-NetConnection` to host fails | VPN filter driver, wrong host IP, or VMware NAT host-adapter unchecked | Quit VPN; try the VMnet1 host-only IP; check VMware Virtual Network Editor → VMnet8 → "Connect a host virtual adapter to this network". |
| `adb devices` shows `offline` | Emulator still booting, OR ADB key handshake mid-flight | Wait 5–10 seconds and re-run. |
| Host adb server died when window closed | `nodaemon` ties the server to the window | Re-run Step 3 and keep the window open. Use Task Scheduler or a service wrapper if you want it persistent. |

## Reproducing on a fresh host

Use `share_host_emulator_with_vmware_guest.bat` next to this file — it automates Steps 1–4 on the host. The guest-side steps (5–7) still need to be done by hand inside the VM.
