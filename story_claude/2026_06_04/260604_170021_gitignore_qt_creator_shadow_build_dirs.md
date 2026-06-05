# Conversation - gitignore Qt Creator shadow-build dirs

| Field | Value |
|---|---|
| Saved | 2026-06-04 17:00:21 |
| Commit | auto: untrack + gitignore Qt Creator shadow-build dirs |
| Project | C:\project\vLearn2 |

---

## User

I want gitignore all inside all files inside build-qt-app-Desktop_Qt_5_12_12_.....

## Assistant

The Qt Creator shadow-build dirs sit at the repo root
(build-qt_app-Desktop_Qt_5_12_12_GCC_64bit-Debug / -Release), outside qt_app/, so
qt_app/.gitignore didn't cover them. The Debug dir had also been committed
earlier, so .gitignore alone wouldn't help — already-tracked files keep being
tracked.

Fix:
- Replaced the four messy hand-added patterns in the root .gitignore with two
  clean globs: `build-qt_app-Desktop_*/` and `build-*-Desktop_*/` (covers
  Debug/Release and any future kit).
- `git rm -r --cached build-qt_app-Desktop_Qt_5_12_12_GCC_64bit-Debug` to untrack
  the 28 committed build artifacts (files kept on disk).
- Verified: 0 tracked build- files remain; git check-ignore matches both Debug
  and Release; the dirs stay on disk.

---

## Prompt

I want gitignore all inside all files inside build-qt-app-Desktop_Qt_5_12_12_.....
