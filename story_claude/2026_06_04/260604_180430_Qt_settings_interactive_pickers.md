# Conversation - Qt settings interactive pickers

| Field | Value |
|---|---|
| Saved | 2026-06-04 18:04:30 |
| Commit | auto: make Settings items interactive (pickers) like Flutter |
| Project | C:\project\vLearn2 |

---

## User

If i click each items on setting screen, they didn't reply, plz follow the flutter
windows

## Assistant

The Settings rows were display-only; made each one respond with a picker, matching
the Flutter bottom-sheet pickers and persisting where Flutter does:

- Theme → Apricot/Sage/Iris/Obsidian → PATCH /users/profile activeTheme (note:
  restart to apply, since the Qt theme is applied once at startup).
- Language → English/한국어/中文 → PATCH uiLanguage.
- Active tutor → fetch /teachers, pick → PATCH activePersonaId.
- Font (Editorial/Modern/Friendly/Classic), Default mode (Chat/Face), Bubble style
  (Classic/Modern/Tail/Soft/Notebook) → local value update (QInputDialog list).
- Voice → info dialog (offline ASR+TTS via sherpa-onnx).
- Change password → dialog → PATCH currentPassword/newPassword. Sign out → red.

Each tile is now a clickable row (chevron + pointer cursor) wired to a handler;
tile() returns the value QLabel so the picker updates the shown value live.
setProfile seeds Theme/Language values from the loaded profile. Builds clean.

---

## Prompt

If i click each items on setting screen, they didn't reply, plz follow the flutter
windows
