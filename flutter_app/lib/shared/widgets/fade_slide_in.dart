import 'package:flutter/material.dart';

/// One-shot fade + upward slide entrance.
///
/// Uses [TweenAnimationBuilder] so there is no [AnimationController] to
/// manage — the animation plays once when the widget is first inserted and
/// then stays idle forever (zero ongoing cost).
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 280),
    this.slideDistance = 16.0,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Pixels the widget slides up during the entrance (always upward).
  final double slideDistance;

  @override
  Widget build(BuildContext context) {
    final total = delay + duration;
    final startFraction = total.inMicroseconds > 0
        ? delay.inMicroseconds / total.inMicroseconds
        : 0.0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: total,
      curve: Interval(startFraction, 1.0, curve: Curves.easeOut),
      builder: (_, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, slideDistance * (1.0 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
