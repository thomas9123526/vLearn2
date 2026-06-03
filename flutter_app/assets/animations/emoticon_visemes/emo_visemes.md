# Mochi — Flutter Integration Guide

How to load your exported `mochi.riv` into a Flutter app and drive the character's
expressions, blinking, and mouth lip-sync from a **sherpa-onnx** STT/TTS pipeline.

This guide targets the **Rive Flutter `0.14.x` runtime** (the native C++ runtime).
The API here is *different* from the old `RiveAnimation` / `SMINumber` runtime — older
tutorials will not compile against 0.14.x.

---

## 0. How the pieces fit together

Your `.riv` exposes four state-machine inputs. The whole integration is just *writing
to these four values* at the right time:

| Input        | Type    | Range | Who writes it                                   |
|--------------|---------|-------|-------------------------------------------------|
| `state`      | Number  | 0–5   | Your app lifecycle (idle/listening/thinking/…)  |
| `mouth`      | Number  | 0–5   | The lip-sync driver, only while speaking         |
| `amplitude`  | Number  | 0–1   | TTS loudness (if you use the blend mouth instead)|
| `blink`      | Trigger | —     | A repeating timer in Dart                        |

State enum (high-level mode):

```
0 Idle · 1 Thinking · 2 Speaking · 3 Attention · 4 Excited · 5 Disappointed
```

Mouth enum (viseme while speaking):

```
0 rest · 1 mbp · 2 ai · 3 e · 4 u · 5 o
```

The mental model: a single object owns the character's mode and pushes `state`. While
`state == 2` (Speaking), a separate driver reads the TTS audio and pushes `mouth`
(or `amplitude`) every frame. A timer fires `blink`. That's the entire contract.

> **Note on "Inputs [Deprecated]".** In recent editor/runtime versions Rive marks
> classic state-machine *Inputs* as deprecated in favour of **Data Binding** (View
> Models). Inputs still work and are the simplest path for this rig, so this guide
> uses them. If you'd rather future-proof, see *Appendix B* for the data-binding
> equivalent — the lip-sync logic is identical, only the "how you write the value"
> line changes.

---

## 1. Dependencies

In `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  rive: ^0.14.0          # native runtime — use the latest 0.14.x
  sherpa_onnx: ^1.10.0   # use the latest; STT + TTS bindings

  # You also need *something* to play raw PCM samples from sherpa TTS.
  # Pick one — examples below assume you can both play and tap the samples:
  # flutter_pcm_sound: ^3.0.0     # feed Float32/Int16 PCM directly (good for streaming)
  # or write a WAV and use just_audio / audioplayers

flutter:
  assets:
    - assets/rive/mochi.riv
    - assets/models/      # your sherpa-onnx model files
```

Then:

```bash
flutter pub get
```

`rive 0.14.x` pulls in `rive_native`, which downloads prebuilt native libraries on
first build. If an iOS/macOS build can't find them, run `flutter clean` and rebuild;
see the Rive migration guide if the `rive_native:setup` script doesn't run.

---

## 2. Initialise Rive

The native runtime **must** be initialised before any Rive widget is built. Do it in
`main()`:

```dart
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RiveNative.init();   // mandatory — omitting this throws at runtime
  runApp(const MyApp());
}
```

---

## 3. Load the file and grab the inputs

We load `mochi.riv`, build a `RiveWidgetController`, and resolve the four inputs once.
Wrapping them in a small controller class keeps the rest of the app clean.

```dart
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// High-level character modes — mirror these on the Rive `state` input.
enum Mode { idle, thinking, speaking, attention, excited, disappointed }

class MochiController {
  MochiController(this._controller) {
    final sm = _controller.stateMachine;
    _state     = sm.number('state');
    _mouth     = sm.number('mouth');
    _amplitude = sm.number('amplitude');
    _blink     = sm.trigger('blink');
  }

  final RiveWidgetController _controller;

  late final NumberInput?  _state;
  late final NumberInput?  _mouth;
  late final NumberInput?  _amplitude;
  late final TriggerInput? _blink;

  // ---- high-level mode -------------------------------------------------
  void setMode(Mode m)        => _state?.value = m.index.toDouble();

  /// Pulse a momentary state (Excited / Disappointed) then fall back.
  void flash(Mode m, {Mode back = Mode.idle, int ms = 1600}) {
    setMode(m);
    Future.delayed(Duration(milliseconds: ms), () => setMode(back));
  }

  // ---- lip-sync writes -------------------------------------------------
  void setMouth(int viseme)   => _mouth?.value = viseme.toDouble();
  void setAmplitude(double a) => _amplitude?.value = a.clamp(0.0, 1.0);

  // ---- blink -----------------------------------------------------------
  void blink() => _blink?.fire();

  void dispose() {
    _state?.dispose();
    _mouth?.dispose();
    _amplitude?.dispose();
    _blink?.dispose();
  }
}
```

