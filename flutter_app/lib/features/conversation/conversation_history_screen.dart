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
final _historyProvider =
    FutureProvider<List<ConversationSession>>((ref) async {
  final raw =
      await ref.read(conversationsApiProvider).listSessions(limit: 100);
  return raw.map(ConversationSession.fromJson).toList();
});

class ConversationHistoryScreen extends ConsumerWidget {
  const ConversationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(_historyProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Conversation history'),
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          logRawError('conversation_history.load', e, st);
          return PoliteErrorCenter(
            error: e,
            context: ErrorContext.loadList,
            onRetry: () => ref.invalidate(_historyProvider),
          );
        },
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final personaAsync =
        ref.watch(personaByIdProvider(widget.session.personaId));

    final (statusLabel, statusColor) = switch (widget.session.status) {
      'active' => ('Active', scheme.primary),
      'completed' => ('Completed', Colors.green.shade700),
      _ => ('Abandoned', scheme.outline),
    };

    final personaName = personaAsync.maybeWhen(
      data: (p) => p?.name ?? 'Tutor',
      orElse: () => 'Tutor',
    );

    return ListTile(
      onTap: _deleting
          ? null
          : () => context.push(AppRoute.conversation(widget.session.id)),
      title: Text(
        '$personaName · ${widget.session.mode == 'face' ? 'Tutor mode' : 'Chat'}',
      ),
      subtitle: Text(
        '${_formatDate(widget.session.startedAt)} · ${widget.session.turnCount} turns · ${widget.session.xpEarned} XP',
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: const Text(
          'The transcript and any score will be permanently removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref
          .read(conversationsApiProvider)
          .deleteSession(widget.session.id);
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
