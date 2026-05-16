import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/app_apis.dart';
import '../../core/models/models.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/router/app_router.dart';

final _scenariosListProvider = FutureProvider.family<List<Scenario>, _Filters>((ref, f) async {
  final raw = await ref.read(scenariosApiProvider).list(
        category: f.category,
        difficulty: f.difficulty,
        q: f.query,
      );
  return raw.map(Scenario.fromJson).toList();
});

final _personasProvider = FutureProvider<List<Persona>>((ref) async {
  final raw = await ref.read(personasApiProvider).list();
  return raw.map(Persona.fromJson).toList();
});

class _Filters {
  const _Filters({this.category, this.difficulty, this.query});
  final String? category;
  final int? difficulty;
  final String? query;
  @override
  bool operator ==(Object o) =>
      o is _Filters && o.category == category && o.difficulty == difficulty && o.query == query;
  @override
  int get hashCode => Object.hash(category, difficulty, query);
}

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
    final filters = _Filters(
      category: _category,
      difficulty: _difficulty,
      query: _query.isEmpty ? null : _query,
    );
    final scenarios = ref.watch(_scenariosListProvider(filters));
    final locale = ref.watch(localeProvider).languageCode;

    return Scaffold(
      appBar: AppBar(title: const Text('Scenarios')),
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
            child: scenarios.when(
              data: (list) => list.isEmpty
                  ? const Center(child: Text('No scenarios match your filters.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _ScenarioTile(
                        scenario: list[i],
                        locale: locale,
                        onStart: () => _startSession(list[i]),
                      ),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load: $e')),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  Future<void> _startSession(Scenario scenario) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    String personaId = user.activePersonaId ?? '';
    if (personaId.isEmpty) {
      final personas = await ref.read(_personasProvider.future);
      if (personas.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No personas available')),
          );
        }
        return;
      }
      personaId = personas.first.id;
    }

    try {
      final session = await ref.read(conversationsApiProvider).startSession(
            personaId: personaId,
            scenarioId: scenario.id,
            mode: 'chat',
          );
      final sessionId = session['id'] as String;
      if (mounted) context.push(AppRoute.conversation(sessionId));
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to start: $e')));
      }
    }
  }
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
