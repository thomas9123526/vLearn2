import 'dart:math' as math;

import 'package:flutter/material.dart';
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
  }

  @override
  void dispose() {
    _breath.dispose();
    _pulse.dispose();
    _ring.dispose();
    super.dispose();
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
    final asset = widget.persona.riveAsset;

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
                    child: asset != null
                        ? rive.RiveAnimation.asset(
                            'assets/animations/$asset',
                            fit: BoxFit.cover,
                          )
                        : CartoonFace(
                            persona: widget.persona,
                            mood: widget.mood,
                            size: widget.size,
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
