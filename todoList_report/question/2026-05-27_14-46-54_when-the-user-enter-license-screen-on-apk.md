# when the user enter License screen on apk, is it possible to scan files inside a

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-27T05:46:54.249Z

## User

when the user enter License screen on apk, is it possible to scan files inside a particular folder like 룡마/가상외국어회화/license and find  if anyone matches verification?

## Assistant

Yes, possible — but the answer changes by Android version. Three workable approaches:

| Approach | UX | Works for path `…/룡마/가상외국어회화/license/` | Constraint |
| --- | --- | --- | --- |
| **A. `MANAGE_EXTERNAL_STORAGE`** | One-time permission grant via Settings | ✓ any public path | Sensitive permission; Play Store gates it for non-file-manager apps |
| **B. Storage Access Framework** | User picks the folder once via system picker (then app has persistent access to that folder) | ✓ once user grants | Extra UX step on first launch; remembers across launches |
| **C. App-specific external storage** | None | ✗ — must use `/storage/emulated/0/Android/data/com.ryongma.vfls/files/license/` instead | Operator must drop the .lic in a different path |

For an internally-distributed app (which this is — vLearn2 is sideloaded, not on Play Store) where the user picks `/storage/emulated/0/룡마/가상외국어회화/license/` themselves, **A (MANAGE_EXTERNAL_STORAGE)** is the cleanest fit — same folder for everyone, no per-launch picker, scans-and-verifies "just works".

Suggested flow:
1. On Android, the License screen scans `/storage/emulated/0/룡마/가상외국어회화/license/` (plus the parent, matching the Windows pattern) for `*.lic`.
2. For each `.lic` file found (newest first), call `/license/verify` with its base64'd bytes.
3. First one that returns `valid: true` wins — cache it via `licenseStateProvider.setVerifiedContent` so auto-verify replays it on every future launch.
4. If none verify, show "No matching license found" with the expected folder path.

This mirrors the Windows path you already have (just a different folder and an extra permission gate). Want me to implement A with this flow?
