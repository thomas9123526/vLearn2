# Conversation - fix: fall back to emoji when avatar NetworkImage fails (502/network error)

| Field | Value |
|---|---|
| Saved | 2026-06-01 21:01:30 |
| Commit | fix: fall back to emoji when avatar NetworkImage fails (502/network error) |
| Project | C:\project\vLearn2 |

---

## User

<ide_opened_file>The user opened the file c:\project\vLearn2\backend\src\ai\prompt-builder.service.ts in the IDE. This may or may not be related to the current task.</ide_opened_file>

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

## Claude

Let me find where avatar images are loaded in the Flutter app.

**Tool - Grep**

```
c:\project\vLearn2\flutter_app\lib
```

**Result**

```
Found 4 files
flutter_app\lib\features\settings\edit_profile_dialog.dart
flutter_app\lib\features\settings\settings_screen.dart
flutter_app\lib\features\scenarios\scenario_brief_screen.dart
flutter_app\lib\core\models\models.dart
```

**Tool - Grep**

```
c:\project\vLearn2\flutter_app\lib
```

**Result**

```
flutter_app\lib\core\api\app_apis.dart:23:  /// Multipart upload of the user's avatar photo. Returns the
flutter_app\lib\core\api\app_apis.dart:24:  /// updated profile (with avatarUrl populated).
flutter_app\lib\core\api\app_apis.dart:33:      '/users/avatar',
flutter_app\lib\core\models\models.dart:9:    required this.avatarEmoji,
flutter_app\lib\core\models\models.dart:10:    this.avatarUrl,
flutter_app\lib\core\models\models.dart:27:    avatarEmoji: j['avatarEmoji'] as String? ?? '🐣',
flutter_app\lib\core\models\models.dart:28:    avatarUrl: j['avatarUrl'] as String?,
flutter_app\lib\core\models\models.dart:44:  final String avatarEmoji;
flutter_app\lib\core\models\models.dart:47:  /// e.g. `/uploads/avatars/<id>.jpg`. Null = use [avatarEmoji].
flutter_app\lib\core\models\models.dart:48:  final String? avatarUrl;
flutter_app\lib\core\models\models.dart:105:  /// `'female' | 'male' | 'neutral'`. Drives the avatar animation set
flutter_app\lib\core\models\models.dart:113:  /// `.riv` filename under `assets/animations/` for the avatar. Null
flutter_app\lib\features\settings\settings_screen.dart:744:/// Profile tile avatar: shows the uploaded photo (rounded circle) when
flutter_ap
...[truncated]
```

## Claude

Let me read the relevant sections in both files.

**Tool - Read**

```
c:\project\vLearn2\flutter_app\lib\features\settings\settings_screen.dart
```

**Result**

```
740	    );
741	  }
742	}
743	
744	/// Profile tile avatar: shows the uploaded photo (rounded circle) when
745	/// avatar_url is set; falls back to the emoji avatar otherwise.
746	class _UserAvatarCircle extends StatelessWidget {
747	  const _UserAvatarCircle({required this.user});
748	
749	  final UserProfile user;
750	
751	  String? _resolveUrl(String relative) {
752	    if (relative.startsWith('http')) return relative;
753	    final base = AppConfig.defaults.backendBaseUrl;
754	    final idx = base.indexOf('/api');
755	    final idx2 = base.indexOf('/vfls');
756	    final origin =
757	        idx > 0 ? base.substring(0, idx) : (idx2 > 0 ? base.substring(0, idx2) : base);
758	    return '$origin$relative';
759	  }
760	
761	  @override
762	  Widget build(BuildContext context) {
763	    final scheme = Theme.of(context).colorScheme;
764	    final url = user.avatarUrl;
765	    final fullUrl = (url != null && url.isNotEmpty) ? _resolveUrl(url) : null;
766	
767	    return CircleAvatar(
768	      radius: 22,
769	      backgroundColor: scheme.primaryContainer,
770	      backgroundImage: fullUrl != null ? NetworkImage(fullUrl) : null,
771	      child: fullUrl == null
772	          ? Text(u
...[truncated]
```

**Tool - Read**

```
c:\project\vLearn2\flutter_app\lib\features\settings\edit_profile_dialog.dart
```

**Result**

```
355	  final bool uploading;
356	  final String fallbackEmoji;
357	  final ColorScheme scheme;
358	
359	  @override
360	  Widget build(BuildContext context, WidgetRef ref) {
361	    final url = user.avatarUrl as String?;
362	    // avatar_url comes from the backend as `/uploads/avatars/<file>`.
363	    // Prepend the Dio base URL so NetworkImage can resolve it.
364	    final fullUrl = (url != null && url.isNotEmpty)
365	        ? _resolveAvatarUrl(ref, url)
366	        : null;
367	
368	    return Stack(
369	      alignment: Alignment.center,
370	      children: [
371	        CircleAvatar(
372	          radius: 32,
373	          backgroundColor: scheme.primaryContainer,
374	          backgroundImage: fullUrl != null ? NetworkImage(fullUrl) : null,
375	          child: fullUrl == null
376	              ? Text(
377	                  fallbackEmoji.isEmpty ? '🐣' : fallbackEmoji,
378	                  style: const TextStyle(fontSize: 28),
379	                )
380	              : null,
381	        ),
382	        if (uploading)
383	          const SizedBox(
384	            width: 64,
385	            height: 64,
386	            child: CircularProgressIndicator(strokeWidth: 2.4),
387	      
...[truncated]
```

