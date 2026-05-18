# 06_password — Password fields obscured by Android keyboard

## Ask

> When the user tap edit profile at the settings screen of application, app shows dialog to edit user information. I can scroll down to see password area. But If i tap password textfield to change password, the android ime shows but i can't see the textfields that i interacting now.

## Root cause

Flutter's `Dialog` positions itself using a fixed `insetPadding`:

```dart
// Before
builder: (_) => const Dialog(
  insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 48),
  child: SizedBox(width: 460, child: _EditProfileBody()),
),
```

`insetPadding.bottom = 48` is hardcoded. When the Android IME opens (e.g., keyboard = 350 px tall), the keyboard occupies the bottom of the screen but the dialog's `insetPadding.bottom` stays at 48 — the dialog doesn't move up. The password `TextField`s at the bottom of the dialog's scroll content end up behind the keyboard with no way to scroll to them.

## Fix

The `showDialog` builder closure is rebuilt by Flutter whenever `MediaQuery` changes (including `viewInsets`). By reading `MediaQuery.viewInsetsOf(ctx).bottom` inside the builder and applying it to `insetPadding.bottom`, the dialog lifts itself above the keyboard as soon as the IME opens:

```dart
Future<void> showEditProfileDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
      return Dialog(
        insetPadding: EdgeInsets.fromLTRB(24, 48, 24, bottom > 0 ? bottom + 8 : 48),
        child: const SizedBox(width: 460, child: _EditProfileBody()),
      );
    },
  );
}
```

- `bottom > 0` — keyboard is open: dialog sits 8 px above the keyboard top edge.
- `bottom == 0` — keyboard is closed: original 48 px bottom gap preserved.

`Dialog` uses `AnimatedPadding` internally so the transition is smooth as the keyboard slides in/out.

The `SingleChildScrollView` inside `_EditProfileBody` already handles the scrollable content, so once the dialog is repositioned correctly, the user can scroll to the focused field naturally.

## Bonus fixes (same file)

| Issue | Fix |
|-------|-----|
| `RadioListTile.groupValue` / `.onChanged` deprecated in Flutter 3.32 | Wrapped `Column` of `RadioListTile`s in a `RadioGroup<String>` widget; moved the guard check inside the `onChanged` callback |
| Missing `const` on `_SectionLabel(...)` calls | Added `const` to all four `_SectionLabel` constructor calls |

## Files changed

| File | Change |
|------|--------|
| [flutter_app/lib/features/settings/edit_profile_dialog.dart](../../flutter_app/lib/features/settings/edit_profile_dialog.dart) | Dynamic `insetPadding.bottom` in dialog builder; `RadioGroup` wrapper; `const` annotations |
