# todoList/0518_v3 tasks 04–06 — tutor edit, theme swatches, keyboard fix

## What this task did

Three tasks from `todoList/0518_v3/` (files 04, 05, 06).

### 04 — Admin panel Edit button for tutors

The personas list page had the name column linked to the edit page, but no explicit "Edit" button — only Deactivate/Restore in the actions cell. Added a `Pencil` icon button that links to `/personas/[id]`, gated by the existing `canEdit` permission check, sitting alongside the status-change buttons.

### 05 — Theme picker with color swatches

The theme picker bottom sheet was plain text labels. Rebuilt as a visual card-per-theme using `AppPalette.byKey[themeKey]` so each option shows its real colors:
- Card background = `palette.background`
- Three decreasing color dots: primary (28px) → accent (20px) → surfaceVariant (14px, bordered)
- Theme name in `palette.onSurface`
- 2px primary-colored border + check icon when selected

Two new private widgets added: `_ThemeTile` and `_Dot`.

### 06 — Keyboard covers password fields in edit profile dialog

When the Android IME opens over the edit-profile dialog, the fixed `insetPadding.bottom: 48` didn't shift the dialog — the password fields disappeared under the keyboard.

Fix: the `showDialog` builder now reads `MediaQuery.viewInsetsOf(ctx).bottom` and sets `insetPadding.bottom = keyboard_height + 8` when the keyboard is open. Since `Dialog` uses `AnimatedPadding` internally, the dialog slides up smoothly as the keyboard rises.

Also fixed in the same file: `RadioListTile.groupValue`/`onChanged` deprecated in Flutter 3.32 → wrapped in `RadioGroup<String>`; added missing `const` to `_SectionLabel` constructor calls.

## Files

| Path | Change |
|------|--------|
| [admin_panel/src/app/(dashboard)/personas/page.tsx](../admin_panel/src/app/(dashboard)/personas/page.tsx) | `Pencil` import + Edit button in actions column |
| [flutter_app/lib/features/settings/settings_screen.dart](../flutter_app/lib/features/settings/settings_screen.dart) | `app_tokens.dart` import; `_pickTheme` → visual tiles; `_ThemeTile` + `_Dot` widgets |
| [flutter_app/lib/features/settings/edit_profile_dialog.dart](../flutter_app/lib/features/settings/edit_profile_dialog.dart) | Dynamic `insetPadding.bottom`; `RadioGroup` wrapper; `const` |
| [todoList_report/0518_v3/04_tutor_edit.md](../todoList_report/0518_v3/04_tutor_edit.md) | Task report |
| [todoList_report/0518_v3/05_settings_theme.md](../todoList_report/0518_v3/05_settings_theme.md) | Task report |
| [todoList_report/0518_v3/06_password.md](../todoList_report/0518_v3/06_password.md) | Task report |

## User prompt (verbatim)

> For files from 04 to 06 inside todoList\0518_v3 folder, read it and do what they said.
> After you have done task, produce report what you have done and save as md format to "todoList_report\0518_v3" folder.
