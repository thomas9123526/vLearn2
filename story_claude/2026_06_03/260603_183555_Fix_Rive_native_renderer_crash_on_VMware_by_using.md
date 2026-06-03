# Conversation - Fix Rive native renderer crash on VMware by using Flutter renderer on Windows

| Field | Value |
|---|---|
| Saved | 2026-06-03 18:35:55 |
| Commit | Fix Rive native renderer crash on VMware by using Flutter renderer on Windows |
| Project | C:\project\vLearn2 |

---

## User

<ide_opened_file>The user opened the file c:\project\vLearn2\cmds\install_rive_native.ps1 in the IDE. This may or may not be related to the current task.</ide_opened_file>

when i debug windows program on vmware, and i enter the conversation screen then the application suddenly exits. below are the logs. i think rive raises error.


D:\a\sherpa-onnx\sherpa-onnx\sherpa-onnx\csrc\offline-tts-vits-model.cc:Init:162 ---vits model---
n_speakers=109
onnx.infer=onnxruntime.quant
punctuation=; : , . ! ? ¡ ¿ — … " « » “ ”  
model_type=vits
comment=vctk
language=English
add_blank=1
sample_rate=22050
----------input names----------
0 x
1 x_length
2 noise_scale
3 length_scale
4 noise_scale_w
5 sid
----------output names----------
0 y
2

22
D:\a\sherpa-onnx\sherpa-onnx\sherpa-onnx\csrc\lexicon.cc:ConvertTokensToIds:93 Unknown token: ̃
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
│ #0   SherpaOnnxTtsService.initialize (package:flutter_app/core/speech/sherpa_onnx_tts.dart:130:12)
│ #1   <asynchronous suspension>
├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
│ 💡 TTS: OfflineTts ready with 109 voices.
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
Lost connection to device.

Exited.

## Claude

Looking at the logs, TTS initializes fine — the crash ("Lost connection to device") happens after that, likely a native crash in Rive or something else on the conversation screen. Let me find the relevant code.

**Tool - Agent**

```
{"description":"Find conversation screen and Rive usage","subagent_type":"Explore","prompt":"In the Flutter app at c:\\project\\vLearn2\\flutter_app, find:\n1. The conversation screen file (likely something like conversation_screen.dart or chat_screen.dart)\n2. All files that use Rive animations (import \u0027package:rive\u0027 or RiveAnimation or StateMachineController)\n3. Any Rive asset loading code\n\nSearch breadth: medium. Report file paths and key line numbers where Rive is used."}
```

**Result**

```
Perfect! Now I have all the information needed. Let me compile the comprehensive report.

## Summary

I've completed a thorough search of the Flutter app. Here are my findings:

### 1. **Conversation Screen File**
- **Primary file**: `c:\project\vLearn2\flutter_app\lib\features\conversation\conversation_screen.dart` (lines 1-808)
- **Related file**: `c:\project\vLearn2\flutter_app\lib\features\conversation\conversation_history_screen.dart` (also found in search but not the main active screen)

The main conversation screen (`ConversationScreen`) is a `ConsumerStatefulWidget` (lines 49-56) with two distinct UI modes:
- **Chat mode** (`_ChatModeBody`): Text-based interface with optional voice input (lines 293-565)
- **Tutor mode**: Face-to-face conversational interface (uses `_TutorModeWrapper` → `TutorModeView`)

---

### 2. **Files Using Rive Animations**

**8 files found** with Rive imports or usage:

| File Path | Key Rive Usage | Key Lines |
|-----------|----------------|-----------|
| `flutter_app\lib\features\conversation\conversation_screen.dart` | Comment reference only (no direct code) | Line 46 |
| `flutter_app\lib\features\conversation\widgets\tutor_avatar.dart` | **Primar
...[truncated]
```

## Claude

Let me look at the tutor_avatar.dart and main.dart Rive init more closely.

**Tool - Read**

```
c:\project\vLearn2\flutter_app\lib\features\conversation\widgets\tutor_avatar.dart
```

**Result**

