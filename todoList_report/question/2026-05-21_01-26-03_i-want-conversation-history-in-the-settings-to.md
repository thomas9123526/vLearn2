# I want "conversation history" in the settings to be relocated. I want "conversat

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-20T16:26:03.014Z

## User

I want "conversation history" in the settings to be relocated.
I want "conversation history" on the left side of the windows
I want "history" on the bottom tab of the android.

## Assistant

Let me find the current "conversation history" entry in settings and the tab structure.

## Assistant

Plan: lift Conversation history to a top-level tab (sidebar item on desktop, bottom tab on mobile). The user wants different labels per platform ("Conversation history" desktop, "History" mobile), so I'll add a `desktopLabel` to `_TabSpec`.

## Assistant

Right — need to define `desktopLabel` on `_TabSpec` and have the sidebar use it.

## Assistant

Now update the sidebar item to use `desktopLabel`.

## Assistant

Now move the conversation history route inside the shell, add the layout flag, drop the back arrow on the screen, and remove the settings entry.

## Assistant

I need to add it inside the ShellRoute. Let me put it back in the right place.

## Assistant

Now drop the back arrow on the conversation history screen (it's a tab now, not a pushed screen), then remove the settings entry, then update the layout flag defaults.

## Assistant

Good — `go_router` is still used for `context.push`. Now remove the settings entry and update the layout flag defaults.

## Assistant

Neither is used elsewhere. Remove both imports.

## Assistant

Now update layout config defaults — add `tabs.history`, drop the now-orphaned `conversation.history`.

## Assistant

Update the backend seed and admin flag catalog to keep them in sync.

## Assistant

Verify Flutter analysis is clean.

## Assistant

Clean. Commit + story log.

## Assistant

Done — committed as `f2b8628`.

**Summary**:
- **AppShell** ([app_shell.dart](flutter_app/lib/shared/widgets/app_shell.dart)) — added History to `_allTabs` between Scenarios and Progress. `_TabSpec` now has an optional `desktopLabel`, so the desktop sidebar shows "Conversation history" and the mobile bottom-nav shows "History" from the same single spec.
- **Router** ([app_router.dart](flutter_app/lib/core/router/app_router.dart)) — moved `/conversations/history` from a top-level fullscreen route into the `ShellRoute` so it renders inside the sidebar/bottom-nav chrome.
- **Screen** ([conversation_history_screen.dart](flutter_app/lib/features/conversation/conversation_history_screen.dart)) — dropped the AppBar back arrow (nothing to pop when it's a tab).
- **Settings** ([settings_screen.dart](flutter_app/lib/features/settings/settings_screen.dart)) — deleted the ListTile + its `LayoutVisibility` wrapper, plus two now-unused imports.
- **Layout flag** — new `tabs.history` (default `true`) added to: Flutter baked defaults, backend seed, admin flag catalog. The old `conversation.history` flag (only consumer was the deleted Settings entry) is gone from all three.

`flutter analyze` clean across all touched files. Note the backend seed change requires a re-seed for the new flag to appear in the DB; existing `conversation.history` rows are harmless and can be purged from the admin UI if you want.
