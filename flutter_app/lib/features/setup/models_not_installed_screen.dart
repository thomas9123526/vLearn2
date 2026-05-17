import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/errors/polite_error.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/storage/model_registry.dart';

/// First-launch screen shown when the sherpa-onnx model bundle isn't on disk.
///
/// Per Mode-B (admin pre-placement) the app **never downloads** models. This
/// screen helps the admin (or end-user under admin direction) drop the bundle
/// into the right place — and offers a text-only fallback so the user isn't
/// blocked from the app entirely.
class ModelsNotInstalledScreen extends ConsumerWidget {
  const ModelsNotInstalledScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(modelRegistrySnapshotProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Speech setup')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: snap.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) {
              logRawError('models_not_installed_screen', e, st);
              return PoliteErrorCenter(
                error: e,
                context: ErrorContext.loadDetail,
                onRetry: () =>
                    ref.invalidate(modelRegistrySnapshotProvider),
              );
            },
            data: (s) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.mic_off_outlined, size: 56, color: scheme.primary),
                const SizedBox(height: 16),
                Text(
                  _titleFor(s.status),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _bodyFor(s.status),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expected location',
                        style:
                            Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        s.modelRoot,
                        style: TextStyle(
                          fontFamily: 'EditorialMono',
                          fontSize: 13,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Drop the model bundle here, including a manifest.json with SHA-256 entries for each file, then return and tap Re-check.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (s.verifications.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Files',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final v in s.verifications)
                          ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            leading: Icon(
                              _iconFor(v.status),
                              color: _colorFor(v.status, scheme),
                            ),
                            title: Text(v.file.relativePath),
                            subtitle:
                                v.message == null ? null : Text(v.message!),
                          ),
                      ],
                    ),
                  ),
                ] else
                  const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Re-check'),
                        onPressed: () =>
                            ref.invalidate(modelRegistrySnapshotProvider),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.text_fields),
                        label: const Text('Text-only mode'),
                        onPressed: () async {
                          // Persist the opt-out so the router stops forcing
                          // this screen on every cold boot. The opt-out is
                          // automatically cleared when a valid bundle is
                          // detected (see SpeechReadyBanner.dispose).
                          await ref
                              .read(appSettingsProvider.notifier)
                              .acknowledgeTextOnly();
                          if (context.mounted) context.go('/home');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _titleFor(ModelRegistryStatus s) => switch (s) {
        ModelRegistryStatus.manifestMissing => 'Speech models not installed',
        ModelRegistryStatus.corrupt => 'Speech models look corrupted',
        ModelRegistryStatus.notReady => 'Speech models not ready',
        ModelRegistryStatus.ready => 'Speech models ready',
      };

  String _bodyFor(ModelRegistryStatus s) => switch (s) {
        ModelRegistryStatus.manifestMissing =>
          'No manifest.json was found in the expected folder. Your administrator should drop the bundle there per the deployment instructions.',
        ModelRegistryStatus.corrupt =>
          'Some files are missing or their SHA-256 hashes don\'t match the manifest. Re-copy the bundle and tap Re-check.',
        ModelRegistryStatus.notReady =>
          'The model directory exists but the bundle isn\'t complete yet.',
        ModelRegistryStatus.ready => 'You\'re all set.',
      };

  IconData _iconFor(FileVerificationStatus s) => switch (s) {
        FileVerificationStatus.ok => Icons.check_circle_outline,
        FileVerificationStatus.missing => Icons.error_outline,
        FileVerificationStatus.hashMismatch => Icons.warning_amber_outlined,
        FileVerificationStatus.sizeMismatch => Icons.warning_amber_outlined,
      };

  Color _colorFor(FileVerificationStatus s, ColorScheme scheme) =>
      switch (s) {
        FileVerificationStatus.ok => Colors.green,
        FileVerificationStatus.missing => scheme.error,
        FileVerificationStatus.hashMismatch => Colors.orange,
        FileVerificationStatus.sizeMismatch => Colors.orange,
      };
}
