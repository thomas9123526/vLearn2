# Conversation - Escape parens in echo inside cmd IF blocks

| Field | Value |
|---|---|
| Saved | 2026-05-29 13:42:01 |
| Commit | Escape parens inside cmd IF/echo blocks |
| Project | C:\project\vLearn2 |

---

## User

C:\project\vLearn2\cmds>adb-host-portproxy.bat
. was unexpected at this time.

(Re-clarified: running on the host, the script fails immediately with this error.)

## Assistant

**Root cause.** Inside cmd.exe `if (...)` blocks, parens count toward block depth EVEN inside `echo` strings. My `adb-host-portproxy.bat` had:

```bat
if not %errorlevel%==0 (
    echo [ERROR] This script needs admin (netsh portproxy + firewall).
    ...
)
```

cmd's parser opens the IF block at the first `(`, then hits the `(netsh portproxy + firewall)` in the echo, decrements its depth count incorrectly, closes the IF block at that inner `)`, and tries to parse "`firewall)\n...`" as the next statement. The next thing it sees is `.` (from "firewall**)**." — actually the period after the close-paren), and reports "`. was unexpected at this time.`"

Same pattern existed in two other scripts I wrote earlier in the session — fixed proactively even though they hadn't manifested yet:

- `adb-host-server.bat` line 36 — inside `if not exist "%ADB%" (` block, echo had `(see memory: vm-environment)`. Probably didn't fire for the user earlier because `C:\tools\platform-tools\adb.exe` exists on this VM so the IF body was never entered. **But cmd parses the block to find its end regardless of whether it'll execute** — meaning a different machine where adb doesn't exist would have failed cryptically. Belt-and-suspenders.
- `adb-vm-tcp-connect.bat` lines 43, 83 — same pattern in two `if (...) ` blocks.
- `verify_offline_build.bat` lines 105, 108 — `if /I "%SKIP_QRSCAN%"=="no-qrscan" (...) else (...)` block, echoes with `(skipped per ...)`  and `(gradlew :app:assembleDebug)`.

**Fix.** Escape `(` as `^(` and `)` as `^)` in every echo inside a `(...)` block. This tells cmd's parser to treat them as literal characters, not block delimiters.

Audited the other recently-added bat files (`bootstrap_offline_gradle.bat`, `build_apk_per_abi.bat`) — no occurrences. The older scripts in `cmds/` use the same idiom in a few places but the user hasn't reported them breaking; left those alone to avoid mass-touching unrelated work.

---

## Prompt

i run on host machine for
C:\project\vLearn2\cmds>adb-host-portproxy.bat
but it outputs '. was unexpected at this time.'
