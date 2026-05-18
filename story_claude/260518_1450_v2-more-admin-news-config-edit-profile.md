# more.txt — admin News new-post, layout flag catalog, edit-profile dialog

## What this task did

Three things from `todoList/0518_v2/more.txt`:

1. **Admin News "New post" works** — added the missing `/news/new` page in the admin panel with a RHF + Zod form (slug, pinned, title/body/summary i18n). Submits to the existing `POST /admin/news` endpoint, posts start as drafts.

2. **Config flags reorganized** — replaced the flat 40-row list with a tab strip per app screen, showing "Big sections" toggles up front and an "Advanced" expander for fine-grained sub-knobs. Catalog lives in `admin_panel/src/lib/flag-catalog.ts` (hardcoded; admin panel knows the app's structure). Drift surfaced via a yellow "Uncategorized" card if the backend returns keys not in the catalog. Added `LayoutVisibility` wrappers around the four big sections of Progress so the toggles actually affect the running app.

3. **Edit-profile dialog on Settings** — tapping the profile tile now opens a dialog with display name + avatar emoji (free-form + 18-emoji quick-pick) + gender (radio: Female/Male/Non-binary/Prefer not to say) + optional password change (current + new + confirm). Backend got a `gender` column on `users` (migration `1779700000000-users-gender.ts`), `UpdateProfileDto` gained `gender`/`newPassword`/`currentPassword`, and `UsersService.updateProfile` now bcrypt-verifies the current password before hashing the new one. Flutter `UserProfile.gender` parses with an `'unspecified'` fallback so old builds still work pre-migration.

## Files

| Path | Change |
|------|--------|
| [admin_panel/src/app/(dashboard)/news/new/page.tsx](../admin_panel/src/app/(dashboard)/news/new/page.tsx) | NEW — RHF + Zod form for creating news posts |
| [admin_panel/src/lib/flag-catalog.ts](../admin_panel/src/lib/flag-catalog.ts) | NEW — flag → tab/tier/label catalog |
| [admin_panel/src/app/(dashboard)/config/page.tsx](../admin_panel/src/app/(dashboard)/config/page.tsx) | Tab strip + Big sections / Advanced layout |
| [flutter_app/lib/features/progress/progress_screen.dart](../flutter_app/lib/features/progress/progress_screen.dart) | Wrapped 4 big sections in `LayoutVisibility` |
| [flutter_app/lib/features/settings/edit_profile_dialog.dart](../flutter_app/lib/features/settings/edit_profile_dialog.dart) | NEW — dialog with display name, avatar, gender, password |
| [flutter_app/lib/features/settings/settings_screen.dart](../flutter_app/lib/features/settings/settings_screen.dart) | Profile tile → `showEditProfileDialog` |
| [flutter_app/lib/core/models/models.dart](../flutter_app/lib/core/models/models.dart) | `UserProfile.gender` |
| [backend/src/database/migrations/1779700000000-users-gender.ts](../backend/src/database/migrations/1779700000000-users-gender.ts) | NEW — `users.gender VARCHAR(20) NOT NULL DEFAULT 'unspecified'` |
| [backend/src/database/entities/user.entity.ts](../backend/src/database/entities/user.entity.ts) | `gender` column |
| [backend/src/users/dto/user.dto.ts](../backend/src/users/dto/user.dto.ts) | `gender`, `newPassword`, `currentPassword` on the update DTO |
| [backend/src/users/users.service.ts](../backend/src/users/users.service.ts) | Handles gender + bcrypt-verified password change |
| [todoList_report/0518_v2/more.md](../todoList_report/0518_v2/more.md) | Task report |

## Heads-up for deploy

The new `users.gender` column needs `npm run db:migrate` on the backend before the dialog can save gender. The Flutter side reads with a fallback so older builds still parse profiles correctly even pre-migration.

## User prompt (verbatim)

> continue and after finish above context, plz do the following
>
> 1. in admin panel, On news tab. "New Post" is not working. admin can post news with title and description.
>
> 2. At the "Config flags" tab on admin panel , you put all the possible visibility flags. This is complex for me.
>
> I want construct visible flags for big layouts in applications screen. I want visible flags for all tabs. and Inside the each tabs, put flags for big layout for its tab.
>
> 3. at settings screen of application. There should be edit profile function to change user's gender,password, photo, etc. I want show dialog when the user tap profile item on settings screen.