## Claude

Now let me check what class the edit_profile_dialog avatar widget is.

**Tool - Read**

```
c:\project\vLearn2\flutter_app\lib\features\settings\edit_profile_dialog.dart
```

**Result**

```
340	  }
341	}
342	
343	/// Round preview that mirrors what the rest of the app will render
344	/// after upload. While [uploading] is true the spinner sits over
345	/// whatever the current source is (uploaded photo > emoji).
346	class _AvatarPreview extends ConsumerWidget {
347	  const _AvatarPreview({
348	    required this.user,
349	    required this.uploading,
350	    required this.fallbackEmoji,
351	    required this.scheme,
352	  });
353	
354	  final dynamic user; // UserProfile — kept dynamic to avoid widening imports
355	  final bool uploading;
356	  final String fallbackEmoji;
357	  final ColorScheme scheme;
358	
359	  @override
```

## Claude

Both `CircleAvatar` widgets need error handling. I'll add `onBackgroundImageError` and convert the widgets to stateful ones to track image load failures.

**Tool - Edit**

```
c:\project\vLearn2\flutter_app\lib\features\settings\settings_screen.dart
```

**Result**

```
The file c:\project\vLearn2\flutter_app\lib\features\settings\settings_screen.dart has been updated successfully. (file state is current in your context — no need to Read it back)
```

**Tool - Edit**

```
c:\project\vLearn2\flutter_app\lib\features\settings\settings_screen.dart
```

**Result**

```
The file c:\project\vLearn2\flutter_app\lib\features\settings\settings_screen.dart has been updated successfully. (file state is current in your context — no need to Read it back)
```

## Claude

Now fix the same issue in the edit_profile_dialog's `_AvatarPreview`. That one is a `ConsumerWidget` — I'll convert it to a `ConsumerStatefulWidget` to track the error state.

**Tool - Read**

```
c:\project\vLearn2\flutter_app\lib\features\settings\edit_profile_dialog.dart
```

**Result**

```
343	/// Round preview that mirrors what the rest of the app will render
344	/// after upload. While [uploading] is true the spinner sits over
345	/// whatever the current source is (uploaded photo > emoji).
346	class _AvatarPreview extends ConsumerWidget {
347	  const _AvatarPreview({
348	    required this.user,
349	    required this.uploading,
350	    required this.fallbackEmoji,
351	    required this.scheme,
352	  });
353	
354	  final dynamic user; // UserProfile — kept dynamic to avoid widening imports
355	  final bool uploading;
356	  final String fallbackEmoji;
357	  final ColorScheme scheme;
358	
359	  @override
360	  Widget build(BuildContext context, WidgetRef ref) {
361	    final url = user.avatarUrl as String?;
362	    // avatar_url comes from the backend as `/uploads/avatars/<file>`.
363	    // Prepend the Dio base URL so NetworkImage can resolve it.
364	    final fullUrl = (url != null && url.isNotEmpty)
365	        ? _resolveAvatarUrl(ref, url)
366	        : null;
367	
368	    return Stack(
369	      alignment: Alignment.center,
370	      children: [
371	        CircleAvatar(
372	          radius: 32,
373	          backgroundColor: scheme.primaryContainer,
374	        
...[truncated]
```

**Tool - Edit**

```
c:\project\vLearn2\flutter_app\lib\features\settings\edit_profile_dialog.dart
```

**Result**

```
The file c:\project\vLearn2\flutter_app\lib\features\settings\edit_profile_dialog.dart has been updated successfully. (file state is current in your context — no need to Read it back)
```

## Claude

Now commit and save the story.

**Tool - Bash**

```
Get-Date -Format 'yyMMdd_HHmmss'
```

**Result**

```
Exit code 127
/usr/bin/bash: line 1: Get-Date: command not found
```

**Tool - PowerShell**

```
Get-Date -Format 'yyMMdd_HHmmss'
```

**Result**

```
260601_210109
```

**Tool - Write**

```
c:\project\vLearn2\story_claude\2026_06_01\260601_210109_Avatar_image_error_fallback_to_emoji.md
```

**Result**

```
File created successfully at: c:\project\vLearn2\story_claude\2026_06_01\260601_210109_Avatar_image_error_fallback_to_emoji.md (file state is current in your context — no need to Read it back)
```

**Tool - Bash**

```
git add flutter_app/lib/features/settings/settings_screen.dart flutter_app/lib/features/settings/edit_profile_dialog.dart story_claude/2026_06_01/260601_210109_Avatar_image_error_fallback_to_emoji.md && git commit -m "fix: fall back to emoji when avatar NetworkImage fails (502/network error)"
```

---

## User prompts (verbatim)

### Prompt 1

```
<ide_opened_file>The user opened the file c:\project\vLearn2\backend\src\ai\prompt-builder.service.ts in the IDE. This may or may not be related to the current task.</ide_opened_file>

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
```

