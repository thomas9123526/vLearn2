# Conversation - Fix installer script encoding for Windows 10

| Field | Value |
|---|---|
| Saved | 2026-06-04 15:07:20 |
| Commit | Fix installer scripts: replace all non-ASCII chars for Windows 10 PowerShell 5.1 |
| Project | C:\project\vLearn2 |

---

## User

If you have introduce new modules today then please download them inside installers like playwright-browsers and put install script. remember the script should be encoded properly so the script can be run under windows 10. I haven't run script before because the script was encoding badly for windows 10.

## Assistant

Checked today's changes: the Flutter animation work (FadeSlideIn, AnimatedSwitcher, AnimatedContainer) used only Flutter's built-in widget library — zero new pub or npm packages were added. Nothing new to download.

However, both existing installer scripts had non-ASCII characters that break Windows 10 PowerShell 5.1:

**Root cause:** Windows 10 ships `powershell.exe` (v5.1) which reads script files using the system ANSI codepage (CP1252 or CP949 depending on locale) unless a UTF-8 BOM is present. Files written by Claude Code are UTF-8 without BOM, so any character above codepoint 127 is misread and can abort parsing.

**Characters found and replaced:**

| File | Characters | Count | Replaced with |
|---|---|---|---|
| `install-playwright.ps1` | U+2500 `─` in comment separators | 867 bytes | ASCII `-` |
| `setup-dev.ps1` | U+2500 `─`, U+25BA `►`, U+2713 `✓`, U+2717 `✗` | multiple | `-`, `>>`, `[OK]`, `[FAIL]` |

Also added `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8` to both scripts so subprocess output (npm, flutter) renders correctly on Korean/non-UTF8 Windows consoles.

Both files verified as pure 7-bit ASCII after the fix.

---

## Prompt

If you have introduce new modules today then please download them inside installers like playwright-browsers and put install script. remember the script should be encoded properly so the script can be run under windows 10. I haven't run script before because the script was encoding badly for windows 10.
