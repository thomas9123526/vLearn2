import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/layout_config_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/router/app_router.dart';

/// Top-level chrome for the four main tab routes (home / scenarios /
/// progress / settings). Layout follows the design handoff:
///
/// * **Mobile** (width < 720) — Material `NavigationBar` at the bottom,
///   matching the design's `MobileTabs` row.
/// * **Desktop** (width ≥ 720) — fixed-width left sidebar with logo,
///   nav items, and a profile footer. Mirrors the design's `Sidebar`
///   component in `vLearn2Spec/design_handoff_freetalk/reference/app.jsx`.
///
/// Same `tabs.*` visibility flags apply in both layouts so an admin can
/// hide tabs without breaking the chrome.
class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  /// Breakpoint kept in sync with the splash screen
  /// (`SplashScreen.build`) so the two views agree on what "desktop" is.
  static const double _desktopBreakpoint = 720;
  static const double _sidebarWidth = 220;

  static const _allTabs = <_TabSpec>[
    _TabSpec(route: AppRoute.home,                icon: Icons.home_outlined,         selected: Icons.home,         label: 'Home',      flagKey: 'tabs.home'),
    _TabSpec(route: AppRoute.scenarios,           icon: Icons.explore_outlined,      selected: Icons.explore,      label: 'Scenarios', flagKey: 'tabs.scenarios'),
    // History fits a short label on the bottom nav (mobile) but the longer
    // "Conversation history" reads better in the desktop sidebar.
    _TabSpec(route: AppRoute.conversationHistory, icon: Icons.history_outlined,      selected: Icons.history,      label: 'History',   desktopLabel: 'Conversation history', flagKey: 'tabs.history'),
    _TabSpec(route: AppRoute.progress,            icon: Icons.trending_up_outlined,  selected: Icons.trending_up,  label: 'Progress',  flagKey: 'tabs.progress'),
    _TabSpec(route: AppRoute.settings,            icon: Icons.settings_outlined,     selected: Icons.settings,     label: 'Settings',  flagKey: 'tabs.settings'),
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

    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _DesktopSidebar(
              tabs: visibleTabs,
              activeIndex: activeIndex,
              onTap: (i) => context.go(visibleTabs[i].route),
            ),
            Expanded(child: child),
          ],
        ),
      );
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
    this.desktopLabel,
  });

  final String route;
  final IconData icon;
  final IconData selected;

  /// Compact label used on the mobile `NavigationBar`.
  final String label;

  /// Longer label preferred by the desktop sidebar. Falls back to [label]
  /// when null, so most tabs need not set this.
  final String? desktopLabel;

  final String flagKey;

  String labelFor({required bool isDesktop}) =>
      (isDesktop ? desktopLabel : null) ?? label;
}

// ─── Desktop sidebar ──────────────────────────────────────────────────────

/// Direct port of the `Sidebar` component in
/// `vLearn2Spec/design_handoff_freetalk/reference/app.jsx`. Fixed 220 dp
/// wide, vertical column with: monogram + wordmark header, nav buttons,
/// flexible spacer, then a profile footer.
class _DesktopSidebar extends ConsumerWidget {
  const _DesktopSidebar({
    required this.tabs,
    required this.activeIndex,
    required this.onTap,
  });

  final List<_TabSpec> tabs;
  final int activeIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: AppShell._sidebarWidth,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SidebarHeader(),
          const SizedBox(height: 16),
          for (var i = 0; i < tabs.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: _SidebarItem(
                spec: tabs[i],
                active: i == activeIndex,
                onTap: () => onTap(i),
              ),
            ),
          const Spacer(),
          const Divider(height: 1),
          const SizedBox(height: 10),
          const _SidebarProfileFooter(),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text(
              'F',
              style: TextStyle(
                fontFamily: 'EditorialHeading',
                fontStyle: FontStyle.italic,
                fontSize: 18,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'FreeTalk',
            style: TextStyle(
              fontFamily: 'EditorialHeading',
              fontSize: 20,
              letterSpacing: -0.2,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// One row in the sidebar nav. Accent-filled pill when active, otherwise
/// a subdued label that lifts on hover (matches the design's hover swap
/// to `theme.surfaceAlt`).
class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.spec,
    required this.active,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = widget.active
        ? scheme.primary
        : (_hovered ? scheme.surfaceContainerHighest : Colors.transparent);
    final fg = widget.active ? scheme.onPrimary : scheme.onSurfaceVariant;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                widget.active ? widget.spec.selected : widget.spec.icon,
                size: 16,
                color: fg,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.spec.labelFor(isDesktop: true),
                  style: TextStyle(
                    color: fg,
                    fontFamily: 'EditorialBody',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom of the sidebar. Mirrors the design's profile chip — avatar emoji,
/// display name, then a mono "B1 · 12🔥" line built from current level and
/// streak. Hidden while auth is still resolving so we don't flash a stub.
class _SidebarProfileFooter extends ConsumerWidget {
  const _SidebarProfileFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    const cefr = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    // currentLevel is 1-based per backend; clamp defensively.
    final levelIdx = (user.currentLevel - 1).clamp(0, cefr.length - 1);
    final levelLabel = cefr[levelIdx];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: scheme.primaryContainer,
            child: Text(user.avatarEmoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$levelLabel · ${user.streakDays}🔥',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontFamily: 'EditorialMono',
                    fontSize: 10,
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