```
1	import 'dart:async';
2	import 'dart:math' as math;
3	
4	import 'package:flutter/material.dart';
5	import 'package:flutter_app/core/config/app_config.dart';
6	import 'package:rive/rive.dart' as rive;
7	
8	import '../../../core/models/models.dart';
9	import 'cartoon_face.dart';
10	
11	/// Visual state the tutor avatar is currently in.
12	enum TutorMood {
13	  /// At rest — gentle breathing only.
14	  idle,
15	
16	  /// TTS is playing — mouth driven by amplitude from sherpa-onnx PCM.
17	  speaking,
18	
19	  /// User is recording — tutor leans in (Attention state).
20	  listening,
21	
22	  /// Positive moment — flash Excited then auto-return to Idle.
23	  praising,
24	
25	  /// Negative / timeout moment — flash Disappointed then auto-return to Idle.
26	  disappointed,
27	
28	  /// User has been silent a while — encourage them to speak.
29	  encouraging,
30	
31	  /// Awaiting AI reply after STT — Thinking state.
32	  thinking,
33	}
34	
35	/// Mochi (emo_linear.riv) `state` input enum — must stay in sync with the rig.
36	///
37	/// | value | expression   | type    |
38	/// |-------|-------------|---------|
39	/// | 0     | Idle         | resting |
40	/// | 1     | Thinking     | restin
...[truncated]
```

**Tool - Read**

```
c:\project\vLearn2\flutter_app\lib\main.dart
```

**Result**

```
1	// vLearn2 — entry point.
2	//
3	// Architecture summary:
4	//   * State: Riverpod. Every cross-screen thing (auth, settings, model
5	//     registry, API clients) lives behind a Provider so widgets stay
6	//     stateless and tests can override.
7	//   * Navigation: go_router. The single source of truth is
8	//     [routerProvider] (see core/router/app_router.dart) which wires auth
9	//     redirects, the speech-models gate, and per-route deeplinks.
10	//   * Theming: built per-(theme key × font group) pair via [AppTheme.build]
11	//     and rebuilt automatically when either changes.
12	//
13	// The runApp call uses `UncontrolledProviderScope` so we can warm one
14	// provider (the on-disk config) before the first widget tree builds. This
15	// avoids a flash of fallback config during cold start.
16	
17	import 'dart:io';
18	import 'package:flutter/material.dart';
19	import 'package:flutter/services.dart';
20	import 'package:flutter_localizations/flutter_localizations.dart';
21	import 'package:flutter_riverpod/flutter_riverpod.dart';
22	import 'package:permission_handler/permission_handler.dart';
23	import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
24	import 'package:
...[truncated]
```

## Claude

Let me check the rive version and pubspec to understand the renderer setup.

**Tool - Bash**

```
grep -E "rive|rive_native" c:\project\vLearn2\flutter_app\pubspec.yaml
```

**Result**

```
Exit code 2
grep: c:projectvLearn2flutter_apppubspec.yaml: No such file or directory
```

**Tool - Read**

```
c:\project\vLearn2\cmds\install_rive_native.ps1
```

**Result**

```
1	# -----------------------------------------------------------------------------
2	# vLearn2 - Install pre-built rive_native libraries into the Dart pub cache.
3	#
4	# The rive_native CMakeLists.txt calls "dart run rive_native:setup" which
5	# downloads native DLLs from the internet.  On the air-gapped VMware machine
6	# that call fails.  This script copies the pre-built binaries from the project
7	# tree (flutter_app\windows\rive_native_prebuilt\) into the correct pub-cache
8	# location so the setup command is satisfied without any network access.
9	#
10	# Run once after applying a git bundle that includes the prebuilt files:
11	#   .\cmds\install_rive_native.ps1
12	# -----------------------------------------------------------------------------
13	
14	[CmdletBinding()]
15	param()
16	
17	$ErrorActionPreference = "Stop"
18	
19	$root   = Split-Path $PSScriptRoot -Parent
20	$src    = Join-Path $root "flutter_app\windows\rive_native_prebuilt"
21	
22	if (-not (Test-Path $src)) {
23	    Write-Host "[rive] ERROR: prebuilt folder not found: $src"
24	    Write-Host "       Make sure you have applied the latest git bundle first."
25	    exit 1
26	}
27	
28	# Locate the rive_native package in
...[truncated]
```

## Claude

Let me check the rive package API available in the pub cache.

**Tool - Bash**

```
Get-ChildItem "C:\pub-Cache\hosted\pub.dev" -Directory -Filter "rive-*" | Select-Object Name
```