And the widget that hosts it:

```dart
class MochiView extends StatefulWidget {
  const MochiView({super.key, required this.onReady});
  final void Function(MochiController) onReady;

  @override
  State<MochiView> createState() => _MochiViewState();
}

class _MochiViewState extends State<MochiView> {
  late final fileLoader = FileLoader.fromAsset(
    'assets/rive/mochi.riv',
    riveFactory: Factory.rive,   // Rive Renderer (full fidelity)
  );

  MochiController? _mochi;

  @override
  void dispose() {
    _mochi?.dispose();
    fileLoader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RiveWidgetBuilder(
      fileLoader: fileLoader,
      // If your file has more than one state machine, pass:
      //   controller: (file) => RiveWidgetController(
      //     file,
      //     stateMachineSelector: StateMachineSelector.byName('Mochi'),
      //   ),
      builder: (context, state) => switch (state) {
        RiveLoading() => const Center(child: CircularProgressIndicator()),
        RiveFailed()  => Center(child: Text('Failed: ${state.error}')),
        RiveLoaded()  => _buildLoaded(state.controller),
      },
    );
  }

  Widget _buildLoaded(RiveWidgetController controller) {
    _mochi ??= () {
      final m = MochiController(controller);
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onReady(m));
      return m;
    }();
    return RiveWidget(controller: controller, fit: Fit.contain);
  }
}
```

