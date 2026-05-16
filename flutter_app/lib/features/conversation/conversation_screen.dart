import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/app_apis.dart';
import '../../core/models/models.dart';
import '../../core/router/app_router.dart';

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
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Send failed: $e')));
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
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('End failed: $e')));
        setState(() => _ending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(_sessionProvider(widget.sessionId));
    final scheme = Theme.of(context).colorScheme;

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
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (d) => Column(
          children: [
            Expanded(
              child: d.messages.isEmpty
                  ? const Center(child: Text('Send your first message to get started.'))
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(16),
                      itemCount: d.messages.length,
                      itemBuilder: (_, i) => _Bubble(message: d.messages[i]),
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

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final ConversationMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.role == 'user';
    final color = isUser ? scheme.primary : scheme.surfaceContainerHighest;
    final textColor = isUser ? Colors.white : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(message.content, style: TextStyle(color: textColor, fontSize: 15, height: 1.4)),
            ),
          ),
        ],
      ),
    );
  }
}