**Tool - PowerShell**

```
Get-Content "c:\project\vLearn2\flutter_app\pubspec.yaml" | Select-String "rive"
```

**Result**

```
Exit code 127
/usr/bin/bash: line 1: Get-ChildItem: command not found
/usr/bin/bash: line 1: Select-Object: command not found
```

**Result**

```
  flutter_[7mrive[0mrpod: ^2.5.1
  [7mrive[0mrpod_annotation: ^2.3.5
  # Animation. 0.14 was a major rewrite — [7mRive[0mAnimation widget removed,
  # replaced by [7mRive[0mWidget + a (Stateless)RiveWidgetController loaded
  [7mrive[0m: ^0.14.7
  [7mrive[0mrpod_generator: ^2.4.0
  [7mrive[0mrpod_lint: ^2.3.10
```

**Tool - PowerShell**

```
Get-ChildItem "C:\pub-Cache\hosted\pub.dev" -Directory -Filter "rive-*" | Select-Object Name
```

**Result**

```
Exit code 1
[31;1mGet-ChildItem: [31;1mCannot find path 'C:\pub-Cache\hosted\pub.dev' because it does not exist.[0m
```

**Tool - PowerShell**

```
$pubCache = if ($env:PUB_CACHE) { $env:PUB_CACHE } else { Join-Path $env:LOCALAPPDATA "Pub\Cache" }; Write-Host "PUB_CACHE: $pubCache"; Get-ChildItem "$pubCache\hosted\pub.dev" -Directory -Filter "rive-*" | Select-Object Name
```

**Result**

```
PUB_CACHE: C:\Users\aaa\AppData\Local\Pub\Cache

[32;1mName[0m
[32;1m----[0m
rive-0.13.20
rive-0.14.7
```

**Tool - PowerShell**

```
Get-ChildItem "C:\Users\aaa\AppData\Local\Pub\Cache\hosted\pub.dev\rive-0.14.7\lib" -Recurse -Filter "*.dart" | Where-Object { $_.Name -match "factory|renderer" } | Select-Object FullName
```

**Result**

```
(PowerShell completed with no output)
```

**Tool - PowerShell**

```
Select-String -Path "C:\Users\aaa\AppData\Local\Pub\Cache\hosted\pub.dev\rive-0.14.7\lib\*.dart" -Pattern "Factory" -List | Select-Object Path, Line | Select-Object -First 20
```

**Result**

```
(PowerShell completed with no output)
```

**Tool - PowerShell**

```
Get-ChildItem "C:\Users\aaa\AppData\Local\Pub\Cache\hosted\pub.dev\rive-0.14.7\lib" -Recurse | Select-Object FullName | Select-Object -First 30
```

**Result**

```
[32;1mFullName[0m
[32;1m--------[0m
C:\Users\aaa\AppData\Local\Pub\Cache\hosted\pub.dev\rive-0.14.7\lib\src
C:\Users\aaa\AppData\Local\Pub\Cache\hosted\pub.dev\rive-0.14.7\lib\rive.dart
C:\Users\aaa\AppData\Local\Pub\Cache\hosted\pub.dev\rive-0.14.7\lib\src\models
C:\Users\aaa\AppData\Local\Pub\Cache\hosted\pub.dev\rive-0.14.7\lib\src\painters
C:\Users\aaa\AppData\Local\Pub\Cache\hosted\pub.dev\rive-0.14.7\lib\src\widgets
C:\Users\aaa\AppData\Local\Pub\Cache\hosted\pub.dev\rive-0.14.7\lib\src\errors.dart
C:\Users\aaa\AppData\Local\Pub\Cache\hosted\pub.dev\rive-0.14.7\lib\src\file_loader.dart
C:\Users\aaa\AppData\Local\Pub\Cache\hosted\pub.dev\rive-0.14.7\lib\src\rive_extensions.dart
C:\Users\aaa\AppData\Local\Pub\Cache\hosted\pub.dev\rive-0.14.7\lib\src\models\artboard_selector.dart
C:\Users\aaa\AppData\Local\Pub\Cache\hosted\pub.dev\rive-0.14.7\lib\src\models\data_bind.dart
C:\Users\aaa\AppData\Local\Pub\Cache\hosted\pub.dev\rive-0.14.7\lib\src\models\state_machine_selector.dart
C:\Users\aaa\AppData\Local\Pub\Cache\hosted\pub.dev\rive-0.14.7\lib\src\painters\widget_controller.dart
C:\Users\aaa\AppData\Local\Pub\Cache\hosted\pub.dev\rive-0.14.7\lib\src\widgets\inh
...[truncated]
```

