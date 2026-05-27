# is the button for "Load .lic file" in License screen works? I put lic file to "C

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-27T03:42:56.526Z

## User

is the button for "Load .lic file" in License screen works?
I put lic file to "C:\Users\aaa\룡마\가상외국어회화", but doesn't load it

## Assistant

That button is a TODO stub — it just shows a message, never actually reads any file. Let me wire it up properly. Let me check what's available:

## Assistant

I'll wire up the actual file-loading. The button is a TODO right now — it just shows the instruction message. Plan: scan `%USERPROFILE%\룡마\가상외국어회화\` and its `\lic\` subfolder for *.lic files, base64-encode the most recent one, then call `/license/verify`.

## Assistant

Right — the warnings will clear once I add the loader function that actually uses those imports. Continuing:

## Assistant

Now wire the loader into `_getLicense` so the button actually does something:

## Assistant

Clean. Committing:

## Assistant

Done. The "Load .lic file" button now actually works on Windows. Committed as `cb26c51`.

**What it does now**:
1. On tap, it walks both `%USERPROFILE%\룡마\가상외국어회화\` and `%USERPROFILE%\룡마\가상외국어회화\lic\` looking for `*.lic` files.
2. Picks the **most recently modified** one (handy when you've issued a new license — it auto-grabs the latest).
3. Reads the raw DER bytes, base64-encodes them, and POSTs to `/license/verify` (same wire format Android already uses via QR).
4. Shows `Loaded from: C:\Users\aaa\룡마\가상외국어회화\xxx.lic` under the status card so you can confirm which file got picked up.
5. If no `.lic` is found anywhere, the error tells you the exact path to drop it in.

In your case the file at `C:\Users\aaa\룡마\가상외국어회화\<serial>.lic` will be picked up directly — no `\lic\` subfolder needed. Hot-reload the Flutter app and tap **Load .lic file** again.
