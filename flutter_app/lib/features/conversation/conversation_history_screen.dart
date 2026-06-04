import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/app_apis.dart';
import '../../core/errors/polite_error.dart';
import '../../core/models/models.dart';
import '../../core/providers/personas_provider.dart';
import '../../core/router/app_router.dart';

/// All my past + current sessions, most recent first.
///
/// The list intentionally fetches *every* status: active rows resume into
/// [ConversationScreen]; completed/abandoned rows open the same screen,
/// which now switches to read-only when `status != 'active'`.
final _historyProvider = FutureProvider<List<ConversationSession>>((ref) async {
  final raw = await ref.read(conversationsApiProvider).listSessions(limit: 100);
  return raw.map(ConversationSession.fromJson).toList();
});

class ConversationHistoryScreen extends ConsumerWidget {
  const ConversationHistoryScreen({super.key});

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text(
          'Every conversation, transcript, and score will be permanently removed. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(conversationsApiProvider).deleteAllSessions();
      ref.invalidate(_historyProvider);
    } on Exception catch (e, st) {
      if (context.mounted) {
        showPoliteErrorSnack(context, e, tag: 'history.clear_all', stack: st);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(_historyProvider);
    final hasSessions = history.valueOrNull?.isNotEmpty == true;

    return Scaffold(
      appBar: AppBar(
        // No leading back button: this screen is a top-level shell tab
        // (sidebar item on desktop, bottom-nav tab on mobile).
        automaticallyImplyLeading: false,
        title: const Text('Conversation history'),
        actions: [
          if (hasSessions)
            IconButton(
              tooltip: 'Clear all history',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClearAll(context, ref),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: history.when(
          loading: () => const Center(
            key: ValueKey('loading'),
            child: CircularProgressIndicator(),
          ),
          error: (e, st) {
            logRawError('conversation_history.load', e, st);
            return PoliteErrorCenter(
              key: const ValueKey('error'),
              error: e,
              context: ErrorContext.loadList,
              onRetry: () => ref.invalidate(_historyProvider),
            );
          },
          data: (sessions) {
            if (sessions.isEmpty) {
              return const Center(
                key: ValueKey('empty'),
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No conversations yet. Pick a topic to start your first session.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return RefreshIndicator(
              key: const ValueKey('list'),
              onRefresh: () async => ref.invalidate(_historyProvider),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: sessions.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) => _SessionTile(session: sessions[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SessionTile extends ConsumerStatefulWidget {
  const _SessionTile({required this.session});

  final ConversationSession session;

  @override
  ConsumerState<_SessionTile> createState() => _SessionTileState();
}

class _SessionTileState extends ConsumerState<_SessionTile> {
  bool _deleting = false;

  static const _cefrLabels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final session = widget.session;

    final personaAsync = ref.watch(personaByIdProvider(session.personaId));
    final personaName = personaAsync.maybeWhen(
      data: (p) => p?.name ?? 'Tutor',
      orElse: () => 'Tutor',
    );

    final title = session.scenarioTitle ?? 'Free conversation';
    final cefrLevel = session.cefrLevel;
    final cefrLabel = (cefrLevel != null && cefrLevel >= 1 && cefrLevel <= 6)
        ? _cefrLabels[cefrLevel - 1]
        : null;

    final (statusLabel, statusColor) = switch (session.status) {
      'active'    => ('Active',    scheme.primary),
      'completed' => ('Completed', Colors.green.shade700),
      _           => ('Abandoned', scheme.outline),
    };

    return ListTile(
      onTap: _deleting
          ? null
          : () => context.push(AppRoute.conversation(session.id)),
      title: Row(
        children: [
          if (cefrLabel != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                cefrLabel,
                style: TextStyle(
                  fontFamily: 'EditorialMono',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      subtitle: Text(
        '$personaName · ${_formatDate(session.startedAt)} · ${session.turnCount} turns',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Delete from history',
            onPressed: _deleting ? null : _confirmAndDelete,
            icon: _deleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.delete_outline, color: scheme.error),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndDelete() async {
    // IMPORTANT: use the dialog's own `dialogContext` (the `builder`
    // parameter), NOT the outer screen `context`. Since this screen
    // lives inside a ShellRoute, the outer context's nearest Navigator
    // is the shell's nested Navigator — popping THAT would tear down
    // the shell tab itself, empty go_router's match list, and trip
    // a cascade of Navigator-dispose assertions. The dialog's context
    // resolves to the root Navigator (where `showDialog` puts it), so
    // popping there dismisses just the dialog.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: const Text(
          'The transcript and any score will be permanently removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(conversationsApiProvider).deleteSession(widget.session.id);
      // Refresh the parent list — the provider lives outside this widget.
      if (mounted) {
        ref.invalidate(_historyProvider);
      }
    } on Exception catch (e, st) {
      if (mounted) {
        setState(() => _deleting = false);
        showPoliteErrorSnack(
          context,
          e,
          tag: 'conversation_history.delete',
          stack: st,
        );
      }
    }
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $h:$min';
  }
}
