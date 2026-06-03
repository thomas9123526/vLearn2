# Conversation - Avatar image error fallback to emoji

| Field | Value |
|---|---|
| Saved | 2026-06-01 21:01:09 |
| Commit | fix: fall back to emoji when avatar NetworkImage fails (502/network error) |
| Project | C:\project\vLearn2 |

---

## User

(Pasted Flutter exception)

```
══╡ EXCEPTION CAUGHT BY IMAGE RESOURCE SERVICE ╞════════════════════════════════════════════════════
The following NetworkImageLoadException was thrown resolving an image codec:
HTTP request failed, statusCode: 502,
http://172.86.121.43/uploads/avatars/a93bc3c1-2595-4141-92b8-9347fd52b7f7.png
```

## Assistant

Both `CircleAvatar` widgets using `backgroundImage: NetworkImage(fullUrl)` had no error handler,
so a 502 (or any network failure) propagated as an unhandled Flutter exception.

**`_UserAvatarCircle`** (settings_screen.dart) was converted from `StatelessWidget` to
`StatefulWidget`. Added `_imageError` bool; `onBackgroundImageError` sets it to `true`, which
clears `fullUrl` and causes the `child` emoji to render instead.

**`_AvatarPreview`** (edit_profile_dialog.dart) was converted from `ConsumerWidget` to
`ConsumerStatefulWidget`. Same pattern, plus `didUpdateWidget` resets `_imageError` when
`avatarUrl` changes (after a fresh upload).

---

## Prompt

(Pasted Flutter exception about NetworkImageLoadException with statusCode: 502 on avatar URL)
