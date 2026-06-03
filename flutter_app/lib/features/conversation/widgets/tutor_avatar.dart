import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_app/core/config/app_config.dart';
import 'package:flutter_app/core/config/rive_render_config.dart';
import 'package:rive/rive.dart' as rive;

import '../../../core/models/models.dart';
import 'cartoon_face.dart';

/// Visual state the tutor avatar is currently in.
enum TutorMood {
  /// At rest — gentle breathing only.
  idle,

  /// TTS is playing — mouth driven by amplitude from sherpa-onnx PCM.
  speaking,

  /// User is recording — tutor leans in (Attention state).
  listening,

  /// Positive moment — flash Excited then auto-return to Idle.
  praising,

  /// Negative / timeout moment — flash Disappointed then auto-return to Idle.
  disappointed,

  /// User has been silent a while — encourage them to speak.
  encouraging,

  /// Awaiting AI reply after STT — Thinking state.
  thinking,
}

/// Mochi (emo_visemes.riv) `state` input enum — must stay in sync with the rig.
///
/// | value | expression   | type    |
/// |-------|-------------|---------|
/// | 0     | Idle         | resting |
/// | 1     | Thinking     | resting |
/// | 2     | Speaking     | resting |
/// | 3     | Attention    | resting |
/// | 4     | Excited      | moment  |
/// | 5     | Disappointed | moment  |
///
/// Moment states (4, 5) auto-return to Idle inside the rig after ~1.5 s.
const _kStateIdle = 0.0;
const _kStateThinking = 1.0;
const _kStateSpeaking = 2.0;
const _kStateAttention = 3.0;
const _kStateExcited = 4.0;
const _kStateDisappointed = 5.0;

/// Big tutor avatar used in Tutor (Face) mode.
///
/// Combines:
///   * a circular body filled with the emo_visemes.riv Mochi animation;
///   * a pulsing glow ring tied to [mood];
///   * three floating emotion icons that fade in/out by mood.
///
/// [amplitude] (0.0–1.0) is the real-time loudness value from the TTS
/// service's RMS envelope — it is bucketed into one of six viseme shapes
/// (mouth=0–5) and written to the Mochi `mouth` input while speaking.
class TutorAvatar extends StatefulWidget {
  const TutorAvatar({
    required this.persona,
    required this.mood,
    this.amplitude = 0.0,
    this.size = 240,
    super.key,
  });

  final Persona persona;
  final TutorMood mood;

  /// 0.0 (closed) → 1.0 (wide open). Only has a visible effect when
  /// `state == 2` (Speaking) — the Mochi rig gates the Mouth layer to
  /// that state. Pass 0 when not speaking.
  final double amplitude;
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

  /// Fast pulse synced to TTS audio playback.
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  /// Listening ring — slow rotate while the mic is open.
  late final AnimationController _ring =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..repeat();

  // ─── emo_visemes.riv / Mochi state-machine inputs ─────────────────────────
  //
  // State machine name: "Mochi"
  //
  // Inputs:
  //   Number  state — 0 Idle | 1 Thinking | 2 Speaking | 3 Attention |
  //                   4 Excited (moment) | 5 Disappointed (moment)
  //   Number  mouth — 0 rest | 1 mbp | 2 ai | 3 e | 4 u | 5 o
  //                   Driven by viseme bucketing from the RMS amplitude.
  //   Trigger blink — fire to play one blink
  //
  // All lookups are nullable — a null means the input isn't exported on
  // the current asset version and the write is silently skipped.
  rive.NumberInput? _stateInput;
  rive.NumberInput? _mouthInput;
  rive.TriggerInput? _blinkInput;

  // Viseme anti-chatter state — prevent mouth from flickering faster than 70ms.
  int _currentViseme = 0;
  int _lastSwitchMs = 0;
  static const int _holdMs = 70;

  /// Shared file loader — decoded once per app session, reused on every
  /// mount so re-entering the conversation screen never flashes a blank.
  // Backend chosen by [RiveRenderConfig.useGpu]: native (GPU) renderer where
  // hardware supports it, Flutter/Skia renderer otherwise. On the VMware dev
  // VM the native renderer crashes against the virtual GPU, so GPU defaults
  // off on Windows. See rive_render_config.dart.
  static final rive.FileLoader _fileLoader = rive.FileLoader.fromAsset(
    'assets/animations/emoticon_visemes/emo_visemes.riv',
    riveFactory: RiveRenderConfig.factory,
  );

  /// Natural blink scheduler — fires every 2–5 s regardless of mood.
  Timer? _blinkTimer;
  final math.Random _rng = math.Random();

