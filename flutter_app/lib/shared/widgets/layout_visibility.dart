import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/layout_config_provider.dart';

/// Wraps a section that the admin panel can hide remotely. Default visible.
class LayoutVisibility extends ConsumerWidget {
  const LayoutVisibility({
    required this.configKey,
    required this.child,
    this.fallback = true,
    this.whenHidden,
    super.key,
  });

  final String configKey;
  final bool fallback;
  final Widget child;
  final Widget? whenHidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(layoutConfigProvider).valueOrNull;
    final visible = config?.isVisible(configKey, fallback: fallback) ?? fallback;
    return visible ? child : (whenHidden ?? const SizedBox.shrink());
  }
}
