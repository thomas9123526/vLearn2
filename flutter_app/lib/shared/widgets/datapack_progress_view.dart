// Reusable 0–100% progress view for an on-demand datapack unpack.
//
// Driven straight off `DataPackGroupController` state — a host screen
// (e.g. the conversation screen waiting on the "speech" group) does:
//
//   final s = ref.watch(dataPackGroupControllerProvider);
//   if (s.isRunning) {
//     return DataPackProgressView(fraction: s.fraction, status: s.status);
//   }
//
// Stateless + theme-driven so it drops into a dialog, an overlay, or a
// full screen unchanged.

import 'package:flutter/material.dart';

class DataPackProgressView extends StatelessWidget {
  const DataPackProgressView({
    super.key,
    required this.fraction,
    required this.status,
    this.title = 'Preparing data…',
  });

  /// 0.0 – 1.0. Clamped before display.
  final double fraction;

  /// Human-readable line under the bar (current file, etc.).
  final String status;

  /// Headline above the bar.
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clamped = fraction.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: clamped,
                  minHeight: 8,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$percent%',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                status,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
