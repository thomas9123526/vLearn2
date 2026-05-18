import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/app_apis.dart';
import '../../core/errors/polite_error.dart';
import '../../core/providers/auth_provider.dart';

/// Aggregated `/progress` payload. Backend shape (see ProgressService):
/// `{ ...UserProgressEntity, latestSnapshot: SkillSnapshotEntity | null }`.
final _progressProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(progressApiProvider).myProgress();
});

final _snapshotsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(progressApiProvider).snapshots();
});

final _completionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(progressApiProvider).completions();
});

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final progress = ref.watch(_progressProvider);
    final snapshots = ref.watch(_snapshotsProvider);
    final completions = ref.watch(_completionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_progressProvider);
          ref.invalidate(_snapshotsProvider);
          ref.invalidate(_completionsProvider);
        },
        child: progress.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) {
            logRawError('progress_screen.load', e, st);
            return PoliteErrorCenter(
              error: e,
              context: ErrorContext.loadDetail,
              onRetry: () => ref.invalidate(_progressProvider),
            );
          },
          data: (p) {
            final latest = p['latestSnapshot'] as Map<String, dynamic>?;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _CefrCard(currentLevel: user?.currentLevel ?? 1),
                const SizedBox(height: 16),
                _ActivityCard(
                  minutesTotal: (p['minutes_spoken_total'] as num? ?? 0).toInt(),
                  minutesWeek: (p['minutes_spoken_this_week'] as num? ?? 0).toInt(),
                  sessionsTotal: (p['sessions_total'] as num? ?? 0).toInt(),
                  sessionsWeek: (p['sessions_this_week'] as num? ?? 0).toInt(),
                  snapshotsAsync: snapshots,
                ),
                const SizedBox(height: 16),
                _SkillBreakdown(latest: latest),
                const SizedBox(height: 16),
                _CompletionsCard(async: completions),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// CEFR ladder card. Maps the user's `current_level` (1..6) to an A1..C2
/// label and animates a 6-stop progress bar.
class _CefrCard extends StatelessWidget {
  const _CefrCard({required this.currentLevel});
  final int currentLevel;

  static const _labels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  static const _names = [
    'Beginner',
    'Elementary',
    'Intermediate',
    'Upper intermediate',
    'Advanced',
    'Proficient',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clamped = currentLevel.clamp(1, 6);
    final label = _labels[clamped - 1];
    final name = _names[clamped - 1];
    final fillPercent = clamped / 6.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT LEVEL',
                      style: TextStyle(
                        fontFamily: 'EditorialMono',
                        fontSize: 11,
                        letterSpacing: 1.4,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (clamped < 6)
                      Text(
                        'Climbing toward ${_labels[clamped]}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fillPercent),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 10,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(scheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final l in _labels)
                Text(
                  l,
                  style: TextStyle(
                    fontFamily: 'EditorialMono',
                    fontSize: 10,
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

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.minutesTotal,
    required this.minutesWeek,
    required this.sessionsTotal,
    required this.sessionsWeek,
    required this.snapshotsAsync,
  });

  final int minutesTotal;
  final int minutesWeek;
  final int sessionsTotal;
  final int sessionsWeek;
  final AsyncValue<List<Map<String, dynamic>>> snapshotsAsync;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MINUTES SPOKEN',
            style: TextStyle(
              fontFamily: 'EditorialMono',
              fontSize: 11,
              letterSpacing: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: minutesTotal),
                duration: const Duration(milliseconds: 900),
                builder: (_, v, _) => Text(
                  '$v',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              if (minutesWeek > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '+$minutesWeek this week',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: snapshotsAsync.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (list) => _MiniBars(snapshots: list),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Sessions',
                  total: sessionsTotal,
                  week: sessionsWeek,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: scheme.outline.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Total min',
                  total: minutesTotal,
                  week: minutesWeek,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBars extends StatelessWidget {
  const _MiniBars({required this.snapshots});
  final List<Map<String, dynamic>> snapshots;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Take up to last 7 snapshots, oldest→newest.
    final recent = snapshots.take(7).toList().reversed.toList();
    if (recent.isEmpty) {
      return Center(
        child: Text(
          'Practice a few sessions to see your trend here.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      );
    }
    final maxSessions = recent
        .map((s) => (s['sessions_in_window'] as num? ?? 0).toInt())
        .fold<int>(1, (a, b) => a > b ? a : b);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < recent.length; i++)
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                begin: 0,
                end:
                    (recent[i]['sessions_in_window'] as num? ?? 0).toDouble() /
                    maxSessions,
              ),
              duration: Duration(milliseconds: 400 + i * 120),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  height: 80 * v.clamp(0.05, 1.0),
                  decoration: BoxDecoration(
                    color: i == recent.length - 1
                        ? scheme.primary
                        : scheme.primary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.total, required this.week});
  final String label;
  final int total;
  final int week;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          '$total',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        Text(
          '$label · $week this week',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _SkillBreakdown extends StatelessWidget {
  const _SkillBreakdown({required this.latest});
  final Map<String, dynamic>? latest;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final skills = <String, int?>{
      'Pronunciation': (latest?['pronunciation'] as num?)?.toInt(),
      'Fluency': (latest?['fluency'] as num?)?.toInt(),
      'Vocabulary': (latest?['vocabulary'] as num?)?.toInt(),
      'Grammar': (latest?['grammar'] as num?)?.toInt(),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SKILL BREAKDOWN',
            style: TextStyle(
              fontFamily: 'EditorialMono',
              fontSize: 11,
              letterSpacing: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          for (final entry in skills.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SkillRow(name: entry.key, value: entry.value),
            ),
          if (latest == null) ...[
            const SizedBox(height: 4),
            Text(
              'Finish a conversation to record your first scores.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.name, required this.value});
  final String name;
  final int? value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final v = value ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Text(
              value == null ? '—' : '$v',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'EditorialMono',
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: v / 100),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (_, t, _) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: t,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(_colorFor(name, scheme)),
            ),
          ),
        ),
      ],
    );
  }

  Color _colorFor(String skill, ColorScheme scheme) {
    return switch (skill) {
      'Pronunciation' => scheme.primary,
      'Fluency' => scheme.secondary,
      'Vocabulary' => scheme.tertiary,
      'Grammar' => Colors.teal,
      _ => scheme.primary,
    };
  }
}

class _CompletionsCard extends StatelessWidget {
  const _CompletionsCard({required this.async});
  final AsyncValue<List<Map<String, dynamic>>> async;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SCENARIOS COMPLETED',
            style: TextStyle(
              fontFamily: 'EditorialMono',
              fontSize: 11,
              letterSpacing: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          async.when(
            loading: () => const SizedBox(
              height: 60,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (list) => list.isEmpty
                ? Text(
                    'No completed scenarios yet — pick one and start talking.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  )
                : Column(
                    children: [
                      for (final c in list.take(6))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  c['scenario_id'] as String? ?? 'Scenario',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              Text(
                                '×${(c['completion_count'] as num? ?? 1).toInt()}',
                                style: TextStyle(
                                  fontFamily: 'EditorialMono',
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
