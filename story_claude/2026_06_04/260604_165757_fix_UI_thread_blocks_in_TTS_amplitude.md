# Conversation - Fix UI thread blocks in TTS amplitude stream

| Field | Value |
|---|---|
| Saved | 2026-06-04 16:57:57 |
| Commit | auto: fix TTS cache sync I/O and amplitude setState 60Hz rebuild |
| Project | C:\project\vLearn2 |

---

## User

Can you verify that the vLearn2 flutter APK operates smoothly on actual devices and that users do not experience any UI freezing or abnormal symptoms? In particular, when using voice recognition and voice output, the UI needs to appear fluid and the characters need to respond naturally; can you guarantee that this actually happens?

## Assistant

Code analysis verdict: FAIL — two confirmed blocking issues found:

1. STT FFI (`_online!.decode()` / `_offline!.decode()`) runs synchronously on the main isolate — UI freezes for the full inference duration.
2. TTS FFI (`_engine!.generate()`) + synchronous cache write (`writeAsBytesSync`, `createSync`) blocks main isolate on first synthesis.
3. `setState()` called 60×/sec from amplitude stream → full `TutorModeView` rebuild at 60 Hz.
4. `existsSync()` synchronous stat on cache check.

Issues 1 & 2 (FFI on main isolate) require full Isolate architecture change — hard.
Issues 3 & 4 are easy wins, offered to fix now.

## User

yes

## Assistant

Applied two easy fixes:

**sherpa_onnx_tts.dart:**
- `existsSync()` → `await cacheFile.exists()`
- `cacheFile.parent.createSync(recursive: true)` → `await cacheFile.parent.create(recursive: true)`
- `cacheFile.writeAsBytesSync(wav)` → `await cacheFile.writeAsBytes(wav)`

**tutor_mode_view.dart:**
- `double _amplitude` field → `final _amplitude = ValueNotifier<double>(0.0)`
- `setState(() => _amplitude = amp)` in ampSub → `_amplitude.value = amp` (no setState)
- `_amplitude = 0.0` in ttsSub → `_amplitude.value = 0.0` (outside setState)
- Wrapped `_AvatarStage` in `ValueListenableBuilder<double>` — only avatar subtree rebuilds on amplitude changes, not the whole screen
- Added `_amplitude.dispose()` in dispose()

---

## Prompt

yes
