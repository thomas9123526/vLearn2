import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/app_apis.dart';
import '../../core/errors/polite_error.dart';
import '../../core/models/models.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/personas_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/bubble_style.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/tutor_mode_view.dart';

/// Materialised view of one session: the session row + every message we
/// have for it, in ascending sequence order.
class _SessionData {
  const _SessionData({required this.session, required this.messages});
  final ConversationSession session;
  final List<ConversationMessage> messages;
}

/// Fetcher used by both Chat and Tutor modes. Family-keyed by session id so
/// multiple sessions in the back stack each get their own state.
final _sessionProvider =
    FutureProvider.family<_SessionData, String>((ref, id) async {
  final raw = await ref.read(conversationsApiProvider).getSession(id);
  return _SessionData(
    session: ConversationSession.fromJson(raw),
    messages: (raw['messages'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(ConversationMessage.fromJson)
        .toList(),
  );
});

/// Looks up the active persona for the session so Tutor mode can render
/// the right gradient / Rive asset / voice.
// personaByIdProvider lives in core/providers/personas_provider.dart

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

  /// Local "currently viewing" mode. Defaults to the session's stored mode
  /// (set at start time) but the user can flip it via the AppBar toggle.
  String? _viewMode;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Submit a text turn to the backend and refresh the local view.
  /// Used both by the chat-mode text input and by tutor-mode (after STT).
  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(conversationsApiProvider).sendMessage(widget.sessionId, trimmed);
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

  Future<String?> _fetchSuggestion() async {
    return ref.read(conversationsApiProvider).suggestNextLine(widget.sessionId);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(_sessionProvider(widget.sessionId));
    final scheme = Theme.of(context).colorScheme;
    final bubbleStyle = ref.watch(bubbleStyleProvider);
    final isTutorMode = data.maybeWhen(
      data: (d) => (_viewMode ?? d.session.mode) == 'face',
      orElse: () => false,
    );

    return Scaffold(
      // Tutor mode is fullscreen — chrome lives inside [TutorModeView].
      appBar: isTutorMode
          ? null
          : AppBar(
              title: data.maybeWhen(
                data: (d) => Text('Turn ${d.session.turnCount}'),
                orElse: () => const Text('Conversation'),
              ),
              actions: [
                data.maybeWhen(
                  data: (_) => IconButton(
                    tooltip: 'Tutor mode',
                    icon: const Icon(Icons.face_retouching_natural),
                    onPressed: () => setState(() => _viewMode = 'face'),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
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
        data: (d) {
          final mode = _viewMode ?? d.session.mode;
          if (mode == 'face') {
            return _TutorModeWrapper(
              sessionId: widget.sessionId,
              personaId: d.session.personaId,
              messages: d.messages,
              turnCount: d.session.turnCount,
              onSendText: _send,
              onIdleSuggestion: _fetchSuggestion,
              onSwitchToChat: () => setState(() => _viewMode = 'chat'),
              onEnd: _end,
              ending: _ending,
            );
          }
          return _ChatModeBody(
            scroll: _scroll,
            messages: d.messages,
            bubbleStyle: bubbleStyle,
            sending: _sending,
            scheme: scheme,
            input: _input,
            onSend: () => _send(_input.text),
          );
        },
      ),
    );
  }
}

/// Splits chat mode into its own widget so the build method stays
/// readable. Same chat-bubble list + send box as before.
class _ChatModeBody extends StatelessWidget {
  const _ChatModeBody({
    required this.scroll,
    required this.messages,
    required this.bubbleStyle,
    required this.sending,
    required this.scheme,
    required this.input,
    required this.onSend,
  });

  final ScrollController scroll;
  final List<ConversationMessage> messages;
  final BubbleStyle bubbleStyle;
  final bool sending;
  final ColorScheme scheme;
  final TextEditingController input;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? const Center(child: Text('Send your first message to get started.'))
              : ListView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) => ChatBubble(
                    message: messages[i],
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
                    controller: input,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: const InputDecoration(hintText: 'Type your message…'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: sending ? null : onSend,
                  icon: sending
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
    );
  }
}

/// Hydrates the active persona for the session, then renders [TutorModeView].
/// Done in its own widget so the persona FutureProvider stays scoped and
/// chat mode doesn't pay the lookup cost.
class _TutorModeWrapper extends ConsumerWidget {
  const _TutorModeWrapper({
    required this.sessionId,
    required this.personaId,
    required this.messages,
    required this.turnCount,
    required this.onSendText,
    required this.onIdleSuggestion,
    required this.onSwitchToChat,
    required this.onEnd,
    required this.ending,
  });

  final String sessionId;
  final String personaId;
  final List<ConversationMessage> messages;
  final int turnCount;
  final Future<void> Function(String text) onSendText;
  final Future<String?> Function() onIdleSuggestion;
  final VoidCallback onSwitchToChat;
  final VoidCallback onEnd;
  final bool ending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayPersonaId =
        ref.watch(tutorDisplayPersonaIdProvider(personaId));
    final persona = ref.watch(personaByIdProvider(displayPersonaId));
    return persona.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) {
        logRawError('conversation_screen.persona', e, st);
        return Center(
          child: Text(politeMessageFor(e, context: ErrorContext.loadDetail)),
        );
      },
      data: (p) {
        if (p == null) {
          return const Center(child: Text('No tutor assigned to this session.'));
        }
        return TutorModeView(
          sessionId: sessionId,
          persona: p,
          messages: messages,
          turnCount: turnCount,
          onSendText: onSendText,
          onIdleSuggestion: onIdleSuggestion,
          onSwitchToChat: onSwitchToChat,
          onEnd: onEnd,
          ending: ending,
        );
      },
    );
  }
}

