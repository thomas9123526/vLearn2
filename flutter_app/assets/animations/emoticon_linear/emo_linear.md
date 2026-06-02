# Mochi — Flutter + sherpa-onnx integration guide

How to drive `mochi.riv` (the expressive blob) from a Flutter app using
sherpa-onnx for STT/TTS. This is the runtime side: load the file, grab the
inputs, map your pipeline's phases to expressions, and lip-sync the mouth
from TTS audio.

> The character rig itself was built in the Rive editor. This document only
> covers wiring it up at runtime.

---

## 1. The contract

Everything the app touches goes through **one state machine** and **four
inputs**. The names are **case-sensitive** and must match these strings
exactly — a typo here is the #1 cause of "it loads but never moves".

| Thing            | Name        | Type    | Range  | Meaning |
|------------------|-------------|---------|--------|---------|
| State machine    | `Mochi`     | —       | —      | The one to instantiate |
| Expression       | `state`     | Number  | 0–5    | High-level mode (enum below) |
| Viseme           | `mouth`     | Number  | 0–5    | *Currently unused* (reserved for the viseme upgrade) |
| Loudness         | `amplitude` | Number  | 0.0–1.0| Drives the mouth-open blend while speaking |
| Blink            | `blink`     | Trigger | —      | Fire every few seconds to blink |

**`state` enum:**

| Value | Expression    | Notes |
|-------|---------------|-------|
| 0     | Idle          | Default / resting |
| 1     | Thinking      | LLM is working |
| 2     | Speaking      | TTS playing — mouth driven by `amplitude` |
| 3     | Attention     | Mic open / listening |
| 4     | Excited       | **Moment** state — pulse ~1.5s then return |
| 5     | Disappointed  | **Moment** state — pulse ~1.5s then return |

Idle / Attention / Speaking are *resting* modes you hold. Excited and
Disappointed are *moments*: flash them briefly on a good/bad result, then drop
back to Idle.

---

## 2. Project setup

`pubspec.yaml`:

```yaml
dependencies:
  rive: ^0.13.20          # check pub.dev for the latest; pulls in rive_native
  sherpa_onnx: ^1.10.0    # match the version you're already using
  # plus whatever you use to play PCM audio, e.g. just_audio / audioplayers

flutter:
  assets:
    - assets/mochi.riv
```

> Flutter Rive now runs on a native runtime (the `rive` package sits on top of
> `rive_native`). The native libraries are fetched automatically during
> `flutter run` / `flutter build`. If they don't, run
> `dart run rive_native:setup`.

---

## 3. Load the file and grab the inputs

The reliable pattern: create your **own** `StateMachineController` in `onInit`
so you keep references to the inputs. Number inputs are `SMINumber`, the trigger
is `SMITrigger`.

```dart
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class MochiView extends StatefulWidget {
  const MochiView({super.key, this.onReady});
  final void Function(MochiController)? onReady;

  @override
  State<MochiView> createState() => _MochiViewState();
}

class _MochiViewState extends State<MochiView> {
  void _onRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'Mochi',                       // <-- state machine name
      onStateChange: (sm, state) {
        // optional: debugPrint('state -> $state');
      },
    );
    if (controller == null) {
      debugPrint('Mochi state machine not found — check the name/export');
      return;
    }
    artboard.addController(controller);
    widget.onReady?.call(MochiController(controller));
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1, // artboard is 512x512
      child: RiveAnimation.asset(
        'assets/mochi.riv',
        // artboard: 'Mochi_Master', // set if your artboard isn't the default
        fit: BoxFit.contain,
        onInit: _onRiveInit,
      ),
    );
  }
}
```

---

## 4. A small wrapper around the blob

Keep all the Rive-poking in one place so the rest of the app just expresses
*intent* (`mochi.listening()`, `mochi.speaking()`, …).

