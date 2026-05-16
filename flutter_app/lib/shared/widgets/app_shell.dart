import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';

/// Bottom-nav shell for the four main tabs (home / scenarios / progress / settings).
class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  static const _tabs = <_TabSpec>[
    _TabSpec(route: AppRoute.home, icon: Icons.home_outlined, selected: Icons.home, label: 'Home'),
    _TabSpec(route: AppRoute.scenarios, icon: Icons.explore_outlined, selected: Icons.explore, label: 'Scenarios'),
    _TabSpec(route: AppRoute.progress, icon: Icons.trending_up_outlined, selected: Icons.trending_up, label: 'Progress'),
    _TabSpec(route: AppRoute.settings, icon: Icons.settings_outlined, selected: Icons.settings, label: 'Settings'),
  ];

  int _activeIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < _tabs.length; i++) {
      if (loc.startsWith(_tabs[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _activeIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => context.go(_tabs[i].route),
        destinations: [
          for (final t in _tabs)
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
  });

  final String route;
  final IconData icon;
  final IconData selected;
  final String label;
}
