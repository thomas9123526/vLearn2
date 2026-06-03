# Conversation - Fix cmds .ps1 encoding parser error on Win11

| Field | Value |
|---|---|
| Saved | 2026-06-03 10:07:07 |
| Commit | auto: convert cmds/*.ps1 to ASCII to fix PS5.1 parser error on Win11 |
| Project | C:\project\vLearn2 |

---

## User

cmds/setup.ps1 not work on this vmware machine

## Assistant

Investigated the script and the live VM environment. Found that env vars
(`ANDROID_SDK_ROOT=C:\tools`, `JAVA_HOME`, Flutter on PATH) were already correct,
and the Gradle dist was already seeded — so the obvious path mismatches were not
the blocker. Asked the user for the exact symptom.

User reported the real error:

```
At C:\project\vLearn2\cmds\setup.ps1:208 char:223
+ ... ----------------------------------
The string is missing the terminator: ".
At C:\project\vLearn2\cmds\setup.ps1:204 char:8
+ } else {
Missing closing '}' in statement block or type definition.
ParserError ... TerminatorExpectedAtEndOfString
Host machine is Windows 11.
```

Diagnosis: **encoding bug, not logic.** All `cmds\*.ps1` files are saved as
UTF-8 **without a BOM** and contain decorative non-ASCII characters (box-drawing
`─`, em-dash `—`, bullet `•`, ellipsis `…`, arrows `← →`). Windows PowerShell 5.1
(`powershell.exe`, default on Win10/11) decodes BOM-less files using the system
ANSI code page, not UTF-8, turning each multibyte char into mojibake. That
corruption produced a stray quote in the line-208 separator comment, which the
parser reported as a missing string terminator + missing brace.

Fix: converted all six scripts to **pure ASCII**, mapping decorative chars to
ASCII equivalents (`─`/`—`→`-`, `•`→`*`, `…`→`...`, `←`→`<-`, `→`→`->`). Read each
file as UTF-8, replaced, wrote back as UTF-8-no-BOM (7-bit clean). This makes the
scripts parse correctly regardless of console code page, BOM, or PowerShell edition.

Verified: 0 non-ASCII bytes remain in every file, and all six pass
`[System.Management.Automation.Language.Parser]::ParseFile` with no errors. Diff
review confirmed only comments and `Write-Host` display strings changed — nothing
semantic.

All six scripts shared the identical latent bug, so fixed them together rather
than just `setup.ps1` (which even points the user to `vlearn2-online.ps1` at the end).

---

## Prompt

cmds/setup.ps1 not work on this vmware machine
