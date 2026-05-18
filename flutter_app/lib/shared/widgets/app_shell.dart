import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/layout_config_provider.dart';
import '../../core/router/app_router.dart';

/// Bottom-nav shell for the main tabs (home / scenarios / progress / settings).
/// Tab visibility is controlled by `tabs.*` layout flags in the admin panel.
class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  static const _allTabs = <_TabSpec>[
    _TabSpec(route: AppRoute.home,      icon: Icons.home_outlined,         selected: Icons.home,         label: 'Home',      flagKey: 'tabs.home'),
    _TabSpec(route: AppRoute.scenarios, icon: Icons.explore_outlined,      selected: Icons.explore,      label: 'Scenarios', flagKey: 'tabs.scenarios'),
    _TabSpec(route: AppRoute.progress,  icon: Icons.trending_up_outlined,  selected: Icons.trending_up,  label: 'Progress',  flagKey: 'tabs.progress'),
    _TabSpec(route: AppRoute.settings,  icon: Icons.settings_outlined,     selected: Icons.settings,     label: 'Settings',  flagKey: 'tabs.settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfgAsync = ref.watch(layoutConfigProvider);
    final visibleTabs = cfgAsync.maybeWhen(
      data: (cfg) {
        final filtered = _allTabs.where((t) => cfg.isVisible(t.flagKey)).toList();
        // Never show zero tabs — fall back to all if every flag is false.
        return filtered.isEmpty ? List<_TabSpec>.unmodifiable(_allTabs) : filtered;
      },
      orElse: () => List<_TabSpec>.unmodifiable(_allTabs),
    );

    final loc = GoRouterState.of(context).matchedLocation;
    var activeIndex = 0;
    for (var i = 0; i < visibleTabs.length; i++) {
      if (loc.startsWith(visibleTabs[i].route)) {
        activeIndex = i;
        break;
      }
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeIndex,
        onDestinationSelected: (i) => context.go(visibleTabs[i].route),
        destinations: [
          for (final t in visibleTabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.selected),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({
    required this.route,
    required this.icon,
    required this.selected,
    required this.label,
    required this.flagKey,
  });

  final String route;
  final IconData icon;
  final IconData selected;
  final String label;
  final String flagKey;
}