> The state machine in your `.riv` is named **`Mochi`**. If `RiveWidgetController(file)`
> picks the wrong one (it defaults to the artboard's default machine), name it
> explicitly with `StateMachineSelector.byName('Mochi')` as shown in the comment.

---

## 4. Drive the high-level state from your pipeline

Map each phase of your STT → LLM → TTS loop to a `Mode`. This is exactly the wiring
from the rig spec, translated to Dart:

```dart
late final MochiController mochi; // set from MochiView.onReady

void wirePipeline() {
  stt.onStart      = ()  => mochi.setMode(Mode.attention);  // mic open, listening
  stt.onFinal      = ()  => mochi.setMode(Mode.thinking);   // got transcript → LLM
  llm.onFirstToken = ()  => mochi.setMode(Mode.speaking);   // TTS begins
  tts.onEnd        = ()  => mochi.setMode(Mode.idle);

  // sentiment / result hooks — momentary pulses
  agent.onSuccess  = ()  => mochi.flash(Mode.excited);
  agent.onError    = ()  => mochi.flash(Mode.disappointed);
}
```

`flash()` pulses Excited/Disappointed for ~1.5 s then returns to Idle, matching the
demo's "play sample → return to idle" behaviour.

---

## 5. Lip-sync from sherpa-onnx TTS (the reliable route)

Your character's mouth should follow the **audio it is speaking** — i.e. the TTS
output. sherpa-onnx TTS hands you raw PCM `Float32` samples. You play them *and* tap
the same samples to compute a loudness envelope, then either:

- **Route A — amplitude blend:** write the smoothed envelope to `amplitude` and let
  the Mouth layer's 1-D blend open the mouth proportionally. Simplest, very robust.
- **Route B — 6 visemes:** bucket the envelope into the six mouth shapes and write
  `mouth`. Crisper, more articulated.

Both read from the same envelope; pick one. Here's the envelope + both routes in Dart.

```dart
import 'dart:typed_data';
import 'dart:math' as math;

class LipSync {
  LipSync(this.mochi);
  final MochiController mochi;

  double _sma = 0;                 // smoothed amplitude (0..1)
  int _currentViseme = 0;
  int _lastSwitchMs = 0;
  static const _holdMs = 70;       // min time a viseme stays up (anti-chatter)

  /// Feed every chunk of PCM that sherpa hands you (the same chunk you enqueue
  /// to your audio player). `samples` are Float32 in roughly [-1, 1].
  void onAudioChunk(Float32List samples) {
    if (samples.isEmpty) return;

    // RMS loudness of this chunk
    double sum = 0;
    for (final s in samples) sum += s * s;
    final rms = math.sqrt(sum / samples.length);     // ~0..0.3
    final amp = math.min(1.0, rms * 3.2);            // normalise → 0..1
    _sma = _sma * 0.6 + amp * 0.4;                    // smooth (kills jitter)

    // ---- Route A: comment this out if you use Route B ----
    // mochi.setAmplitude(_sma);

    // ---- Route B: 6-viseme bucketing ----
    final target = _visemeFor(_sma);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (target != _currentViseme && now - _lastSwitchMs > _holdMs) {
      _currentViseme = target;
      _lastSwitchMs = now;
      mochi.setMouth(target);
    }
  }

  /// Thresholds ordered by openness (closed → wide). NOTE the mouth numbers are
  /// NOT in numeric order — they map by how open the shape is. Do not replace
  /// this with `floor(amp * 6)`.
  int _visemeFor(double amp) {
    if (amp < 0.08) return 1;  // MBP — lips closed (silence/gaps)
    if (amp < 0.28) return 0;  // REST — barely open
    if (amp < 0.48) return 4;  // U — small round
    if (amp < 0.66) return 3;  // E — wide
    if (amp < 0.84) return 5;  // O — round open
    return 2;                  // AI — wide open
  }

  /// Call when TTS playback ends so the mouth doesn't freeze on a shape.
  void reset() {
    _sma = 0;
    _currentViseme = 0;
    mochi.setMouth(0);          // back to rest
    // mochi.setAmplitude(0);   // if using Route A
  }
}
```

### Hooking it to sherpa-onnx TTS

sherpa-onnx synthesises audio and can deliver it **in chunks via a callback** as it
generates, which is what lets the mouth move in real time instead of all at once at
the end. Run synthesis off the UI thread (an isolate or `compute`) and marshal the
`mouth`/`amplitude` writes back to the main thread — Rive inputs must be written on
the platform (main) thread.

```dart
// Pseudostructure — exact callback signature can vary slightly by sherpa_onnx
// version, so check OfflineTts.generateWithCallback in your installed version.
final lip = LipSync(mochi);

void speak(String text) {
  mochi.setMode(Mode.speaking);

  tts.generateWithCallback(
    text: text,
    sid: 0,
    speed: 1.0,
    callback: (Float32List chunk) {
      audioPlayer.feed(chunk);     // enqueue PCM for playback (your player)
      lip.onAudioChunk(chunk);     // drive the mouth from the SAME samples
      return 1;                    // return 1 to keep generating, 0 to stop
    },
  );

  // when playback finishes:
  // mochi.setMode(Mode.idle);
  // lip.reset();
}
```

If you instead generate the whole clip at once (`tts.generate(...)` returns
`GeneratedAudio` with `.samples` and `.sampleRate`), slice the samples into ~20–40 ms
windows and call `lip.onAudioChunk` once per window in sync with playback position.

> **Sample rate matters for chunk size, not for the envelope.** A 22050 Hz VITS voice
> at 30 fps is ~735 samples per frame; a 24000 Hz Kokoro voice is ~800. RMS over a
> ~20–40 ms window tracks playback well. If the mouth lags or races the audio, adjust
> `_holdMs` and the `* 3.2` gain, not the math.

---

## 6. Blinking

`blink` is a Trigger. Fire it on a random 2–5 s timer, and skip it while Excited
(state 4 uses happy arc eyes):

```dart
import 'dart:async';
import 'dart:math';

class Blinker {
  Blinker(this.mochi);
  final MochiController mochi;
  final _rng = Random();
  Timer? _timer;
  Mode _mode = Mode.idle;

  void setMode(Mode m) => _mode = m;

  void start() => _schedule();
  void stop()  => _timer?.cancel();

  void _schedule() {
    final ms = 2000 + _rng.nextInt(3000); // 2–5 s
    _timer = Timer(Duration(milliseconds: ms), () {
      if (_mode != Mode.excited) mochi.blink();
      _schedule();
    });
  }
}
```

Keep `Blinker._mode` in sync whenever you call `mochi.setMode(...)`.

---

## 7. Putting it together

```dart
class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key});
  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  MochiController? mochi;
  LipSync? lip;
  Blinker? blinker;

  void _onReady(MochiController m) {
    mochi = m;
    lip = LipSync(m);
    blinker = Blinker(m)..start();
    m.setMode(Mode.idle);
    // wirePipeline(); // attach your STT/LLM/TTS hooks here
  }

  void _setMode(Mode mode) {
    mochi?.setMode(mode);
    blinker?.setMode(mode);
  }

  @override
  void dispose() {
    blinker?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AspectRatio(
          aspectRatio: 1, // artboard is 512×512
          child: MochiView(onReady: _onReady),
        ),
      ),
    );
  }
}
```

---

## 8. Phoneme-accurate lip-sync (advanced, optional)

You mentioned getting phonemes from sherpa. Two honest caveats before you build this:

1. **sherpa-onnx TTS does not expose aligned phoneme timestamps through the standard
   Flutter API.** It returns audio samples (and the streaming callback above). The
   engines use phonemes internally (e.g. espeak-ng tokens), but you don't get a timed
   `[(phoneme, startMs, endMs)]` list back from the Dart binding. So for the character
   *speaking*, the amplitude/viseme route in §5 is the practical choice.
2. **Phonemes from sherpa ASR describe the *user's* speech, not the character's.** If
   your "get phonemes" refers to ASR, those drive nothing on the talking mouth — they'd
   only be useful for a "repeat after me" style feature.

If you *do* obtain a timed phoneme/viseme stream (from a forced aligner like Montreal
Forced Aligner offline, a TTS model that emits token durations, or Rhubarb-style
analysis of the rendered audio), driving the mouth is straightforward — map phonemes to
your six visemes and write `mouth` on a scheduled timeline:

```dart
// phoneme group → mouth enum
int visemeForPhoneme(String p) {
  switch (p) {
    case 'p': case 'b': case 'm':              return 1; // MBP
    case 'aa': case 'ay': case 'ae': case 'ah': return 2; // AI
    case 'iy': case 'ih': case 'ey':            return 3; // E
    case 'uw': case 'uh': case 'w':             return 4; // U
    case 'ow': case 'oy': case 'ao':            return 5; // O
    default:                                    return 0; // REST
  }
}

// Given a list of (viseme, startMs) cues, schedule them against playback start:
void scheduleVisemes(List<({int viseme, int startMs})> cues) {
  final t0 = DateTime.now().millisecondsSinceEpoch;
  for (final cue in cues) {
    final delay = cue.startMs - (DateTime.now().millisecondsSinceEpoch - t0);
    Future.delayed(Duration(milliseconds: delay.clamp(0, 1 << 30)),
        () => mochi.setMouth(cue.viseme));
  }
}
```

Treat this as an upgrade path. Ship the amplitude/viseme route first; it reads as
convincing speech and needs nothing but the audio you're already playing.

---

## 9. Gotchas & checklist

- **Call `RiveNative.init()` in `main()`** before any Rive widget, or you'll crash.
- **Write inputs on the main thread.** If TTS runs in an isolate, send chunks back to
  the UI isolate and call `setMouth`/`setAmplitude` there.
- **Reset the mouth when speaking ends** (`lip.reset()` → `mouth = 0`), otherwise the
  last viseme freezes on the face. The state machine's `state != 2 → mouth-off`
  transition handles the layer side; this handles the input side.
- **Keep viseme transitions ~0 s in the editor.** Long cross-fades smear the visemes
  and you lose the crispness — verify in the editor, not in code.
- **Pick one mouth route**, not both. Don't write `amplitude` and `mouth` at the same
  time or the two mouth approaches fight.
- **Dispose** the controller, inputs, blinker timer, and file loader.
- **Tune two numbers** if it looks off: the `* 3.2` gain (overall mouth openness) and
  `_holdMs` (snappiness vs. chatter). Leave the threshold table alone.

### Input quick reference

| Input       | Write with                  | Values                                            |
|-------------|-----------------------------|---------------------------------------------------|
| `state`     | `mochi.setMode(Mode.x)`     | 0 idle·1 thinking·2 speaking·3 attention·4 excited·5 disappointed |
| `mouth`     | `mochi.setMouth(n)`         | 0 rest·1 mbp·2 ai·3 e·4 u·5 o                      |
| `amplitude` | `mochi.setAmplitude(0..1)`  | 0 closed → 1 fully open                            |
| `blink`     | `mochi.blink()`             | trigger; fire every 2–5 s, skip while excited      |

---

## Appendix A — Loading the file other ways

```dart
// From bytes you already have:
final file = await File.decode(bytes, factory: Factory.rive);

// From a bundled asset, manually:
final file = await File.asset('assets/rive/mochi.riv', riveFactory: Factory.rive);

// From a URL:
final file = await File.url('https://example.com/mochi.riv', riveFactory: Factory.rive);
```

## Appendix B — If you migrate to Data Binding (View Models)

Rive recommends Data Binding over classic Inputs going forward. If you rebuild the rig
to expose a View Model (e.g. number properties `state`, `mouth`, `amplitude`), the only
thing that changes is the write call:

```dart
final vm = controller.dataBind(DataBind.auto());
final stateProp = vm.number('state');
stateProp?.value = Mode.speaking.index.toDouble();
```

Everything in §4–§8 (lifecycle mapping, the envelope, bucketing, blink timer) is
unchanged — those compute *what* number to write; data binding only changes the
plumbing of *how* it's written. Confirm the exact `dataBind` / property accessor names
against your installed `rive` version, as the binding API is still evolving.
