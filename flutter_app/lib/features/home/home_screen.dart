import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/app_apis.dart';
import '../../core/errors/polite_error.dart';
import '../../core/models/models.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/layout_visibility.dart';
import '../news/widgets/bell_icon.dart';
import '../news/widgets/news_strip.dart';

final _scenariosProvider = FutureProvider<List<Scenario>>((ref) async {
  final raw = await ref.read(scenariosApiProvider).list();
  return raw.map(Scenario.fromJson).toList();
});

final _progressProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(progressApiProvider).myProgress();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final scenarios = ref.watch(_scenariosProvider);
    final progress = ref.watch(_progressProvider);
    final locale = ref.watch(localeProvider).languageCode;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: const [
          LayoutVisibility(
            configKey: 'home.notification_bell',
            child: BellIcon(),
          ),
          SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(_scenariosProvider);
            ref.invalidate(_progressProvider);
            await ref.read(authProvider.notifier).refreshProfile();
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _Greeting(user: user, scheme: scheme),
              ),
              const SizedBox(height: 16),
              if (user != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _StreakAndXp(user: user),
                ),
              const SizedBox(height: 16),
              const LayoutVisibility(
                configKey: 'home.news_strip',
                child: NewsStrip(),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: progress.when(
                  data: (p) => _QuickStats(progress: p),
                  loading: () => const Center(child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Recommended scenarios',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: scenarios.when(
                  data: (list) => _ScenarioStrip(scenarios: list.take(4).toList(), locale: locale),
                  loading: () => const _ScenarioStripSkeleton(),
                  error: (e, st) {
                    logRawError('home_screen.scenarios', e, st);
                    return PoliteBanner(
                      text: politeMessageFor(e, context: ErrorContext.loadList),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.user, required this.scheme});
  final UserProfile? user;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greet = hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user == null ? greet : '$greet, ${user!.displayName}',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          "Let's practice some English today.",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _StreakAndXp extends StatelessWidget {
  const _StreakAndXp({required this.user});
  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = (user.xpTotal % 500) / 500.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [scheme.primary, scheme.primaryContainer]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${user.streakDays} day streak',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${user.xpTotal} XP',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${500 - (user.xpTotal % 500)} XP to level ${user.currentLevel + 1}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.progress});
  final Map<String, dynamic> progress;

  @override
  Widget build(BuildContext context) {
    final sessions = (progress['sessions_total'] as num? ?? 0).toInt();
    final minutes = (progress['minutes_spoken_total'] as num? ?? 0).toInt();
    final scenarios = (progress['scenarios_completed'] as num? ?? 0).toInt();
    return Row(
      children: [
        _Stat(value: '$sessions', label: 'Sessions', icon: Icons.chat_bubble_outline),
        const SizedBox(width: 8),
        _Stat(value: '$minutes', label: 'Minutes', icon: Icons.timer_outlined),
        const SizedBox(width: 8),
        _Stat(value: '$scenarios', label: 'Topics', icon: Icons.map_outlined),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.icon});
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScenarioStrip extends StatelessWidget {
  const _ScenarioStrip({required this.scenarios, required this.locale});
  final List<Scenario> scenarios;
  final String locale;

  @override
  Widget build(BuildContext context) {
    if (scenarios.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No scenarios yet — pull to refresh.'),
      );
    }
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: scenarios.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _ScenarioCard(scenario: scenarios[i], locale: locale),
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({required this.scenario, required this.locale});
  final Scenario scenario;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 240,
      child: InkWell(
        onTap: () => context.go(AppRoute.scenarios),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  scenario.category,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onPrimaryContainer),
                ),
              ),
              Text(
                scenario.title.forLocale(locale),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
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
      ),
    );
  }
}

class _ScenarioStripSkeleton extends StatelessWidget {
  const _ScenarioStripSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) => Container(
          width: 240,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