  @override
  void didUpdateWidget(covariant TutorAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.mood == TutorMood.speaking) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }

    if (oldWidget.mood != widget.mood) {
      _applyMoodToRive(widget.mood);
    }

    // Always sync mouth viseme so the mouth tracks loudness continuously.
    if (oldWidget.amplitude != widget.amplitude) {
      _updateMouthFromAmplitude(widget.amplitude);
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _breath.dispose();
    _pulse.dispose();
    _ring.dispose();
    super.dispose();
  }

  // ─── Rive helpers ──────────────────────────────────────────────────────────

  void _onRiveLoaded(rive.RiveLoaded state) {
    if (!mounted) return;
    try {
      final sm = state.controller.stateMachine;
      // ignore: deprecated_member_use
      _stateInput = sm.number('state');
      // ignore: deprecated_member_use
      _mouthInput = sm.number('mouth');
      // ignore: deprecated_member_use
      _blinkInput = sm.trigger('blink');

      AppConfig.logx(
        'rive-init',
        'Mochi SM "${sm.name}" — inputs: '
            'state=${_stateInput != null}, '
            'mouth=${_mouthInput != null}, '
            'blink=${_blinkInput != null}',
      );

      _scheduleNextBlink();
      _applyMoodToRive(widget.mood);
    } catch (e, st) {
      AppConfig.logx('rive-init failed', 'Mochi: $e\n$st');
      _stateInput = null;
      _mouthInput = null;
      _blinkInput = null;
    }
  }

  /// Bucket [amp] (0.0–1.0 RMS envelope) into one of the six viseme shapes
  /// and write it to the Mochi `mouth` input with anti-chatter debounce.
  void _updateMouthFromAmplitude(double amp) {
    if (widget.mood != TutorMood.speaking) return;
    final target = _visemeFor(amp.clamp(0.0, 1.0));
    final now = DateTime.now().millisecondsSinceEpoch;
    if (target != _currentViseme && now - _lastSwitchMs > _holdMs) {
      _currentViseme = target;
      _lastSwitchMs = now;
      try {
        _mouthInput?.value = target.toDouble();
      } catch (_) {}
    }
  }

  /// Map RMS amplitude to one of the six Mochi mouth visemes.
  ///
  /// The thresholds are ordered by mouth openness, not by enum value —
  /// do not replace with `(amp * 6).floor()`.
  ///
  /// | amp range  | mouth | shape          |
  /// |------------|-------|----------------|
  /// | < 0.08     | 1     | MBP — closed   |
  /// | 0.08–0.28  | 0     | REST           |
  /// | 0.28–0.48  | 4     | U — small round|
  /// | 0.48–0.66  | 3     | E — wide       |
  /// | 0.66–0.84  | 5     | O — round open |
  /// | ≥ 0.84     | 2     | AI — wide open |
  int _visemeFor(double amp) {
    if (amp < 0.08) return 1;
    if (amp < 0.28) return 0;
    if (amp < 0.48) return 4;
    if (amp < 0.66) return 3;
    if (amp < 0.84) return 5;
    return 2;
  }

  /// Blink every 2–5 s. The Mochi rig suppresses blinking in state 4
  /// (Excited) internally, but we guard it here too just in case.
  void _scheduleNextBlink() {
    _blinkTimer?.cancel();
    if (_blinkInput == null) return;
    final ms = 2000 + _rng.nextInt(3000);
    _blinkTimer = Timer(Duration(milliseconds: ms), () {
      if (!mounted) return;
      if (widget.mood != TutorMood.praising) _blinkInput?.fire();
      _scheduleNextBlink();
    });
  }

  /// Map [TutorMood] → Mochi `state` number and push it to the rig.
  void _applyMoodToRive(TutorMood mood) {
    try {
      final stateVal = switch (mood) {
        TutorMood.idle        => _kStateIdle,
        TutorMood.thinking    => _kStateThinking,
        TutorMood.speaking    => _kStateSpeaking,
        TutorMood.listening   => _kStateAttention,
        TutorMood.praising    => _kStateExcited,       // moment — rig auto-returns
        TutorMood.disappointed => _kStateDisappointed, // moment — rig auto-returns
        TutorMood.encouraging => _kStateIdle,           // no dedicated state
      };
      _stateInput?.value = stateVal;
      // Reset mouth to rest whenever we leave Speaking so the face closes.
      if (mood != TutorMood.speaking) {
        _mouthInput?.value = 0.0;
        _currentViseme = 0;
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

  @override
  Widget build(BuildContext context) {
    final from = _hex(widget.persona.gradientFrom);
    final to = _hex(widget.persona.gradientTo);

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
                    child: rive.RiveWidgetBuilder(
                      key: const ValueKey('rive-mochi'),
                      fileLoader: _fileLoader,
                      onLoaded: _onRiveLoaded,
                      onFailed: (e, st) => AppConfig.logx(
                        'rive parse failed',
                        'emo_visemes.riv: $e',
                      ),
                      builder: (context, state) {
                        switch (state) {
                          case rive.RiveLoaded(:final controller):
                            return rive.RiveWidget(
                              controller: controller,
                              fit: rive.Fit.cover,
                            );
                          case rive.RiveLoading():
                            return const SizedBox.expand();
                          case rive.RiveFailed():
                            return CartoonFace(
                              key: ValueKey('face-${widget.persona.id}'),
                              persona: widget.persona,
                              mood: widget.mood,
                              size: widget.size,
                            );
                        }
                      },
                    ),
                  ),
                ),
              );
            },
          ),

          // Floating emotion cluster.
          ..._emoticonsFor(widget.mood, widget.size),
        ],
      ),
    );
  }

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
