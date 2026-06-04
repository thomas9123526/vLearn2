# Can you verify that the vLearn2 flutter APK operates smoothly on actual devices 

Session: `ec7e9529-1399-4642-b1c1-753f53834cc7`
Saved: 2026-06-04T07:47:11.141Z

## User

Can you verify that the vLearn2 flutter APK operates smoothly on actual devices and that users do not experience any UI freezing or abnormal symptoms? In particular, when using voice recognition and voice output, the UI needs to appear fluid and the characters need to respond naturally; can you guarantee that this actually happens?
I don't want you to build apk and install emulator.

## Assistant

Understood. No build/emulator — code analysis only. Let me re-read the current state of the key files for an honest assessment.

## Assistant

Now I have everything I need for an honest code-analysis verdict.

---

## Verification: STT/TTS UI fluidity on real device

**Verdict: FAIL — two confirmed blocking issues, two easy wins**

**Claim:** UI stays fluid and character animates naturally during voice recognition and TTS output.

**Method:** Static code analysis of the three files that own the entire voice pipeline.

---

### Findings

#### 🔴 Issue 1 — STT inference freezes the UI thread ([sherpa_onnx_stt.dart:189-204](flutter_app/lib/core/speech/sherpa_onnx_stt.dart#L189-L204))

```dart
// doTranscribe() has no await inside — zero yields to the event loop
while (_online!.isReady(stream)) {
  _online!.decode(stream);   // ← synchronous FFI, blocks entire main isolate
}
// or for offline/Whisper:
_offline!.decode(stream);    // ← same
```

Dart's `async` keyword does **not** create a thread. Without an `await` inside `doTranscribe()`, the main isolate is fully occupied for the duration of ONNX inference. On a real ARM64 device with the current 4B model, this is likely **0.5–4 seconds** of complete freeze: the Rive avatar stops, the "Thinking…" spinner stops, touch is unresponsive.

The `setState(thinking)` call **does** run before this (line 246), so users see the status pill flip before the freeze — that's good. But the spinner won't spin during inference.

#### 🔴 Issue 2 — TTS synthesis freezes the UI thread ([sherpa_onnx_tts.dart:289-304](flutter_app/lib/core/speech/sherpa_onnx_tts.dart#L289-L304))

```dart
final audio = _engine!.generate(   // ← synchronous VITS FFI, no await
  text: text, sid: sid, speed: rate,
);
// ...
cacheFile.writeAsBytesSync(wav);   // ← synchronous disk write on top
```

Same problem. First time the tutor speaks a new sentence: VITS synthesis + sync disk write both block the main isolate. Cached sentences are fine (readAsBytes() IS async), but first-time synthesis will freeze.

#### 🟡 Issue 3 — setState() at 60 Hz during TTS playback ([tutor_mode_view.dart:79-82](flutter_app/lib/features/conversation/widgets/tutor_mode_view.dart#L79-L82))

```dart
_ampSub = tts.amplitudeStream.listen((double amp) {
  if (!mounted) return;
  setState(() => _amplitude = amp);  // ← rebuilds entire TutorModeView 60×/sec
});
```

This forces a full widget subtree rebuild 60 times per second while the tutor is speaking. On high-end devices no visible problem. On mid-range it contributes to frame drops during playback.

#### ✅ What works well

- Mood transitions (`idle → thinking → speaking`) are correctly gated with `setState` before the async calls, so visual state changes are shown to the user even if animations then freeze.
- Rive avatar integration, mic button states, status pill animations — all correct structure.
- TTS cache hit path is fully async — repeated sentences play without any freeze.
- The 60s STT timeout with a clear error message prevents the UI from getting permanently stuck.

---

### What I can fix now vs. what requires restructuring

| Issue | Fix | Effort |
|---|---|---|
| `setState` 60×/sec | Replace with `ValueNotifier` + `ValueListenableBuilder` scoped to amplitude | Easy — 15 min |
| Sync disk write in TTS cache | `writeAsBytesSync` → `await writeAsBytes`, `createSync` → `await create()` | Easy — 5 min |
| **STT FFI blocks main isolate** | Move inference to a separate `Isolate` via `Isolate.run()` — needs the engine to re-initialize inside the isolate (FFI handles can't cross isolates) | Hard — full engine architecture change |
| **TTS FFI blocks main isolate** | Same isolate approach | Hard — same |

---

**Bottom line:** I cannot guarantee smooth UI during STT/TTS. The two FFI-blocks-main-thread issues are real and confirmed in the current code. How *bad* it feels depends on the device: a flagship 2024 SoC might complete inference in 400ms (barely noticeable); a mid-range or old device could be 2–5 seconds of frozen UI.

Want me to apply the two easy fixes now (setState → ValueNotifier, async disk I/O)? Those are safe changes that improve things without touching the hard architecture problem.
