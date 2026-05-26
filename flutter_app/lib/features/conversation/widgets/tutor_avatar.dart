import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_app/core/config/app_config.dart';
import 'package:rive/rive.dart' as rive;

import '../../../core/models/models.dart';
import 'cartoon_face.dart';

/// Visual state the tutor avatar is currently in. Drives both the body
/// animation and the floating emotion icons around the avatar.
enum TutorMood {
  /// At rest, no audio playing, not listening — gentle breathing only.
  idle,

  /// Speaking back the assistant reply — mouth pulses with the TTS audio.
  speaking,

  /// User is recording. The tutor leans in slightly, "listening" ring
  /// animates around the head.
  listening,

  /// Last user turn was strong — quick smile + thumbs up cluster.
  praising,

  /// Last user turn had clear errors — a small disappointed cluster.
  /// Comes with the polite-correction body language.
  disappointed,

  /// User has been silent for a while — gentle "go ahead, you got this"
  /// encouragement.
  encouraging,
}

/// Big tutor avatar used in Tutor (Face) mode. Combines:
///   * a circular body filled with a Rive animation (if asset is shipped)
///     or a gradient + name initial fallback;
///   * a pulsing glow ring tied to [mood];
///   * three floating emotion icons that fade in/out by mood.
class TutorAvatar extends StatefulWidget {
  const TutorAvatar({
    required this.persona,
    required this.mood,
    this.size = 240,
    super.key,
  });

  final Persona persona;
  final TutorMood mood;
  final double size;

  @override
  State<TutorAvatar> createState() => _TutorAvatarState();
}

