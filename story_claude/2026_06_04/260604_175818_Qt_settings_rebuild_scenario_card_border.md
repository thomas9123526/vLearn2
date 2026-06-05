# Conversation - Qt settings rebuild + scenario card border

| Field | Value |
|---|---|
| Saved | 2026-06-04 17:58:18 |
| Commit | auto: rebuild Settings to match Flutter + color scenario card border |
| Project | C:\project\vLearn2 |

---

## User

Settings page doesn't match with the flutter windows application, Also scenario
item in home screen, looks bad for the ui. i think you can give some colors for
border.

## Assistant

Read the real settings_screen.dart structure and rebuilt SettingsPage to match:
profile tile (avatar + name + email) then sectioned list tiles —
- Appearance: Theme (Obsidian dark), Language (English)
- Font: Editorial
- Conversation: Default mode (Chat), Bubble style (Classic)
- Voice (our addition): speech-model status from AsrService/TtsService availability
- Account: Change password (opens a dialog → PATCH /users/profile with
  currentPassword/newPassword), Sign out (red, functional)

Each tile = leading icon glyph + title (+ value subtitle) + chevron for actionable
rows, in Card frames under mono section headers — mirroring the Flutter ListTile
layout.

Supporting changes: UserProfile model gained email/uiLanguage/activeTheme;
ApiClient.updateProfile (PATCH /users/profile); setProfile now shows the email.

Scenario cards: gave #ScenarioCard a periwinkle-tinted border
(rgba(157,153,199,0.35)) with a brighter accent2 border + surfaceAlt fill on hover,
so the cards read clearly on the dark background (Home + Scenarios).

Builds clean; headless smoke OK.

---

## Prompt

Settings page doesn't match with the flutter windows application, Also scenario
item in home screen, looks bad for the ui. i think you can give some colors for
border.