```dart
import 'dart:async';
import 'dart:math';
import 'package:rive/rive.dart';

/// High-level modes — keep in sync with the `state` enum in the rig.
enum Mood { idle, thinking, speaking, attention, excited, disappointed }

class MochiController {
  MochiController(this._sm) {
    _state     = _sm.findInput<double>('state')     as SMINumber?;
    _amplitude = _sm.findInput<double>('amplitude') as SMINumber?;
    _blink     = _sm.findInput<bool>('blink')       as SMITrigger?;
    // _mouth  = _sm.findInput<double>('mouth')      as SMINumber?; // unused for now
    _startBlinkTimer();
  }

  final StateMachineController _sm;
  SMINumber? _state;
  SMINumber? _amplitude;
  SMITrigger? _blink;

  Timer? _blinkTimer;
  Timer? _flashTimer;
  final _rng = Random();

  Mood _mood = Mood.idle;
  Mood get mood => _mood;

  // ---- expression control -------------------------------------------------

  void setMood(Mood m) {
    _mood = m;
    _state?.value = m.index.toDouble();   // enum order == state numbers
  }

  void idle()        => setMood(Mood.idle);
  void thinking()    => setMood(Mood.thinking);
  void speaking()    => setMood(Mood.speaking);
  void listening()   => setMood(Mood.attention);

  /// Moment states: pulse, then fall back. Mirrors the demo's flash().
  void flashExcited({Duration hold = const Duration(milliseconds: 1500)}) =>
      _flash(Mood.excited, hold);
  void flashDisappointed({Duration hold = const Duration(milliseconds: 1500)}) =>
      _flash(Mood.disappointed, hold);

  void _flash(Mood m, Duration hold) {
    _flashTimer?.cancel();
    setMood(m);
    _flashTimer = Timer(hold, () => setMood(Mood.idle));
  }

  // ---- lip-sync -----------------------------------------------------------

  /// 0.0 (closed) .. 1.0 (wide). Only has a visible effect while speaking,
  /// because the Mouth layer in the rig is gated to state == 2.
  void setAmplitude(double v) => _amplitude?.value = v.clamp(0.0, 1.0);

  // ---- blink --------------------------------------------------------------

  void _startBlinkTimer() {
    _blinkTimer?.cancel();
    final ms = 2000 + _rng.nextInt(3000); // every 2–5s
    _blinkTimer = Timer(Duration(milliseconds: ms), () {
      if (_mood != Mood.excited) _blink?.fire(); // rig also guards state==4
      _startBlinkTimer();
    });
  }

  void dispose() {
    _blinkTimer?.cancel();
    _flashTimer?.cancel();
  }
}
```

> The rig already suppresses blinking during Excited, so the `_mood != excited`
> check is just belt-and-suspenders.

---

## 5. Map your pipeline to expressions

One place owns the mood; your STT / LLM / TTS callbacks flip it.

| Pipeline event          | Call                       | Resulting `state` |
|-------------------------|----------------------------|-------------------|
| Mic opens / listening   | `mochi.listening()`        | 3 Attention |
| Got transcript → LLM    | `mochi.thinking()`         | 1 Thinking |
| TTS starts              | `mochi.speaking()`         | 2 Speaking |
| TTS audio frame         | `mochi.setAmplitude(x)`    | — (drives mouth) |
| TTS ends                | `mochi.idle()`             | 0 Idle |
| Task succeeded          | `mochi.flashExcited()`     | 4 → 0 |
| Task failed             | `mochi.flashDisappointed()`| 5 → 0 |

```dart
stt.onStart      = () => mochi.listening();
stt.onFinal      = () => mochi.thinking();
llm.onFirstToken = () => mochi.speaking();   // TTS about to begin
tts.onEnd        = () => mochi.idle();

agent.onSuccess  = () => mochi.flashExcited();
agent.onError    = () => mochi.flashDisappointed();
```

(Adapt the callback names to your actual sherpa-onnx / app wiring — the point is
*which mood maps to which phase*.)

---

## 6. Lip-sync from sherpa-onnx TTS

**Key fact:** sherpa-onnx TTS gives you back **audio samples only** — a
`Float32List` plus a sample rate. It does *not* hand you phoneme timing. So the
MVP (and what the rig is built for) is amplitude-driven: measure loudness and
feed `amplitude`. This is stylized lip-sync (matches volume, not exact sounds),
which reads great on a blob.

Flutter has no Web Audio `AnalyserNode`, but you get the whole buffer up front,
so the clean approach is: **precompute a loudness envelope once, then play it
back against a `Ticker` synced to audio position.**

