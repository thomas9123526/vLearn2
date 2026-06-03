# Conversation - Rive renderer crash on persona avatar (VMware GPU)

| Field | Value |
|---|---|
| Saved | 2026-06-03 18:47:30 |
| Commit | auto: re-apply Flutter Rive renderer to persona_avatar on Windows |
| Project | C:\project\vLearn2 |

---

## User

Pasted a console log: sherpa-onnx TTS init succeeded ("OfflineTts ready with 109 voices"),
then "Lost connection to device. Exited." when entering the conversation screen.
Suspected the Rive avatar was the problem and asked me to check.

## Assistant

Diagnosed it as a native crash (no Dart stack trace = segfault, not a catchable
exception), firing when the conversation screen mounts the Rive avatar. The avatars
loaded their `.riv` with `Factory.rive` — Rive's native GPU renderer (rive_native),
which needs real GPU features that VMware's virtual GPU doesn't provide. The existing
`CartoonFace` fallback only catches `RiveFailed` (a Dart-level failure), so a native
segfault bypasses it and kills the app.

Fix: switch to `Factory.flutter` (Rive's built-in Flutter/Skia renderer) which draws
through Flutter's own pipeline and works without the native GPU renderer. Applied to
both tutor_avatar.dart and persona_avatar.dart; `flutter analyze` clean.

## User

"dont git commit automatically and dont put md file in claude from now in this vmware."

## Assistant

Acknowledged — disabled the CLAUDE.md auto-commit + story workflow for this VM.

## User

"can you do again for above changes? I have accidentally lost your changes on code."

## Assistant

Found tutor_avatar.dart already had the fix (committed, Platform-gated:
`Platform.isWindows ? Factory.flutter : Factory.rive`). Only persona_avatar.dart had
reverted to `Factory.rive`. Re-applied the same Platform-gated approach there, adding
`import 'dart:io';`. `flutter analyze` clean on both files.

## User

"so what is the real reason? is it gpu problem?"

## Assistant

Confirmed it with the Windows Application event log instead of guessing. The faulting
module is `rive_native.dll`, exception `0xc0000005` (access violation), same fault
offset 0x283aad across three crashes. Smoking gun: even Rive's own editor (`Rive.exe`)
crashed in `rive_native.dll` with the same code on this machine. So rive_native's GPU
renderer cannot run on the VM's virtual GPU — almost certainly dereferencing a GPU
resource that never got created because the virtual driver lacks the feature.
`Factory.flutter` avoids that code path while still using the rest of Flutter's
rendering (which already works in the VM).

## User

"can you turn on the auto commit and make md inside story??? folder?"

## Assistant

Re-enabled the commit + story workflow and committed the persona_avatar.dart fix
together with this story file.

---

## Prompt

can you turn on the auto commit and make md inside story??? folder?
