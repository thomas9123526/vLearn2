# more.txt — admin News, layout flags, edit-profile dialog

Three follow-ups from `todoList/0518_v2/more.txt`.

## 1 — Admin News "New post" button works

### Ask

> in admin panel, On news tab. "New Post" is not working. admin can post news with title and description.

### Why it didn't work

The button on `/news` linked to `/news/new`, but that route had no `page.tsx` — Next.js 404'd silently from the user's perspective.

### What's there now

[admin_panel/src/app/(dashboard)/news/new/page.tsx](../../admin_panel/src/app/(dashboard)/news/new/page.tsx) — full form using the same RHF + Zod pattern as the scenario-create flow. Fields:

- Slug (validated lowercase + dashes; uniqueness enforced server-side)
- Pinned checkbox
- Title (en required, ko/zh optional)
- Body (en required, ko/zh optional, multi-line textareas)
- Summary (all locales optional)

Submits to `POST /admin/news` (already existed). Posts land in `status: 'draft'` so an admin still has to hit Publish on the list page — matches the existing workflow.

## 2 — Config flags grouped by app tab, big sections first

### Ask

> At the "Config flags" tab on admin panel, you put all the possible visibility flags. This is complex for me. I want construct visible flags for big layouts in applications screen. I want visible flags for all tabs. and Inside the each tabs, put flags for big layout for its tab.

### Before

`/config` page rendered every flag from `GET /admin/config` flat, grouped only by the loose `category` column. 40+ rows in one giant scroll.

### After

Two new pieces working together:

- **[admin_panel/src/lib/flag-catalog.ts](../../admin_panel/src/lib/flag-catalog.ts)** — hardcoded catalog mapping each flag key to:
  - `tab`: which app screen it belongs to (`home`, `scenarios`, `conversation`, `progress`, `settings`, `report`, `system`)
  - `tier`: `big` (prominent layout block) vs `fine` (sub-knob)
  - `label`: human-readable name shown in the admin UI
- **[admin_panel/src/app/(dashboard)/config/page.tsx](../../admin_panel/src/app/(dashboard)/config/page.tsx)** — rebuilt with a tab strip across the top (one tab per app screen). Each tab shows its **Big sections** card up front, with an **Advanced (N)** expander below for the fine-tier flags.

```
┌─────────────────────────────────────────────────┐
│ Layout flags                                    │
│ Show or hide big sections of the app, …         │
├─────────────────────────────────────────────────┤
│ [ Home ] [ Scenarios ] [ Conversation ] [ … ]   │
│                                                 │
│ Daily dashboard — what the user sees on launch. │
│                                                 │
│ ┌── Big sections ────────────────────────────┐  │
│ │  Greeting header                  [✓]      │  │
│ │  Streak banner                    [✓]      │  │
│ │  News strip                       [✓]      │  │
│ │  Quick stats row                  [✓]      │  │
│ │  Recommended scenarios            [✓]      │  │
│ └────────────────────────────────────────────┘  │
│                                                 │
│ ▶ Advanced (4)                                  │
└─────────────────────────────────────────────────┘
```

Drift handling: if `GET /admin/config` returns a key the catalog doesn't list yet, it falls into a yellow "Uncategorized flags" card so nothing silently disappears — pairs with a hint to add it to `flag-catalog.ts`.

### Bonus

- New `LayoutVisibility` wrappers added to [progress_screen.dart](../../flutter_app/lib/features/progress/progress_screen.dart) (CEFR card, activity, skills, completions) so the big-tier toggles actually affect the app — not just sit in the admin DB.

## 3 — Edit-profile dialog on Settings

### Ask

> at settings screen of application. There should be edit profile function to change user's gender, password, photo, etc. I want show dialog when the user tap profile item on settings screen.

### What changed

Tapping the profile tile in [settings_screen.dart](../../flutter_app/lib/features/settings/settings_screen.dart) now opens an in-place dialog ([edit_profile_dialog.dart](../../flutter_app/lib/features/settings/edit_profile_dialog.dart)) with three sections:

| Section | What it does |
|---------|--------------|
| Display name | Updates `displayName` |
| Avatar | Free-form emoji field + 18-emoji quick-pick grid. Note: photo upload isn't wired (no storage backend for user avatars yet); copy makes this explicit |
| Gender | Radio group — Female / Male / Non-binary / Prefer not to say |
| Change password | Three fields: current password, new password (≥8), confirm. Section is optional — leaving new password blank skips password update entirely |

Save uses the existing `PATCH /users/profile`, then calls `authProvider.refreshProfile()` so the profile tile updates in place after the dialog dismisses.

### Backend changes

- **Migration** [1779700000000-users-gender.ts](../../backend/src/database/migrations/1779700000000-users-gender.ts) — adds `users.gender VARCHAR(20) NOT NULL DEFAULT 'unspecified'`
- **Entity** [user.entity.ts](../../backend/src/database/entities/user.entity.ts) — new `gender` column
- **DTO** [user.dto.ts](../../backend/src/users/dto/user.dto.ts) — `UserProfileDto.gender`; `UpdateProfileDto.gender`, `newPassword`, `currentPassword`
- **Service** [users.service.ts](../../backend/src/users/users.service.ts) — handles `gender`, and for password change: requires `currentPassword`, verifies via bcrypt (proves caller controls the account, not just the access token), hashes new password with the same `BCRYPT_ROUNDS = 10` as signup, then saves. Re-queries the user with `select: ['id', 'password_hash']` because the column is `select: false` by default

### Frontend model

- [models.dart](../../flutter_app/lib/core/models/models.dart) — `UserProfile.gender` field, defaults to `'unspecified'` on missing JSON

### Notes

- The migration must be run (`npm run db:migrate`) before the dialog can save gender — without it, the `gender` column doesn't exist and the PATCH fails. The Flutter side reads gender with a `?? 'unspecified'` fallback so existing builds still parse profiles fine.
- Real photo upload (camera/gallery → multipart upload → static-served URL) is a meaningful chunk of work — out of scope for this dialog. The emoji-picker UX is what the existing design wants anyway.