```dart
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/scheduler.dart';

class LipSync {
  LipSync(this.mochi, this.vsync);
  final MochiController mochi;
  final TickerProvider vsync;

  static const _windowSec = 0.016; // ~16ms buckets ≈ one per frame
  static const _gain = 3.2;        // tune: louder voices -> lower; quiet -> higher

  Ticker? _ticker;
  List<double> _env = const [];
  double _sma = 0;

  /// Build a 0..1 loudness value per ~16ms of audio.
  static List<double> buildEnvelope(Float32List samples, int sampleRate) {
    final win = (sampleRate * _windowSec).round().clamp(1, samples.length);
    final env = <double>[];
    for (var i = 0; i < samples.length; i += win) {
      final end = math.min(i + win, samples.length);
      var sum = 0.0;
      for (var j = i; j < end; j++) sum += samples[j] * samples[j];
      final rms = math.sqrt(sum / (end - i));        // 0..~0.3
      env.add((rms * _gain).clamp(0.0, 1.0));         // -> 0..1
    }
    return env;
  }

  /// Call right when you start playing the audio.
  void start(Float32List samples, int sampleRate) {
    _env = buildEnvelope(samples, sampleRate);
    _sma = 0;
    final sw = Stopwatch()..start();

    _ticker?.dispose();
    _ticker = vsync.createTicker((_) {
      final i = (sw.elapsedMilliseconds / (_windowSec * 1000)).floor();
      final target = (i >= 0 && i < _env.length) ? _env[i] : 0.0;
      _sma = _sma * 0.6 + target * 0.4;   // smooth — kills jitter
      mochi.setAmplitude(_sma);
      if (i >= _env.length) stop();        // audio finished
    })..start();
  }

  void stop() {
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
    mochi.setAmplitude(0); // close the mouth cleanly
  }
}
```

Wiring it to a spoken sentence:

```dart
// `tts` is your sherpa_onnx OfflineTts instance.
Future<void> say(String text) async {
  final audio = tts.generate(text: text, sid: 0, speed: 1.0);
  // audio.samples : Float32List, audio.sampleRate : int
  // (field names can vary slightly by sherpa_onnx version — verify on yours)

  mochi.speaking();                                   // state -> 2
  lipSync.start(audio.samples, audio.sampleRate);     // drive the mouth

  await playPcm(audio.samples, audio.sampleRate);     // your audio player

  lipSync.stop();
  mochi.idle();                                       // state -> 0
}
```

> **Playing the PCM:** sherpa-onnx examples typically write the samples to a WAV
> (`writeWave(...)`) and play that file with a normal audio plugin
> (`just_audio` / `audioplayers`), or push raw PCM to a low-level player. Either
> works — the lip-sync only needs the `samples`/`sampleRate`, independent of how
> you play them. For tightest sync, drive the envelope index from the player's
> real playback position instead of the `Stopwatch` if your player exposes it.

### Tuning
- **Mouth barely moves:** raise `_gain` (e.g. 4.0–5.0).
- **Mouth always gaping:** lower `_gain` (e.g. 2.0–2.5).
- **Twitchy / jittery:** lean more on the smoother (e.g. `0.7 * _sma + 0.3 * target`).

---

## 7. Pre-flight checklist (when something doesn't work)

1. **Names exact & case-sensitive:** `Mochi`, `state`, `amplitude`, `blink`.
   A null from `findInput` = wrong name or not exported.
2. **State machine is the artboard default** (or pass `artboard:` explicitly).
3. **Loads in Idle:** `state` default is `0` in the rig.
4. **Mouth not moving:** confirm `state` is `2` while you call `setAmplitude` —
   the Mouth layer is gated to `state == 2`, so amplitude does nothing otherwise.
5. **Runtime major version** of the `rive` package matches the `.riv` export
   version shown in the editor's export dialog.
6. **Watermark:** free-plan exports carry a "Made with Rive" mark (team plan
   removes it).

---

## 8. Upgrade paths (later, optional)

**Viseme variety (still amplitude-driven).** Add `m-u / m-e / m-o / m-ai` to the
Talk blend in the editor as intermediate thresholds so the mouth morphs through
shapes instead of just opening. No code change — still just `setAmplitude`.

**True phoneme sync (bigger project).** sherpa-onnx TTS won't give you phoneme
*timing*, so this needs grapheme-to-phoneme + forced alignment to produce a
phoneme-time track, mapped to visemes, driving the `mouth` number from that
timeline. The amplitude route above is the MVP; this is the accuracy upgrade.

If you do build the viseme switch instead of the blend, these are the loudness
buckets the original rig spec uses:

| amplitude     | `mouth` | shape |
|---------------|---------|-------|
| < 0.08        | 1       | MBP — closed |
| 0.08 – 0.28   | 0       | REST — barely open |
| 0.28 – 0.48   | 4       | U — small round |
| 0.48 – 0.66   | 3       | E — wide |
| 0.66 – 0.84   | 5       | O — round open |
| > 0.84        | 2       | AI — wide open |

---

## Quick reference

```dart
mochi.idle();                 // 0
mochi.thinking();             // 1
mochi.speaking();             // 2  (then feed setAmplitude each frame)
mochi.listening();            // 3
mochi.flashExcited();         // 4 -> 0 after ~1.5s
mochi.flashDisappointed();    // 5 -> 0 after ~1.5s
mochi.setAmplitude(0.0..1.0); // mouth open amount while speaking
// blink fires automatically every 2–5s
```
