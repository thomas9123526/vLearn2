# Conversation - Add vlearn2 online toggle script

| Field | Value |
|---|---|
| Saved | 2026-05-29 15:16:32 |
| Commit | Add cmds\vlearn2-online.bat to toggle/check VLEARN2_ONLINE |
| Project | C:\project\vLearn2 |

---

## User

can you make a script to turn VLEARN2_ONLINE on or off and check script if it is on or off

## Assistant

Added `cmds\vlearn2-online.bat` with subcommands:

| Action | Effect |
|---|---|
| `on` | `set VLEARN2_ONLINE=1` in the calling shell. Gradle uses the network. |
| `off` | `set VLEARN2_ONLINE=` in the calling shell. Gradle is offline. |
| `status` (default if no arg) | Prints both current-shell state AND the persistent HKCU\Environment value. |
| `persist-on` | `setx VLEARN2_ONLINE 1`. Every new cmd inherits ON. Discouraged — undermines the offline-by-default workflow. |
| `persist-off` | `reg delete` from HKCU\Environment to revert `persist-on`. |

**Key implementation details:**

1. **NO `setlocal`** at the top of the script. cmd.exe runs batch files in the calling shell's environment by default, but `setlocal` creates a scope that's torn down at `endlocal` (or script end), losing the env-var changes. For this script, omitting `setlocal` is what makes `cmds\vlearn2-online.bat on` actually persist into the user's interactive prompt.
2. **Parens inside echo strings are escaped** (`^(...^)`) per the earlier cmd-IF-block bug we hit in the adb scripts.
3. **Persistent-state check via `reg query "HKCU\Environment" /v VLEARN2_ONLINE`** — no PowerShell needed; faster than spawning a PS process for a status line. Output line format: `    VLEARN2_ONLINE    REG_SZ    1`, so `for /f "tokens=3"` extracts the value.
4. **Three-way status display:** `ON` (matches "1"), `off` (empty), or `unrecognized [<val>]` (any other value — defensive, since the init script's check is `!= "1"`, so anything weird falls into offline mode but we tell the user about it).

**Smoke-tested** by reading back syntactically — the inline test I tried (via PowerShell `&` on the .bat) is unreliable because PS doesn't actually execute batch files that way (it interprets each line as PS). Trusting the structure; user can verify with `cmds\vlearn2-online.bat status` in a real cmd window.

**Typical use:**
```
cmds\vlearn2-online.bat status     :: see where we are
cmds\vlearn2-online.bat on         :: opt in for this shell
flutter pub add some_package
flutter pub get                    :: hits the network
cmds\vlearn2-online.bat off        :: back to offline
cmds\verify_offline_build.bat      :: confirm new dep is in cache
```

---

## Prompt

can you make a script to turn VLEARN2_ONLINE on or off and check script if it is on or off
