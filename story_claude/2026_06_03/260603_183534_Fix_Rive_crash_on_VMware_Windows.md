# Conversation - Fix Rive crash on VMware Windows

| Field | Value |
|---|---|
| Saved | 2026-06-03 18:35:34 |
| Commit | Fix Rive native renderer crash on VMware by using Flutter renderer on Windows |
| Project | C:\project\vLearn2 |

---

## User

when i debug windows program on vmware, and i enter the conversation screen then the application suddenly exits. below are the logs. i think rive raises error.

```
D:\a\sherpa-onnx\... TTS model loaded (109 speakers)
TTS: OfflineTts ready with 109 voices.
Lost connection to device.
Exited.
```

## Assistant

The crash ("Lost connection to device") is a hard native process exit triggered after TTS initializes successfully — meaning the crash happens when the conversation screen first renders its `TutorAvatar` widget.

**Root cause:** `tutor_avatar.dart` uses `rive.Factory.rive` (the native Rive renderer backed by D3D11/D3D12/Vulkan). VMware's virtual GPU does not support the GPU features this renderer requires, causing a native crash (access violation / segfault) when the widget tries to paint for the first time.

**Fix:** In `tutor_avatar.dart`, the static `_fileLoader` now chooses the renderer based on platform:
- **Windows** → `Factory.flutter` (Flutter/Skia, software-safe, works in VMware)
- **Other platforms (Android, etc.)** → `Factory.rive` (native renderer, best performance)

```dart
static final rive.FileLoader _fileLoader = rive.FileLoader.fromAsset(
  'assets/animations/emoticon_linear/emo_linear.riv',
  riveFactory: Platform.isWindows ? rive.Factory.flutter : rive.Factory.rive,
);
```

Also added `import 'dart:io';` to access `Platform`.

---

## Prompt

when i debug windows program on vmware, and i enter the conversation screen then the application suddenly exits. below are the logs. i think rive raises error.
