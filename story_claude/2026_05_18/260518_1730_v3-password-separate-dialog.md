# todoList/0518_v3 task 10 — Separate password change into its own dialog

## What this task did

Extracted the password change fields out of the "Edit profile" dialog and into a dedicated
"Change password" dialog, accessible via a new tile in the Settings → Account section.

### Edit profile dialog (trimmed)

`edit_profile_dialog.dart` — removed the three password controllers, their `dispose()`
calls, the password validation block in `_save()`, and the entire "Change password" UI
section. The dialog now only handles display name, avatar emoji, and gender.

### New change_password_dialog.dart

`showChangePasswordDialog(BuildContext)` opens a focused dialog with:
- Current password (autofocused on open)
- New password (≥ 8 chars validation)
- Confirm new password
- Keyboard-aware `insetPadding.bottom` (same approach as task 06)
- "done" on the confirm field keyboard action triggers save
- `PoliteBanner` for API errors

Calls `updateProfile({ currentPassword, newPassword })` — the existing API endpoint.

### Settings screen

Added import for `change_password_dialog.dart` and a `ListTile` (lock icon + chevron) in
the Account section, just above Sign out.

## Files

| Path | Change |
|------|--------|
| [flutter_app/lib/features/settings/edit_profile_dialog.dart](../flutter_app/lib/features/settings/edit_profile_dialog.dart) | Removed password fields, controllers, validation |
| [flutter_app/lib/features/settings/change_password_dialog.dart](../flutter_app/lib/features/settings/change_password_dialog.dart) | New focused change-password dialog |
| [flutter_app/lib/features/settings/settings_screen.dart](../flutter_app/lib/features/settings/settings_screen.dart) | Import + "Change password" tile in Account section |
| [todoList_report/0518_v3/10_passwordagain.md](../todoList_report/0518_v3/10_passwordagain.md) | Task report |

## User prompt (verbatim)

> I want seperate password change function from edit user dialog of settings screens on application side.
> So on "Edit profile" dialog, don't show password fields.
> Instead, put seperate button on setting screens and if tap button for "Change Password", It shows dialogs to change passwords.
