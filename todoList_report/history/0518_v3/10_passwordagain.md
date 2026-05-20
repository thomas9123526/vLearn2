# 10_passwordagain — Separate password change from Edit Profile dialog

## Ask

> I want separate password change function from edit user dialog of settings screens on
> application side. So on "Edit profile" dialog, don't show password fields. Instead, put
> separate button on setting screens and if tap button for "Change Password", it shows
> dialogs to change passwords.

---

## Before

The "Edit profile" dialog had four sections in one scrollable flow:
1. Display name
2. Avatar emoji
3. Gender
4. Change password (current + new + confirm fields)

The password fields were at the bottom. Scrolling past them after every name/gender edit
was unnecessary friction, and the keyboard-covering bug from task 06 was worst there.

## After

### Edit Profile dialog — password section removed

`edit_profile_dialog.dart` now only handles display name, avatar, and gender.
Removed:
- `_currentPwCtrl`, `_newPwCtrl`, `_confirmPwCtrl` controllers + their `dispose()` calls
- Password validation logic in `_save()`
- The "Change password" section in `build()`

### New `change_password_dialog.dart`

Standalone dialog with a focused 3-field layout:
- Current password (autofocused)
- New password (≥ 8 chars)
- Confirm new password

Keyboard-aware: same `MediaQuery.viewInsetsOf(ctx).bottom` insetPadding trick as the
edit-profile dialog so fields stay visible on Android when the IME opens.

Submitting with the keyboard's "done" action on the confirm field triggers save directly.

Calls `usersApiProvider.updateProfile({ currentPassword, newPassword })` — the same API
endpoint that the old combined dialog used.

### Settings screen — new tile in Account section

```
Account
  ──────────────────────────────────────
  🔒  Change password          ›
  ──────────────────────────────────────
  🚪  Sign out
```

`ListTile` with `Icons.lock_outline` placed just above Sign out, calls
`showChangePasswordDialog(context)` on tap.

## Files changed

| File | Change |
|------|--------|
| [flutter_app/lib/features/settings/edit_profile_dialog.dart](../../flutter_app/lib/features/settings/edit_profile_dialog.dart) | Removed all password fields, controllers, and validation |
| [flutter_app/lib/features/settings/change_password_dialog.dart](../../flutter_app/lib/features/settings/change_password_dialog.dart) | New file — focused change-password dialog |
| [flutter_app/lib/features/settings/settings_screen.dart](../../flutter_app/lib/features/settings/settings_screen.dart) | Added `change_password_dialog.dart` import + "Change password" tile |
