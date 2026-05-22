import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/errors/polite_error.dart';
import '../../core/models/models.dart';
import '../../core/providers/cached_providers.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/refreshing_dot.dart';

class ScenariosScreen extends ConsumerStatefulWidget {
  const ScenariosScreen({super.key});

  @override
  ConsumerState<ScenariosScreen> createState() => _ScenariosScreenState();
}

class _ScenariosScreenState extends ConsumerState<ScenariosScreen> {
  String? _category;
  int? _difficulty;
  String _query = '';

  static const _categories = ['travel', 'business', 'social', 'daily'];
  static const _difficultyLabels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  @override
  Widget build(BuildContext context) {
    final cached = ref.watch(scenariosProvider);
    final locale = ref.watch(localeProvider).languageCode;

    // The full scenario list is cached; filtering runs client-side, so
    // typing a query or tapping a chip is instant — no network per filter.
    final all = cached.value ?? const <Scenario>[];
    final filtered = all.where((s) {
      if (_category != null && s.category != _category) return false;
      if (_difficulty != null && s.difficulty != _difficulty) return false;
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final inTitle = s.title.forLocale(locale).toLowerCase().contains(q);
        final inDesc =
            s.description.forLocale(locale).toLowerCase().contains(q);
        if (!inTitle && !inDesc) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Scenarios'),
            if (cached.refreshing && cached.hasValue) ...[
              const SizedBox(width: 10),
              const RefreshingDot(),
            ],
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search scenarios…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _Chip(label: 'All', selected: _category == null, onTap: () => setState(() => _category = null)),
                for (final c in _categories)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _Chip(
                      label: _capitalize(c),
                      selected: _category == c,
                      onTap: () => setState(() => _category = _category == c ? null : c),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < _difficultyLabels.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _Chip(
                      label: _difficultyLabels[i],
                      selected: _difficulty == i + 1,
                      onTap: () => setState(() => _difficulty = _difficulty == i + 1 ? null : i + 1),
                      compact: true,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(scenariosProvider.notifier).refresh(),
              child: _list(context, cached, filtered, locale),
            ),
          ),
        ],
      ),
    );
  }

  /// The list area: the filtered tiles, an empty state, a cold-launch
  /// spinner, or a polite error if the very first fetch failed with no
  /// cache to fall back on.
  Widget _list(
    BuildContext context,
    Cached<List<Scenario>> cached,
    List<Scenario> filtered,
    String locale,
  ) {
    if (!cached.hasValue) {
      // Cold first launch — nothing cached yet.
      if (cached.error != null) {
        logRawError('scenarios_screen', cached.error!,
            cached.stackTrace ?? StackTrace.current);
        return PoliteErrorCenter(
          error: cached.error!,
          context: ErrorContext.loadList,
          onRetry: () => ref.read(scenariosProvider.notifier).refresh(),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }
    if (filtered.isEmpty) {
      // Kept scrollable so pull-to-refresh still works on the empty state.
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text('No scenarios match your filters.')),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _ScenarioTile(
        scenario: filtered[i],
        locale: locale,
        onStart: () => context.push(AppRoute.scenarioBrief(filtered[i].id)),
      ),
    );
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: compact ? 4 : 8),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : scheme.onSurface,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: compact ? 12 : 14,
          ),
        ),
      ),
    );
  }
}

class _ScenarioTile extends StatelessWidget {
  const _ScenarioTile({required this.scenario, required this.locale, required this.onStart});
  final Scenario scenario;
  final String locale;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final levelLabels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    final levelLabel = scenario.difficulty >= 1 && scenario.difficulty <= 6
        ? levelLabels[scenario.difficulty - 1]
        : '—';
    return InkWell(
      onTap: onStart,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(levelLabel,
                  style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(scenario.title.forLocale(locale),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(scenario.description.forLocale(locale),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text('${scenario.estimatedMinutes} min',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                      const SizedBox(width: 12),
                      Icon(Icons.star_outline, size: 14, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text('${scenario.xpReward} XP',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: scheme.outline),
          ],
        ),
      ),
    );
  }
}
