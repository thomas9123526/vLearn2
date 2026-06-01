# Conversation - Admin conversation mode config

| Field | Value |
|---|---|
| Saved | 2026-06-01 15:15:27 |
| Commit | Add conversation.mode config: tutor/message/both with admin UI and Flutter enforcement |
| Project | C:\project\vLearn2 |

---

## User

In the admin panel, I want put configuration in http://localhost:4101/vAdmin/config/ page.

So three options:
Tutor Mode, Message Mode, Both Mode.

The admin should choose one at least. the default is Both Mode.
If the admin check message mode then the application should only show message mode conversation screen. There's no toggle button.
If the admin check Tutor mode then the application should only show Tutor mode character screen. There's no toggle button.
If the admin check Both mode, the application should show both along with the toggle button.

## Assistant

Implemented `conversation.mode` as a new string config key (`tutor` | `message` | `both`, default `both`) across the full stack:

**Backend seed** (`app-config.seed.ts`): Added `conversation.mode` with `value_type: 'string'`, `is_visible_to_app: true`, default `'both'`.

**Admin flag catalog** (`flag-catalog.ts`): Extended `FlagDescriptor` with `type?: 'boolean' | 'select'` and `options?: readonly string[]`. Replaced the old `conversation.face_mode_available` and `conversation.mode_toggle` catalog entries with a single `conversation.mode` select entry.

**Admin config page** (`config/page.tsx`): `FlagRow` now renders a pill-button group for `type: 'select'` flags — clicking a pill PATCHes the value immediately. The active option is highlighted in primary color.

**Flutter layout defaults** (`layout_config_provider.dart`): Added `'conversation.mode': 'both'` to baked defaults so the app works correctly even when offline.

**TutorModeView / _TutorTopBar** (`tutor_mode_view.dart`): Made `onSwitchToChat` nullable (`VoidCallback?`). The switch-to-chat icon button is hidden when the callback is null.

**ConversationScreen** (`conversation_screen.dart`): Reads `conversationMode` from `layoutConfigProvider`. An `effectiveMode()` local function maps `tutor`→`face`, `message`→`chat`, `both`→user toggle or session default. The AppBar toggle button is only shown when `conversationMode == 'both'`, and `onSwitchToChat` is passed as `null` to `_TutorModeWrapper` when locked to tutor-only mode.

---

## Prompt

In the admin panel, I want put configuration in http://localhost:4101/vAdmin/config/ page.

So three options:
Tutor Mode, Message Mode, Both Mode.

The admin should choose one at least. the default is Both Mode.
If the admin check message mode then the application should only show message mode conversation screen. There's no toggle button.
If the admin check Tutor mode then the application should only show Tutor mode character screen. There's no toggle button.
If the admin check Both mode, the application should show both along with the toggle button.
