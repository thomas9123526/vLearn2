import 'package:flutter/material.dart';

/// Circular progress ring with a centered value label. Used in the session
/// report and the home XP card. Defaults to the theme's primary gradient.
class ScoreRing extends StatelessWidget {
  const ScoreRing({
    required this.value,
    this.max = 100,
    this.size = 160,
    this.strokeWidth = 12,
    this.label,
    this.suffix,
    super.key,
  });

  final num value;
  final num max;
  final double size;
  final double strokeWidth;
  final String? label;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = (value / max).clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: pct,
              strokeWidth: strokeWidth,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(scheme.primary),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$value${suffix ?? ''}',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (label != null)
                Text(
                  label!,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
