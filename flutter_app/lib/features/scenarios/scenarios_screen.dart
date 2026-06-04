import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
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
  String _query = '';
  int? _cefrLevel;

  static const _cefrLabels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  @override
  Widget build(BuildContext context) {
    final cached = ref.watch(scenariosProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final locale = ref.watch(localeProvider).languageCode;

    // Resolve the origin for /uploads/... image URLs (same logic as brief screen).
    const envOverride = String.fromEnvironment('API_BASE_URL');
    final config = ref.watch(appConfigProvider).asData?.value ?? AppConfig.defaults;
    final apiBase = envOverride.isNotEmpty ? envOverride : config.backendBaseUrl;
    String strip(String s, String suffix) {
      final i = s.indexOf(suffix);
      return i > 0 ? s.substring(0, i) : s;
    }
    final uploadsOrigin = strip(strip(apiBase, '/api'), '/vfls');

    // The full scenario list is cached; filtering runs client-side, so
    // typing a query or tapping a chip is instant — no network per filter.
    final all = cached.value ?? const <Scenario>[];
    final categories =
        categoriesAsync.value ??
        all.map((s) => s.category).toSet().map((slug) {
          return Category(
            slug: slug,
            title: I18nText(en: _capitalize(slug)),
          );
        }).toList();
    final filtered = all.where((s) {
      if (_category != null && s.category != _category) return false;
      if (_cefrLevel != null) {
        final level = s.cefrLevel ?? s.difficulty;
        if (level != _cefrLevel) return false;
      }
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final inTitle = s.title.forLocale(locale).toLowerCase().contains(q);
        final inDesc = s.description
            .forLocale(locale)
            .toLowerCase()
            .contains(q);
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
                _Chip(
                  label: 'All',
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                for (final category in categories)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _Chip(
                      label: category.title.forLocale(locale),
                      selected: _category == category.slug,
                      onTap: () => setState(
                        () => _category = _category == category.slug
                            ? null
                            : category.slug,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _Chip(
                  label: 'All levels',
                  selected: _cefrLevel == null,
                  onTap: () => setState(() => _cefrLevel = null),
                ),
                for (var i = 0; i < _cefrLabels.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _Chip(
                      label: _cefrLabels[i],
                      selected: _cefrLevel == i + 1,
                      onTap: () => setState(() =>
                          _cefrLevel = _cefrLevel == i + 1 ? null : i + 1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: RefreshIndicator(
                key: ValueKey(
                  cached.hasValue
                      ? 'data'
                      : cached.error != null
                      ? 'error'
                      : 'loading',
                ),
                onRefresh: () => ref.read(scenariosProvider.notifier).refresh(),
                child: _list(context, cached, filtered, locale, uploadsOrigin),
              ),
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
    String uploadsOrigin,
  ) {
    if (!cached.hasValue) {
      // Cold first launch — nothing cached yet.
      if (cached.error != null) {
        logRawError(
          'scenarios_screen',
          cached.error!,
          cached.stackTrace ?? StackTrace.current,
        );
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
        uploadsOrigin: uploadsOrigin,
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
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
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
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ScenarioTile extends StatelessWidget {
  const _ScenarioTile({
    required this.scenario,
    required this.locale,
    required this.uploadsOrigin,
    required this.onStart,
  });
  final Scenario scenario;
  final String locale;
  final String uploadsOrigin;
  final VoidCallback onStart;

  String _resolveImage(String url) {
    if (url.startsWith('http') || url.startsWith('asset:')) return url;
    return '$uploadsOrigin$url';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lvl = scenario.cefrLevel ?? scenario.difficulty;
    final levelLabel = (lvl >= 1 && lvl <= 6)
        ? ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'][lvl - 1]
        : 'Lv $lvl';
    final heroUrl = scenario.imageUrl;
    final hasHero = heroUrl != null && heroUrl.isNotEmpty;
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
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 48,
                height: 48,
                child: hasHero
                    ? Image.network(
                        _resolveImage(heroUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _LevelBadge(
                          label: levelLabel,
                          scheme: scheme,
                        ),
                      )
                    : _LevelBadge(label: levelLabel, scheme: scheme),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scenario.title.forLocale(locale),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scenario.description.forLocale(locale),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${scenario.estimatedMinutes} min',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.star_outline,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${scenario.xpReward} XP',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
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

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.label, required this.scheme});
  final String label;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) => Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        color: scheme.primaryContainer,
        child: Text(
          label,
          style: TextStyle(
            color: scheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}
