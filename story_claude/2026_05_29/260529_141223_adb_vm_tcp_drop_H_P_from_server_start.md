# Conversation - adb vm tcp drop H P from server start

| Field | Value |
|---|---|
| Saved | 2026-05-29 14:12:24 |
| Commit | adb-vm-tcp-connect: drop -H/-P from kill/start-server (-H suppresses spawn) |
| Project | C:\project\vLearn2 |

---

## User

(After previous fix cleared ADB_SERVER_SOCKET, the run now correctly targets 127.0.0.1:5037 but still fails:)

```
--- Restarting local adb server ---
cannot connect to daemon at tcp:127.0.0.1:5037: ... actively refused it. (10061)
* cannot start server on remote host
```

## Assistant

Different bug this time — env vars are now correctly cleared (adb is hitting 127.0.0.1:5037 instead of the stray .72.1 redirect). The remaining issue is `-H 127.0.0.1 -P 5037` passed to `start-server` itself.

**adb's behavior:** when `-H` is specified — **even with the value `127.0.0.1`** — adb treats the server as "remote" and **will not auto-spawn it**. The flag is interpreted as "talk to an existing server on this host"; spawn is reserved for the default-args path. So `adb -H 127.0.0.1 -P 5037 start-server` translates roughly to "connect to the server at 127.0.0.1:5037, and if it isn't there, give up". The error message "cannot start server on remote host" confirms it.

**Fix.** Remove `-H` and `-P` from `kill-server` and `start-server` lines. Keep them on `connect` and `devices` (where they're harmless safety against a stray env var). The redirect env vars are already cleared above, so the no-flag default of `127.0.0.1:5037` is correct.

Two-line change in the script:
```diff
- "%ADB%" -H 127.0.0.1 -P 5037 kill-server
- "%ADB%" -H 127.0.0.1 -P 5037 start-server
+ "%ADB%" kill-server
+ "%ADB%" start-server
```

Plus updated the comment block to record WHY (so I don't reintroduce the bug in the future).

After this commit, the flow should be:
1. Print + clear the four redirect env vars (already working).
2. `adb kill-server` (no flags) → kills nothing if no server, otherwise stops it.
3. `adb start-server` (no flags) → spawns a fresh local server at 127.0.0.1:5037.
4. `adb -H 127.0.0.1 -P 5037 connect 192.168.72.1:5555` → registers the LDPlayer device with the local server via the host's portproxy.
5. `adb -H 127.0.0.1 -P 5037 devices -l` → lists `192.168.72.1:5555  device`.

---

## Prompt

still same.

C:\project\vLearn2>cmds\adb-vm-tcp-connect.bat 192.168.72.1

=== vLearn2 adb direct-TCP to LDPlayer ===
Host:  192.168.72.1:5555
adb:   C:\tools\platform-tools\adb.exe

--- Clearing adb redirect env vars (shell + persistent) ---
  ADB_SERVER_SOCKET was [tcp:192.168.72.1:5037]

--- Restarting local adb server ---
cannot connect to daemon at tcp:127.0.0.1:5037: cannot connect to 127.0.0.1:5037: No connection could be made because the target machine actively refused it. (10061)
* cannot start server on remote host
error: cannot connect to daemon at tcp:127.0.0.1:5037: cannot connect to 127.0.0.1:5037: No connection could be made because the target machine actively refused it. (10061)

--- Connecting to 192.168.72.1:5555 ---
* cannot start server on remote host
error: cannot connect to daemon at tcp:127.0.0.1:5037: cannot connect to 127.0.0.1:5037: No connection could be made because the target machine actively refused it. (10061)
[ERROR] adb connect failed.
Check that:
  - adb-host-portproxy.bat was run on the host (as admin).
  - LDPlayer is running on the host.
  - The host's firewall allows inbound :5555 from this subnet.