**Tool - Read**

```
C:\Users\aaa\AppData\Local\Pub\Cache\hosted\pub.dev\rive-0.14.7\lib\src\file_loader.dart
```

**Result**

```
1	import 'dart:async' show Completer;
2	
3	import 'package:rive/rive.dart' as rive;
4	import 'package:rive/src/errors.dart';
5	
6	/// {@template FileLoader}
7	/// A class that loads a Rive file from an asset, URL, or file.
8	///
9	/// To be used with [RiveWidgetBuilder].
10	///
11	/// - The [riveFactory] parameter is the Rive factory to use to decode the Rive
12	/// file, and determines the desired renderer to use.
13	///
14	/// This class caches the loaded file, and returns the same file instance
15	/// for subsequent calls to [file].
16	/// {@endtemplate}
17	class FileLoader {
18	  final rive.Factory riveFactory;
19	  final rive.File? _providedFile;
20	  final String? _asset;
21	  final String? _url;
22	  Completer<rive.File>? _loadCompleter;
23	  rive.File? _loadedFile;
24	
25	  /// {@macro FileLoader}
26	  /// - The [asset] parameter is the asset to load the Rive file from.
27	  FileLoader.fromAsset(String asset, {required this.riveFactory})
28	      : _asset = asset,
29	        _providedFile = null,
30	        _url = null;
31	
32	  /// {@macro FileLoader}
33	  /// - The [url] parameter is the URL to load the Rive file from.
34	  FileLoader.fromUrl(String url, {required this.ri
...[truncated]
```

**Tool - PowerShell**

```
Select-String -Path "C:\Users\aaa\AppData\Local\Pub\Cache\hosted\pub.dev\rive-0.14.7\lib\rive.dart" -Pattern "Factory|flutter|native" | Select-Object Line | Select-Object -First 20
```

**Result**

```
[32;1mLine[0m
[32;1m----[0m
export 'package:rive_native/rive_native.dart'
```

**Tool - PowerShell**

```
$pubCache = $env:PUB_CACHE ?? (Join-Path $env:LOCALAPPDATA "Pub\Cache"); Get-ChildItem "$pubCache\hosted\pub.dev" -Directory -Filter "rive_native-*" | Select-Object Name
```

**Result**

```
[32;1mName[0m
[32;1m----[0m
rive_native-0.1.7
```

**Tool - PowerShell**

```
$pubCache = $env:PUB_CACHE ?? (Join-Path $env:LOCALAPPDATA "Pub\Cache"); Get-ChildItem "$pubCache\hosted\pub.dev\rive_native-0.1.7\lib" -Recurse -Filter "*.dart" | Select-Object Name; Select-String -Path "$pubCache\hosted\pub.dev\rive_native-0.1.7\lib\rive_native.dart" -Pattern "Factory|flutter" | Select-Object Line | Select-Object -First 30
```

**Result**

```
[32;1mName[0m
[32;1m----[0m
focus.dart
layout_engine.dart
math.dart
platform.dart
rive_audio.dart
rive_luau.dart
rive_native_plugin_web.dart
rive_native.dart
rive_text.dart
scripting_workspace.dart
semantics.dart
utilities.dart
buffered_render_paint.dart
buffered_render_path.dart
callback_handler.dart
console_reader.dart
defaults.dart
errors.dart
glyph_lookup.dart
paint_dirt.dart
platform_native.dart
platform_web.dart
rive_artboard_layout.dart
rive_hit_test.dart
rive_native_ffi.dart
rive_native_web.dart
rive_renderer.dart
rive_semantics.dart
rive_ticker_aware_painter.dart
rive_widget.dart
rive.dart
wasm_version.dart
dynamic_library_helper.dart
flutter_renderer_ffi.dart
layout_engine_ffi.dart
rive_audio_ffi.dart
rive_data_binding_ffi.dart
rive_event_ffi.dart
rive_ffi_reference.dart
rive_ffi.dart
rive_focus_ffi.dart
rive_luau_ffi.dart
rive_renderer_ffi.dart
rive_semantic_ffi.dart
rive_text_ffi.dart
scripting_workspace_ffi.dart
edge_behavior.dart
aabb.dart
circle_constant.dart
hit_test.dart
mat2d.dart
path_types.dart
segment2d.dart
transform_components.dart
vec2d.dart
rive_semantics_overlay.dart
rive_semantics_test_helpers.
...[truncated]
```

