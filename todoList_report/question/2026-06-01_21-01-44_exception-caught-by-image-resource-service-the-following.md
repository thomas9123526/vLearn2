# ══╡ EXCEPTION CAUGHT BY IMAGE RESOURCE SERVICE ╞════════════════════════════════

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-01T12:01:44.696Z

## User

══╡ EXCEPTION CAUGHT BY IMAGE RESOURCE SERVICE ╞════════════════════════════════════════════════════
The following NetworkImageLoadException was thrown resolving an image codec:
HTTP request failed, statusCode: 502,
http://172.86.121.43/uploads/avatars/a93bc3c1-2595-4141-92b8-9347fd52b7f7.png

When the exception was thrown, this was the stack:
#0      NetworkImage._loadAsync (package:flutter/src/painting/_network_image_io.dart:131:9)
<asynchronous suspension>
#1      MultiFrameImageStreamCompleter._handleCodecReady (package:flutter/src/painting/image_stream.dart:1021:3)
<asynchronous suspension>

Image provider:
  NetworkImage("http://172.86.121.43:80/uploads/avatars/a93bc3c1-2595-4141-92b8-9347fd52b7f7.png",
  scale: 1.0, webHtmlElementStrategy: never, headers: null)
Image key:
  NetworkImage("http://172.86.121.43:80/uploads/avatars/a93bc3c1-2595-4141-92b8-9347fd52b7f7.png",
  scale: 1.0, webHtmlElementStrategy: never, headers: null)

## Assistant

Let me find where avatar images are loaded in the Flutter app.

## Assistant

Let me read the relevant sections in both files.

## Assistant

Now let me check what class the edit_profile_dialog avatar widget is.

## Assistant

Both `CircleAvatar` widgets need error handling. I'll add `onBackgroundImageError` and convert the widgets to stateful ones to track image load failures.

## Assistant

Now fix the same issue in the edit_profile_dialog's `_AvatarPreview`. That one is a `ConsumerWidget` — I'll convert it to a `ConsumerStatefulWidget` to track the error state.

## Assistant

Now commit and save the story.

## Assistant

Both avatar widgets now handle image load failures gracefully:

- **[settings_screen.dart:767](flutter_app/lib/features/settings/settings_screen.dart#L767)** — `_UserAvatarCircle` converted to `StatefulWidget`; `onBackgroundImageError` sets `_imageError = true`, which clears the URL so the emoji child renders instead.
- **[edit_profile_dialog.dart:346](flutter_app/lib/features/settings/edit_profile_dialog.dart#L346)** — `_AvatarPreview` converted to `ConsumerStatefulWidget` with the same pattern, plus `didUpdateWidget` resets the error flag when `avatarUrl` changes after a successful upload.
