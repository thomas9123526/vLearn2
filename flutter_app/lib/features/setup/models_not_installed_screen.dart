import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/datapack/datapack_provider.dart';
import '../../core/errors/polite_error.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/storage/model_registry.dart';
import '../../shared/widgets/datapack_progress_view.dart';

/// Speech-setup screen — shown when the sherpa-onnx model bundle isn't
/// ready (the router redirects here on the first conversation attempt).
///
/// The models ship as a datapack `.dat` tagged `group: "speech"`,
/// `unpack_phase: "on-demand"`. This screen unpacks that group the
/// first time it's reached, showing a live 0–100% progress view; once
/// done it re-checks [ModelRegistry] and lets the user continue.
///
/// If no speech `.dat` is on the device at all, it falls back to
/// guidance (place the pack, then Retry) plus a text-only opt-out so
/// the user isn't blocked from the rest of the app.
class ModelsNotInstalledScreen extends ConsumerStatefulWidget {
  const ModelsNotInstalledScreen({super.key});

  @override
  ConsumerState<ModelsNotInstalledScreen> createState() =>
      _ModelsNotInstalledScreenState();
}

class _ModelsNotInstalledScreenState
    extends ConsumerState<ModelsNotInstalledScreen> {
  @override
  void initState() {
    super.initState();
    // Kick off the speech-group unpack once, after first frame — but
    // only if no group unpack has run yet this session (the controller
    // state survives screen rebuilds).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final phase = ref.read(dataPackGroupControllerProvider).phase;
      if (phase == DataPackGroupPhase.idle) {
        ref
            .read(dataPackGroupControllerProvider.notifier)
            .ensureGroup('speech');
      }
    });
  }

  void _retry() {
    final ctrl = ref.read(dataPackGroupControllerProvider.notifier);
    ctrl.reset();
    ctrl.ensureGroup('speech');
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(dataPackGroupControllerProvider);

    // When the group unpack finishes, re-resolve the model registry so
    // this screen (and the router) see the freshly-unpacked models.
    ref.listen(dataPackGroupControllerProvider, (prev, next) {
      if (next.isDone && (prev == null || !prev.isDone)) {
        ref.invalidate(modelRegistrySnapshotProvider);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Speech setup')),
      body: SafeArea(
        child: switch (group.phase) {
          DataPackGroupPhase.running => DataPackProgressView(
              fraction: group.fraction,
              status: group.status,
              title: 'Setting up speech…',
            ),
          DataPackGroupPhase.error => _ErrorBody(
              message: group.error ?? 'Speech setup failed.',
              onRetry: _retry,
            ),
          // idle (before the post-frame fires) or done → defer to the
          // model registry, which now reflects the unpacked location.
          DataPackGroupPhase.idle ||
          DataPackGroupPhase.done =>
            _registryBody(context),
        },
      ),
    );
  }

  Widget _registryBody(BuildContext context) {
    final snap = ref.watch(modelRegistrySnapshotProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: snap.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          logRawError('models_not_installed_screen', e, st);
          return PoliteErrorCenter(
            error: e,
            context: ErrorContext.loadDetail,
            onRetry: () => ref.invalidate(modelRegistrySnapshotProvider),
          );
        },
        data: (s) => s.isReady
            ? _ReadyBody(onContinue: () => context.go('/home'))
            : _NotFoundBody(
                modelRoot: s.modelRoot,
                onRetry: _retry,
                onTextOnly: () async {
                  await ref
                      .read(appSettingsProvider.notifier)
                      .acknowledgeTextOnly();
                  if (context.mounted) context.go('/home');
                },
              ),
      ),
    );
  }
}

/// Speech models verified present — let the user move on.
class _ReadyBody extends StatelessWidget {
  const _ReadyBody({required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 56, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            'Speech is ready',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'The speech models are installed and verified. '
            'You can start a conversation now.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: onContinue, child: const Text('Continue')),
        ],
      ),
    );
  }
}

/// The group unpack ran but speech still isn't ready — usually because
/// no speech `.dat` is on the device. Offer Retry + text-only.
class _NotFoundBody extends StatelessWidget {
  const _NotFoundBody({
    required this.modelRoot,
    required this.onRetry,
    required this.onTextOnly,
  });
  final String modelRoot;
  final VoidCallback onRetry;
  final Future<void> Function() onTextOnly;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.mic_off_outlined, size: 56, color: scheme.primary),
        const SizedBox(height: 16),
        Text(
          'Speech models not installed',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'No speech data pack was found on this device. Ask your '
          'administrator to place the speech ".dat" pack in the '
          'app\'s data folder, then tap Retry.',
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
                'Models would unpack to',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                modelRoot,
                style: const TextStyle(
                  fontFamily: 'EditorialMono',
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: onRetry,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.text_fields),
                label: const Text('Text-only mode'),
                onPressed: onTextOnly,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Speech setup hit an error (bad pack, unpack failure, …).
class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.error_outline, size: 56, color: scheme.error),
          const SizedBox(height: 16),
          Text(
            'Speech setup failed',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'EditorialMono',
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