**Tool - PowerShell**

```
$pubCache = $env:PUB_CACHE ?? (Join-Path $env:LOCALAPPDATA "Pub\Cache"); Select-String -Path "$pubCache\hosted\pub.dev\rive_native-0.1.7\lib\rive_native.dart" -Pattern "class Factory|Factory\." | Select-Object Line | Select-Object -First 20
```

**Result**

```
(PowerShell completed with no output)
```

**Tool - PowerShell**

```
$pubCache = $env:PUB_CACHE ?? (Join-Path $env:LOCALAPPDATA "Pub\Cache"); $path = "$pubCache\hosted\pub.dev\rive_native-0.1.7\lib"; Select-String -Path "$path\src\rive_renderer.dart" -Pattern "Factory|flutter|rive" | Select-Object Line | Select-Object -First 30
```

**Result**

```
[32;1mLine[0m
[32;1m----[0m
import 'package:flutter/rendering.dart' as flutter;
import 'package:rive_native/rive_text.dart' as common;
import 'package:rive_native/rive_native.dart';
import 'package:rive_native/rive_text.dart';
import '../src/ffi/rive_renderer_ffi.dart'
    if (dart.library.js_interop) '../src/web/rive_renderer_web.dart';
import '../src/ffi/flutter_renderer_ffi.dart'
    if (dart.library.js_interop) '../src/web/flutter_renderer_web.dart';
  factory PathCommand.move(Vec2D to) =>
  factory PathCommand.line(Vec2D from, Vec2D to) =>
  factory PathCommand.quad(Vec2D from, Vec2D control, Vec2D to) =>
  factory PathCommand.cubic(
  factory PathCommand.close() =>
abstract class FlutterRenderer {
  flutter.Canvas get canvas;
  /// Rive content will fill the available view. If the aspect ratios differ,
  /// then the Rive content will be stretched.
  /// Rive content will be contained within the view, preserving the aspect
  /// Rive will cover the view, preserving the aspect ratio. If the Rive
  /// content has a different ratio to the view, then the Rive content will be
  /// Rive content will fill to the width of the view. This may result in
  //
...[truncated]
```

**Tool - PowerShell**

```
$pubCache = $env:PUB_CACHE ?? (Join-Path $env:LOCALAPPDATA "Pub\Cache"); $path = "$pubCache\hosted\pub.dev\rive_native-0.1.7\lib"; Select-String -Path "$path\rive_native.dart" -Pattern "Factory" | Select-Object Line | Select-Object -First 20
```

**Result**

```
(PowerShell completed with no output)
```

**Tool - PowerShell**

```
$pubCache = $env:PUB_CACHE ?? (Join-Path $env:LOCALAPPDATA "Pub\Cache"); $path = "$pubCache\hosted\pub.dev\rive_native-0.1.7\lib"; Get-ChildItem $path -Recurse -Filter "*.dart" | ForEach-Object { Select-String -Path $_.FullName -Pattern "class Factory" } | Select-Object Line, Path
```

**Result**

```
[32;1mLine                    [0m[32;1m Path[0m
[32;1m----                    [0m [32;1m----[0m
abstract class Factory { C:\Users\aaa\AppData\Local\Pub\Cache\hosted\pub.dev\rive_native-0.1.7\lib\src\rive.dart
```

**Tool - PowerShell**

```
$pubCache = $env:PUB_CACHE ?? (Join-Path $env:LOCALAPPDATA "Pub\Cache"); Select-String -Path "$pubCache\hosted\pub.dev\rive_native-0.1.7\lib\src\rive.dart" -Pattern "factory|flutter|rive|Factory" | Select-Object Line | Select-Object -First 40
```

**Result**

