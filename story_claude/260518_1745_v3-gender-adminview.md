# todoList/0518_v3 tasks 11–12 — Gender options trim, collapsible admin cards

## What this task did

### 11 — Gender options: 4 → 2

`edit_profile_dialog.dart` `_genders` reduced from four entries (female, male, non-binary,
prefer-not-to-say) to two (female, male).

Default and `initState` guard updated: any stored value that isn't `'male'` or `'female'`
(old `'nonbinary'` / `'unspecified'`) falls back to `'female'` so the `RadioGroup` always
has a valid selection.

### 12 — Admins page: simple list with expandable cards

The Admins tab used to show `PermissionGrid` checkboxes always-open for every admin,
making the page very tall. Each admin card is now collapsed by default — the header shows
name, email, role, status, and Suspend/Restore buttons. A chevron button (visible only
when the viewer has `canGrant` permission or the row is a superadmin) toggles the
`CardContent` open to show the full `PermissionGrid`.

The per-row logic was extracted into a new `AdminCard` function component with its own
`expanded` state. Status gets a colour-coded label (green/yellow/muted). `PermissionGrid`
and `CreateSubAdminForm` are unchanged.

## Files

| Path | Change |
|------|--------|
| [flutter_app/lib/features/settings/edit_profile_dialog.dart](../flutter_app/lib/features/settings/edit_profile_dialog.dart) | `_genders` → 2 entries; default + guard → `'female'` |
| [admin_panel/src/app/(dashboard)/admins/page.tsx](../admin_panel/src/app/(dashboard)/admins/page.tsx) | `AdminCard` component with `expanded` toggle; `ChevronDown`/`ChevronUp` |
| [todoList_report/0518_v3/11_gender.md](../todoList_report/0518_v3/11_gender.md) | Task report |
| [todoList_report/0518_v3/12_adminview.md](../todoList_report/0518_v3/12_adminview.md) | Task report |

## User prompt (verbatim)

> For files from 11 to 12 inside todoList\0518_v3 folder, read it and do what they said.
> After you have done task, produce report what you have done and save as md format to "todoList_report\0518_v3" folder.
> md filename can be xxx.md where xxx means the current todo file name.
> You are an expert fullstack developer.
> Don't ask me anything. Go automatically without my choice or answer. You do it by yourself and by your decision.
> You have many times. take it easy. Quality is important.
