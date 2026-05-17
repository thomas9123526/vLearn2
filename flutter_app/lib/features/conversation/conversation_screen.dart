import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/app_apis.dart';
import '../../core/errors/polite_error.dart';
import '../../core/models/models.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/router/app_router.dart';
import 'widgets/chat_bubble.dart';

class _SessionData {
  const _SessionData({required this.session, required this.messages});
  final ConversationSession session;
  final List<ConversationMessage> messages;
}

final _sessionProvider = FutureProvider.family<_SessionData, String>((ref, id) async {
  final raw = await ref.read(conversationsApiProvider).getSession(id);
  return _SessionData(
    session: ConversationSession.fromJson(raw),
    messages: (raw['messages'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(ConversationMessage.fromJson)
        .toList(),
  );
});

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  bool _ending = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(conversationsApiProvider).sendMessage(widget.sessionId, text);
      _input.clear();
      ref.invalidate(_sessionProvider(widget.sessionId));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } on Exception catch (e, st) {
      if (mounted) {
        showPoliteErrorSnack(
          context,
          e,
          tag: 'conversation_screen.send',
          errorContext: ErrorContext.send,
          stack: st,
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _end() async {
    if (_ending) return;
    setState(() => _ending = true);
    try {
      await ref.read(conversationsApiProvider).endSession(widget.sessionId);
      if (mounted) {
        context.pushReplacement(AppRoute.report(widget.sessionId));
      }
    } on Exception catch (e, st) {
      if (mounted) {
        showPoliteErrorSnack(
          context,
          e,
          tag: 'conversation_screen.end',
          stack: st,
        );
        setState(() => _ending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(_sessionProvider(widget.sessionId));
    final scheme = Theme.of(context).colorScheme;
    final bubbleStyle = ref.watch(bubbleStyleProvider);

    return Scaffold(
      appBar: AppBar(
        title: data.maybeWhen(
          data: (d) => Text('Turn ${d.session.turnCount}'),
          orElse: () => const Text('Conversation'),
        ),
        actions: [
          TextButton.icon(
            onPressed: _ending ? null : _end,
            icon: const Icon(Icons.flag_outlined),
            label: const Text('End'),
          ),
        ],
      ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          logRawError('conversation_screen.load', e, st);
          return PoliteErrorCenter(
            error: e,
            context: ErrorContext.loadDetail,
            onRetry: () => ref.invalidate(_sessionProvider(widget.sessionId)),
          );
        },
        data: (d) => Column(
          children: [
            Expanded(
              child: d.messages.isEmpty
                  ? const Center(child: Text('Send your first message to get started.'))
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(16),
                      itemCount: d.messages.length,
                      itemBuilder: (_, i) => ChatBubble(
                        message: d.messages[i],
                        style: bubbleStyle,
                      ),
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(hintText: 'Type your message…'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

