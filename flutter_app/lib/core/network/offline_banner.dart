import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'network_status.dart';

/// Slim red banner that pops in from the top when the device loses
/// connectivity and slides away again when it comes back. Mount once
/// inside the app shell — `_AppShell` in `app_router.dart` — so every
/// screen below it gets the banner for free.
///
/// We intentionally do **not** block the underlying UI: read-only
/// screens (settings, history) still work from local cache, and the
/// banner is just an ambient cue. The Dio NetworkInterceptor handles
/// the "you can't actually do that right now" path for write actions.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final statusAsync = ref.watch(networkStatusProvider);
    final isOffline = statusAsync.maybeWhen(
      data: (s) => s == NetworkStatus.offline,
      orElse: () => false,
    );

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: !isOffline
            ? const SizedBox.shrink()
            : Material(
                key: const ValueKey('offline'),
                color: scheme.errorContainer,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 18,
                          color: scheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "You're offline. Some features need a connection.",
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: scheme.onErrorContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