class _TutorAvatarState extends State<TutorAvatar>
    with TickerProviderStateMixin {
  /// Slow breathing animation — runs forever, used in [TutorMood.idle].
  late final AnimationController _breath =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat(reverse: true);

  /// Fast pulse synced to TTS audio playback. Stops when not speaking so it
  /// doesn't drain battery.
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  /// Listening ring — slow rotate while the mic is open.
  late final AnimationController _ring =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..repeat();

  // ─── Rive state-machine integration ───────────────────────────────
  //
  // The character `.riv` (e.g. tutor_hiro.riv) exposes a state machine
  // with these inputs (any may be missing on stub assets — we look
  // each one up with `findInput` and `is`-check the runtime type, so
  // a missing input cleanly becomes a no-op):
  //
  //   trigger blink       — fire to play one blink
  //   number  emotion     — 0 neutral, 1 smile, 2 sad, 3 surprised, …
  //   number  mouth_shape — 0 closed, 1 "A", 2 "E", 3 "I", 4 "O", 5 "U"
  //   trigger nod         — head nod (praising)
  //   trigger shake       — head shake (disappointed)
  //   bool    attention   — leaning-in / listening pose
  //
  // Only blink, emotion=1, and mouth_shape=1 ship in tutor_hiro.riv
  // right now; everything else is wired here so the moment the .riv
  // gains the missing animations no Flutter change is needed.
  rive.SMITrigger? _blinkInput;
  rive.SMINumber? _emotionInput;
  rive.SMINumber? _mouthShapeInput;
  rive.SMITrigger? _nodInput;
  rive.SMITrigger? _shakeInput;
  rive.SMIBool? _attentionInput;

  /// Random natural-blink scheduler — independent of mood so the
  /// character keeps blinking while speaking or listening too.
  Timer? _blinkTimer;
  final math.Random _rng = math.Random();

  /// Mouth-viseme cycler — only runs while [TutorMood.speaking]. With
  /// only `mouth_shape == 1` built today this just toggles open/close;
  /// when E/I/O/U ship, change [_visemeAt] to cycle 1..5.
  Timer? _mouthTimer;

  @override
  void didUpdateWidget(covariant TutorAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mood-driven controller management. We only animate what's currently
    // visible to keep idle CPU low.
    if (widget.mood == TutorMood.speaking) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
    if (oldWidget.mood != widget.mood) {
      _applyMoodToRive(widget.mood);
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _mouthTimer?.cancel();
    // The state-machine controller is owned by the Rive artboard;
    // disposing the artboard (which Rive does when its widget is
    // unmounted) tears it down for us — nothing to drop here.
    _breath.dispose();
    _pulse.dispose();
    _ring.dispose();
    super.dispose();
  }

  // ─── Rive helpers ─────────────────────────────────────────────────

  /// Called by [rive.RiveAnimation.asset] once the artboard is loaded.
  /// Attaches the state machine, resolves every input, kicks off the
  /// blink timer, and applies the current mood so the character isn't
  /// stuck on its default pose for one frame.
  ///
  /// Everything inside is wrapped in a try/catch because the rive
  /// 0.13.x runtime has been seen to throw `RangeError (length): … 0..1: 2`
  /// when reading state-machine internals exported by a newer Rive
  /// editor. A throw here would otherwise bubble up as an unhandled
  /// FlutterError; instead we log it and let the animation play
  /// without state-machine wiring (default timeline only).
  void _onRiveInit(rive.Artboard artboard) {
    if (!mounted) return;
    try {
      if (artboard.stateMachines.isEmpty) {
        AppConfig.logx('rive-init', 'no state machines on ${widget.persona.id}');
        return;
      }
      final smName = artboard.stateMachines.first.name;
      final controller =
          rive.StateMachineController.fromArtboard(artboard, smName);
      if (controller == null) {
        AppConfig.logx('rive-init', 'could not build SM "$smName"');
        return;
      }
      // The artboard keeps the controller alive once added — we only
      // need handles to the inputs from here on, not the controller.
      artboard.addController(controller);

      // findInput<T>('name') returns the SMIInput<T>? — runtime subtype
      // (SMITrigger / SMIBool / SMINumber) is checked with `is` so a
      // shape mismatch between Dart and the Rive file degrades to a
      // no-op rather than a runtime cast error.
      final blink     = controller.findInput<bool>('blink');
      final nod       = controller.findInput<bool>('nod');
      final shake     = controller.findInput<bool>('shake');
      final attention = controller.findInput<bool>('attention');
      final emotion   = controller.findInput<double>('emotion');
      final mouth     = controller.findInput<double>('mouth_shape');
      if (blink     is rive.SMITrigger) _blinkInput     = blink;
      if (nod       is rive.SMITrigger) _nodInput       = nod;
      if (shake     is rive.SMITrigger) _shakeInput     = shake;
      if (attention is rive.SMIBool)    _attentionInput = attention;
      if (emotion   is rive.SMINumber)  _emotionInput   = emotion;
      if (mouth     is rive.SMINumber)  _mouthShapeInput = mouth;

      AppConfig.logx(
        'rive-init',
        '${widget.persona.id} SM "$smName" — inputs: '
            'blink=${_blinkInput != null}, '
            'emotion=${_emotionInput != null}, '
            'mouth_shape=${_mouthShapeInput != null}, '
            'nod=${_nodInput != null}, '
            'shake=${_shakeInput != null}, '
            'attention=${_attentionInput != null}',
      );

      _scheduleNextBlink();
      _applyMoodToRive(widget.mood);
    } catch (e, st) {
      AppConfig.logx('rive-init failed',
          '${widget.persona.id}: $e\n$st');
      // Drop any partially-attached inputs so writes don't fire into a
      // half-broken state machine.
      _blinkInput = null;
      _emotionInput = null;
      _mouthShapeInput = null;
      _nodInput = null;
      _shakeInput = null;
      _attentionInput = null;
    }
  }

  /// Re-arms [_blinkTimer] with a random 3.5–7 s delay. Recursive — the
  /// timer callback fires the blink and immediately schedules the next.
  void _scheduleNextBlink() {
    _blinkTimer?.cancel();
    if (_blinkInput == null) return; // no blink rig — don't burn a timer
    final ms = 3500 + _rng.nextInt(3500);
    _blinkTimer = Timer(Duration(milliseconds: ms), () {
      if (!mounted) return;
      _blinkInput?.fire();
      _scheduleNextBlink();
    });
  }

  /// Viseme value to drive at the [tick]th 160 ms slot while speaking.
  /// Currently alternates 1 ("A") and 0 (closed) to give a simple
  /// talking mouth with the only viseme that's built. Swap for
  /// `((tick % 5) + 1).toDouble()` once E/I/O/U ship.
  double _visemeAt(int tick) => (tick % 2 == 0) ? 1.0 : 0.0;

  void _startMouthCycle() {
    _mouthTimer?.cancel();
    if (_mouthShapeInput == null) return;
    _mouthTimer = Timer.periodic(const Duration(milliseconds: 160), (t) {
      _mouthShapeInput?.value = _visemeAt(t.tick);
    });
  }

  void _stopMouthCycle() {
    _mouthTimer?.cancel();
    _mouthTimer = null;
    _mouthShapeInput?.value = 0;
  }

  /// Translates [TutorMood] into Rive input state. Safe to call before
  /// `_onRiveInit` has run — all the inputs are null then and nothing
  /// happens. Also wrapped in a try/catch: the rive 0.13.x runtime can
  /// throw on `.value =` or `.fire()` when the underlying state-machine
  /// graph (exported by a newer editor) doesn't have a state for the
  /// value we're pushing. A throw here would otherwise bubble up as a
  /// Flutter framework error mid-frame; we'd rather just keep the
  /// previous pose.
  void _applyMoodToRive(TutorMood mood) {
    try {
      switch (mood) {
        case TutorMood.idle:
          _emotionInput?.value = 0;
          _attentionInput?.value = false;
          _stopMouthCycle();
        case TutorMood.speaking:
          _emotionInput?.value = 1; // gentle smile while talking
          _attentionInput?.value = false;
          _startMouthCycle();
        case TutorMood.listening:
          _emotionInput?.value = 0;
          _attentionInput?.value = true;
          _stopMouthCycle();
        case TutorMood.praising:
          _emotionInput?.value = 1;
          _nodInput?.fire();
          _attentionInput?.value = false;
          _stopMouthCycle();
        case TutorMood.disappointed:
          // tutor_hiro.riv only defines emotion states 0 and 1 today;
          // pushing 2 has been seen to RangeError inside the runtime.
          // Clamp to the highest known "sad-ish" state until a real
          // sad viseme ships — gentle degradation, not a crash.
          _emotionInput?.value = 1;
          _shakeInput?.fire();
          _attentionInput?.value = false;
          _stopMouthCycle();
        case TutorMood.encouraging:
          _emotionInput?.value = 1;
          _attentionInput?.value = false;
          _stopMouthCycle();
      }
    } catch (e) {
      AppConfig.logx('rive-mood failed', '$mood: $e');
    }
  }

  Color _hex(String s) {
    final cleaned = s.replaceFirst('#', '');
    final v = int.parse(cleaned, radix: 16) | 0xFF000000;
    return Color(v);
  }

  /// True only if the asset is bundled AND the `rive` runtime can actually
  /// parse it. A `.riv` exported from a newer Rive editor than our pinned
  /// `rive` package throws mid-parse (RangeError from the binary reader) —
  /// checking that the bytes load is not enough, so we attempt a real import
  /// and let the avatar fall back to [CartoonFace] when it fails.
  Future<bool> _riveAssetUsable(String path) async {
    try {
      final bytes = await rootBundle.load(path);
      rive.RiveFile.import(bytes);
      return true;
    } catch (e) {
      AppConfig.logx('rive parse failed', '$path: $e');
      return false;
    }
  }

  /// Single Rive asset used for every tutor, regardless of what the
  /// backend `personas.rive_asset` column says. The DB still drives
  /// gradient colours and the fallback letter; only the .riv binary is
  /// pinned. Swap this constant (or revert to `widget.persona.riveAsset`)
  /// once per-tutor Rive files are ready.
  static const String _forcedRiveAsset = 'tutor_hiro.riv';

  @override
  Widget build(BuildContext context) {
    final from = _hex(widget.persona.gradientFrom);
    final to = _hex(widget.persona.gradientTo);
    const asset = _forcedRiveAsset;

    AppConfig.logx('assets for', widget.persona.name);
    AppConfig.logx('assets path', '$asset (forced; DB value ignored)');



    return SizedBox(
      width: widget.size + 60,
      height: widget.size + 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer "listening" ring — only visible while mic is open.
          if (widget.mood == TutorMood.listening)
            AnimatedBuilder(
              animation: _ring,
              builder: (_, _) {
                return Transform.rotate(
                  angle: _ring.value * 2 * math.pi,
                  child: Container(
                    width: widget.size + 40,
                    height: widget.size + 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          from.withValues(alpha: 0.0),
                          from.withValues(alpha: 0.6),
                          from.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

          // The body — animates scale via breath or pulse depending on mood.
          AnimatedBuilder(
            animation: Listenable.merge([_breath, _pulse]),
            builder: (_, _) {
              final scale = 1.0 +
                  (_pulse.value * 0.06) +
                  (widget.mood == TutorMood.idle ? _breath.value * 0.02 : 0.0);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [from, to],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: from.withValues(alpha: 0.4),
                        blurRadius: widget.mood == TutorMood.speaking ? 32 : 18,
                        spreadRadius: widget.mood == TutorMood.speaking ? 8 : 4,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: FutureBuilder<bool>(
                      key: ValueKey('rive-${widget.persona.id}-$asset'),
                      future: _riveAssetUsable('assets/animations/$asset'),
                      builder: (context, snap) {
                        if (snap.data == true) {
                          return rive.RiveAnimation.asset(
                            'assets/animations/$asset',
                            key: const ValueKey(asset),
                            fit: BoxFit.cover,
                            onInit: _onRiveInit,
                          );
                        }
                        return CartoonFace(
                          key: ValueKey('face-${widget.persona.id}'),
                          persona: widget.persona,
                          mood: widget.mood,
                          size: widget.size,
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),

          // Floating emotion cluster around the avatar.
          ..._emoticonsFor(widget.mood, widget.size),
        ],
      ),
    );
  }

  /// Tiny set of floating emoji that fade in/out depending on mood. Kept
  /// deliberately small — three icons max — so the avatar doesn't turn into
  /// a slot machine.
  List<Widget> _emoticonsFor(TutorMood mood, double size) {
    final items = switch (mood) {
      TutorMood.praising => const [
          (top: 0.0, right: 0.0, icon: '👍'),
          (top: 0.15, right: 0.85, icon: '⭐'),
          (top: 0.8, right: 0.05, icon: '✨'),
        ],
      TutorMood.disappointed => const [
          (top: 0.0, right: 0.5, icon: '🤔'),
          (top: 0.3, right: 0.05, icon: '💭'),
        ],
      TutorMood.encouraging => const [
          (top: 0.05, right: 0.1, icon: '🌱'),
          (top: 0.7, right: 0.9, icon: '💪'),
        ],
      TutorMood.speaking => const [
          (top: 0.1, right: 0.05, icon: '🗨️'),
        ],
      _ => const <({double top, double right, String icon})>[],
    };
    return items.map((it) {
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 350),
        top: it.top * size,
        right: it.right * size,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: 1,
          child: Text(it.icon, style: const TextStyle(fontSize: 24)),
        ),
      );
    }).toList();
  }
}
