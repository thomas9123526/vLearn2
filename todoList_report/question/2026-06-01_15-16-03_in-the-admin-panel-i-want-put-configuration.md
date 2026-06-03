# In the admin  panel, I want put configuration in http://localhost:4101/vAdmin/co

Session: `0c373469-dea6-47f9-ba6b-d5f7b4449689`
Saved: 2026-06-01T06:16:03.711Z

## User

In the admin  panel, I want put configuration in http://localhost:4101/vAdmin/config/ page.

So three options 
Tutor Mode,
Message Mode,
Both Mode.

The admin should choose one at least. the default is Both Mode.
If the admin check message mode then the application should only show message mode conversation screen. There's no toggle button.
If the admin check Tutor mode then the application should only show Tutor mode character screen. There's no toggle button.
If the admin check Both mode, the application should show both along with the toggle button.

## Assistant

Let me explore both the admin panel and Flutter app to understand the current structure.

## Assistant

Now let me read the key files in detail before implementing.

## Assistant

Now let me read the Flutter conversation screen:

## Assistant

Let me read the tutor mode view widget and the `_TutorModeWrapper`:

## Assistant

Let me see where `onSwitchToChat` is used in the tutor mode view:

## Assistant

Now I have a complete picture. Here's what needs to change across 6 files:

1. **Seed** — add `conversation.mode` string flag
2. **Flag catalog** — add `type/options` to descriptor, add select entry, drop superseded toggles
3. **Config page** — render pill-button group for `type: 'select'` flags
4. **Flutter layout defaults** — bake in `conversation.mode: 'both'`
5. **TutorModeView** — make `onSwitchToChat` nullable, hide button when null
6. **ConversationScreen** — read `conversationMode`, enforce it

## Assistant

Now update the config page `FlagRow` to render pill buttons for `type: 'select'`:

## Assistant

Now update Flutter baked defaults and the conversation screen. Starting with the layout config provider:

## Assistant

Now make `onSwitchToChat` nullable in `TutorModeView` and `_TutorTopBar`:

## Assistant

Need to make `_TutorTopBar.onSwitchToChat` nullable too and conditionally hide the button:

## Assistant

Now hide the switch-to-chat button when `onSwitchToChat` is null:

## Assistant

Now update `_TutorModeWrapper` to accept a nullable `onSwitchToChat`, then update `ConversationScreen` to read `conversationMode` and enforce it:

## Assistant

Now update the `build` method in `_ConversationScreenState` to read `conversationMode` and enforce it. First add the import:

## Assistant

The import will be used once I update the `build` method. Now rewrite the core `build` logic to enforce `conversationMode`:

## Assistant

Now commit everything:

## Assistant

Done. Here's a summary of what was built:

**Admin panel** (`/vAdmin/config/` → Conversation tab):
- A new `conversation.mode` flag replaces the old separate `face_mode_available` / `mode_toggle` booleans
- Renders as a pill-button group: **Tutor** | **Message** | **Both** — click any pill to save immediately

**Flutter app** enforces the setting:
- `tutor` → conversation always opens in face/tutor mode, the switch-to-chat button is hidden
- `message` → always chat mode, the tutor-mode toggle in the AppBar is hidden
- `both` → existing behavior: toggle button visible, user can switch freely

**Run `npm run db:seed`** (in the backend) to insert the new `conversation.mode` key into the database.
