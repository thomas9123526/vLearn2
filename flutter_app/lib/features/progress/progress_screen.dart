import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/polite_error.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/cached_providers.dart';
import '../../shared/widgets/layout_visibility.dart';
import '../../shared/widgets/refreshing_dot.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLevel = ref.watch(authProvider).user?.currentLevel ?? 1;
    final progress = ref.watch(progressSummaryProvider);
    final snapshots = ref.watch(progressSnapshotsProvider);
    final completions = ref.watch(progressCompletionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait<void>([
            ref.read(progressSummaryProvider.notifier).refresh(),
            ref.read(progressSnapshotsProvider.notifier).refresh(),
            ref.read(progressCompletionsProvider.notifier).refresh(),
          ]);
        },
        child:
            _body(context, ref, currentLevel, progress, snapshots, completions),
      ),
    );
  }

  /// Cache-first body: the cards render the instant a cached `/progress`
  /// copy exists; a cold first launch shows a spinner; a first-ever fetch
  /// failure (nothing cached) shows a polite error.
  Widget _body(
    BuildContext context,
    WidgetRef ref,
    int currentLevel,
    Cached<Map<String, dynamic>> progress,
    Cached<List<Map<String, dynamic>>> snapshots,
    Cached<List<Map<String, dynamic>>> completions,
  ) {
    final p = progress.value;
    if (p == null) {
      if (progress.error != null) {
        logRawError('progress_screen.load', progress.error!,
            progress.stackTrace ?? StackTrace.current);
        return PoliteErrorCenter(
          error: progress.error!,
          context: ErrorContext.loadDetail,
          onRetry: () => ref.read(progressSummaryProvider.notifier).refresh(),
        );
      }
      // Cold first launch — spinner kept inside a scrollable so
      // pull-to-refresh still works.
      return ListView(
        children: const [
          SizedBox(height: 240),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }
    final latest = p['latestSnapshot'] as Map<String, dynamic>?;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        LayoutVisibility(
          configKey: 'progress.level_badge',
          child: _CefrCard(currentLevel: currentLevel),
        ),
        const SizedBox(height: 16),
        LayoutVisibility(
          configKey: 'progress.weekly_chart',
          child: _ActivityCard(
            minutesTotal: (p['minutes_spoken_total'] as num? ?? 0).toInt(),
            minutesWeek: (p['minutes_spoken_this_week'] as num? ?? 0).toInt(),
            sessionsTotal: (p['sessions_total'] as num? ?? 0).toInt(),
            sessionsWeek: (p['sessions_this_week'] as num? ?? 0).toInt(),
            snapshots: snapshots,
            refreshing: progress.refreshing || snapshots.refreshing,
          ),
        ),
        const SizedBox(height: 16),
        LayoutVisibility(
          configKey: 'progress.skill_radar',
          child: _SkillBreakdown(
            latest: latest,
            refreshing: progress.refreshing,
          ),
        ),
        const SizedBox(height: 16),
        LayoutVisibility(
          configKey: 'progress.achievements',
          child: _CompletionsCard(
            completions: completions,
            refreshing: completions.refreshing,
          ),
        ),
      ],
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
    required this.snapshots,
    required this.refreshing,
  });

  final int minutesTotal;
  final int minutesWeek;
  final int sessionsTotal;
  final int sessionsWeek;
  final Cached<List<Map<String, dynamic>>> snapshots;
  final bool refreshing;

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
          _SectionLabel('MINUTES SPOKEN', refreshing: refreshing),
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
            child: snapshots.hasValue
                ? _MiniBars(snapshots: snapshots.value!)
                : snapshots.error != null
                    ? const SizedBox.shrink()
                    : const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
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
  const _SkillBreakdown({required this.latest, required this.refreshing});
  final Map<String, dynamic>? latest;
  final bool refreshing;

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
          _SectionLabel('SKILL BREAKDOWN', refreshing: refreshing),
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
  const _CompletionsCard({required this.completions, required this.refreshing});
  final Cached<List<Map<String, dynamic>>> completions;
  final bool refreshing;

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
          _SectionLabel('SCENARIOS COMPLETED', refreshing: refreshing),
          const SizedBox(height: 12),
          _completionsBody(context, scheme),
        ],
      ),
    );
  }

  Widget _completionsBody(BuildContext context, ColorScheme scheme) {
    final list = completions.value;
    if (list == null) {
      // Cold launch — or a first fetch that failed with no cache.
      if (completions.error != null) return const SizedBox.shrink();
      return const SizedBox(
        height: 60,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (list.isEmpty) {
      return Text(
        'No completed scenarios yet — pick one and start talking.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
      );
    }
    return Column(
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
    );
  }
}

/// A card's small-caps heading with an optional inline [RefreshingDot]
/// shown while that section is refreshing in the background.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.refreshing = false});
  final String text;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontFamily: 'EditorialMono',
            fontSize: 11,
            letterSpacing: 1.4,
            color: scheme.onSurfaceVariant,
          ),
        ),
        if (refreshing) ...[
          const SizedBox(width: 8),
          const RefreshingDot(size: 12),
        ],
      ],
    );
  }
}
