# 19 — Avatar photo upload + scenario image rendering

Two related changes: app users can upload a profile photo; the
conversation brief screen now renders the admin-attached scenario
image.

## Backend

* Migration `1780800000000-user-avatar-image.ts` — adds
  `avatar_storage_key` and `avatar_url` columns to `vl_user_info`.
  Nullable; emoji fallback stays usable.
* `UserInfoEntity` gains the two columns.
* `UserProfileDto.avatarUrl` exposes the public URL to clients.
* New `POST /users/avatar` (multipart, field `file`) — image/jpeg
  | png | webp ≤ 5 MB, written to
  `<UPLOADS_DIR>/avatars/<user_id>.<ext>`. Mirrors
  `/uploads/avatars/<file>` into `vl_user_info.avatar_url` and
  returns the refreshed profile. Static mount in `main.ts`
  serves the file directly.
* `UsersService.setAvatar` writes both columns transactionally.

Scenario image upload was already shipped — `image_url` on
`vl_scenarios` plus `POST /admin/scenarios/:id/image` — so the
backend side of scenarios needed no change.

## Flutter

* `image_picker: ^1.1.2`.
* `UsersApi.uploadAvatar` — Dio multipart wrapper.
* `UserProfile.avatarUrl` (nullable) plumbed through `fromJson`.
* **Edit Profile dialog** (`edit_profile_dialog.dart`)
  * New "Photo" section with Camera / Gallery buttons (via
    `image_picker`).
  * Live `_AvatarPreview` widget that renders the uploaded
    photo over the emoji fallback. Spinner overlays the avatar
    while the upload is in flight.
  * Existing emoji picker stays — relabelled "Emoji fallback"
    so users understand the precedence.
  * Auth provider's `refreshProfile()` is awaited on success,
    so every `CircleAvatar` in the app picks up the new URL.
* **Scenario brief screen** — `_HeroCard` now drops an
  `Image.network` on top of the existing gradient when
  `scenario.imageUrl` is non-null. URLs are resolved against the
  backend origin (the `/api` and `/vfls` suffixes are stripped
  so the static mount at `/uploads/...` is reached directly).

## Admin display

`vl_user_info.avatar_url` is already returned by the existing
`/admin/users` list view (and the per-user GET), so the admin
panel needs no new endpoint; the existing render code can swap
to `NetworkImage(user.avatar_url)` when available — left as a
straightforward 2-line UI change in `admins`/`users` pages when
priorities allow.

Commit: `9e936df`.
