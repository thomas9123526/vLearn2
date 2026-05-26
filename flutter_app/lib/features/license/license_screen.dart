import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/license/machine_id_service.dart';

/// Settings → License. Shows the device's machine ID, current
/// license status (placeholder for now), and a "Get License" CTA.
///
/// The real verify flow + cert-fetch UI (camera QR on Android,
/// `/sdcard/룡마/가상외국어회화/lic/` watcher on both platforms) is
/// described in `docs/0525/17_license_plan.md`. This screen is the
/// surface those flows will plug into.
class LicenseScreen extends ConsumerWidget {
  const LicenseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final machineId = ref.watch(machineIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('License')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: [
          Text(
            'Device',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Machine ID', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  machineId.when(
                    loading: () => const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (e, _) => Text('Could not read: $e'),
                    data: (id) => SelectableText(
                      id,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'License status',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            color: scheme.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.help_outline, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'No license installed',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Scan a license QR or drop a .lic file in the device\'s license folder.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Get License'),
            onPressed: () {
              // QR-scan flow goes here. Plan doc:
              //   docs/0525/17_license_plan.md §5
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'License acquisition not wired yet — see plan doc.',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Card(
            color: scheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'License verification is in scaffolding stage. The Machine ID '
                'above is a Dart fingerprint; native AAR / DLL libraries will '
                'replace it. See docs/0525/17_license_plan.md.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onTertiaryContainer,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final machineIdProvider = FutureProvider<String>((ref) async {
  return ref.read(machineIdServiceProvider).get();
});