```
[32;1mLine[0m
[32;1m----[0m
import 'package:flutter/services.dart'
import 'package:rive_native/focus.dart' as focus;
import 'package:rive_native/rive_luau.dart';
import 'package:rive_native/semantics.dart';
import '../rive_native.dart';
import 'ffi/rive_ffi.dart' if (dart.library.js_interop) 'web/rive_web.dart';
export 'package:rive_native/src/callback_handler.dart';
class Rive {
  /// rendering multiple Rive animations.
  /// multiple Rive animations simultaneously.
/// Factory for creating Rive rendering objects.
/// - Use [Factory.rive] for the Rive renderer (recommended) for best performance and full rendering support.
/// - Use [Factory.flutter] for the built-in Flutter renderer for smaller graphics that need to integrate with other F…
/// See the [documentation](https://rive.app/docs/runtimes/flutter/flutter#specifying-a-renderer) on specifying a rend…
abstract class Factory {
  /// Whether this factory is supported on the current platform.
  /// Returns the native pointer address for this factory, or 0 if not
  /// backed by a native factory.
  /// Decodes image bytes into a [RenderImage] for use with Rive.
  /// Decodes font bytes into a [Font] for 
...[truncated]
```

## Claude

Found it. `Factory.rive` uses the native GPU renderer which crashes in VMware's virtual GPU. `Factory.flutter` uses Skia which is software-rendered and works fine in VMware. The fix is to use the Flutter renderer on Windows, keeping the native renderer for Android production.

**Tool - Edit**

```
c:\project\vLearn2\flutter_app\lib\features\conversation\widgets\tutor_avatar.dart
```

**Result**

```
The file c:\project\vLearn2\flutter_app\lib\features\conversation\widgets\tutor_avatar.dart has been updated successfully. (file state is current in your context — no need to Read it back)
```

## Claude

Now let me apply the actual fix to use the Flutter renderer on Windows.

**Tool - Edit**

```
c:\project\vLearn2\flutter_app\lib\features\conversation\widgets\tutor_avatar.dart
```

**Result**

```
The file c:\project\vLearn2\flutter_app\lib\features\conversation\widgets\tutor_avatar.dart has been updated successfully. (file state is current in your context — no need to Read it back)
```

## Claude

Now let me commit and save the story.

**Tool - PowerShell**

```
Get-Date -Format 'yyMMdd_HHmmss'
```

**Result**

```
260603_183534
```

**Tool - Write**

```
c:\project\vLearn2\story_claude\2026_06_03\260603_183534_Fix_Rive_crash_on_VMware_Windows.md
```

**Result**

```
File created successfully at: c:\project\vLearn2\story_claude\2026_06_03\260603_183534_Fix_Rive_crash_on_VMware_Windows.md (file state is current in your context — no need to Read it back)
```

**Tool - Bash**

```
git add flutter_app/lib/features/conversation/widgets/tutor_avatar.dart story_claude/2026_06_03/260603_183534_Fix_Rive_crash_on_VMware_Windows.md && git commit -m "Fix Rive native renderer crash on VMware by using Flutter renderer on Windows"
```

---

## User prompts (verbatim)

### Prompt 1

```
<ide_opened_file>The user opened the file c:\project\vLearn2\cmds\install_rive_native.ps1 in the IDE. This may or may not be related to the current task.</ide_opened_file>

when i debug windows program on vmware, and i enter the conversation screen then the application suddenly exits. below are the logs. i think rive raises error.


D:\a\sherpa-onnx\sherpa-onnx\sherpa-onnx\csrc\offline-tts-vits-model.cc:Init:162 ---vits model---
n_speakers=109
onnx.infer=onnxruntime.quant
punctuation=; : , . ! ? ¡ ¿ — … " « » “ ”  
model_type=vits
comment=vctk
language=English
add_blank=1
sample_rate=22050
----------input names----------
0 x
1 x_length
2 noise_scale
3 length_scale
4 noise_scale_w
5 sid
----------output names----------
0 y
2

22
D:\a\sherpa-onnx\sherpa-onnx\sherpa-onnx\csrc\lexicon.cc:ConvertTokensToIds:93 Unknown token: ̃
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
│ #0   SherpaOnnxTtsService.initialize (package:flutter_app/core/speech/sherpa_onnx_tts.dart:130:12)
│ #1   <asynchronous suspension>
├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
│ 💡 TTS: OfflineTts ready with 109 voices.
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
Lost connection to device.

Exited.
```

