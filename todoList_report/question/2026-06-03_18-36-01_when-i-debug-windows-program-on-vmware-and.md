# when i debug windows program on vmware, and i enter the conversation screen then

Session: `10e65b1d-4afb-4146-8130-782b3c1583d6`
Saved: 2026-06-03T09:36:01.019Z

## User

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

## Assistant

Looking at the logs, TTS initializes fine — the crash ("Lost connection to device") happens after that, likely a native crash in Rive or something else on the conversation screen. Let me find the relevant code.

## Assistant

Let me look at the tutor_avatar.dart and main.dart Rive init more closely.

## Assistant

Let me check the rive version and pubspec to understand the renderer setup.

## Assistant

Let me check the rive package API available in the pub cache.

## Assistant

Found it. `Factory.rive` uses the native GPU renderer which crashes in VMware's virtual GPU. `Factory.flutter` uses Skia which is software-rendered and works fine in VMware. The fix is to use the Flutter renderer on Windows, keeping the native renderer for Android production.

## Assistant

Now let me apply the actual fix to use the Flutter renderer on Windows.

## Assistant

Now let me commit and save the story.

## Assistant

**Root cause:** `Factory.rive` is the native Rive renderer (D3D11/Vulkan-backed) which hard-crashes against VMware's virtual GPU before it can render even a single frame — that's why you see "Lost connection to device" right after TTS finishes initializing.

**Fix applied** in [tutor_avatar.dart:123](flutter_app/lib/features/conversation/widgets/tutor_avatar.dart#L123):

```dart
riveFactory: Platform.isWindows ? rive.Factory.flutter : rive.Factory.rive,
```

- **Windows (VMware)** → `Factory.flutter` uses Skia/software rendering, no GPU required
- **Android (production)** → `Factory.rive` keeps the native renderer for best performance
