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

  /// Number of messages last rendered — used to detect when a new turn
  /// (the user's own bubble or the AI's reply) lands so we can scroll
  /// the chat to the bottom.
  int _lastMessageCount = 0;

  /// Local "currently viewing" mode. Defaults to the session's stored mode
  /// (set at start time) but the user can flip it via the AppBar toggle.
  String? _viewMode;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Scrolls the chat list to the newest message. [jump] skips the
  /// animation (first load); later turns animate so the user's eye
  /// follows the new bubble in. A second pass corrects for the
  /// ListView's lazy extent estimate once the trailing bubbles are
  /// laid out.
  void _scrollToBottom({bool jump = false}) {
    if (!_scroll.hasClients) return;
    final target = _scroll.position.maxScrollExtent;
    if (jump) {
      _scroll.jumpTo(target);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    } else {
      _scroll
          .animateTo(
            target,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          )
          .then((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    }
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
      // The refetch adds the new turn(s); the ref.listen in build()
      // sees the longer message list and scrolls the chat to the bottom.
      ref.invalidate(_sessionProvider(widget.sessionId));
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

    // Whenever the message list grows — the user's own turn or the AI's
    // reply landing after a refetch — scroll the chat to the bottom so
    // the newest bubble is visible. First load jumps, later turns animate.
    ref.listen(_sessionProvider(widget.sessionId), (prev, next) {
      final messages = next.valueOrNull?.messages;
      if (messages == null) return; // still loading / error — ignore
      final count = messages.length;
      if (count > _lastMessageCount) {
        final firstLoad = _lastMessageCount == 0;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToBottom(jump: firstLoad),
        );
      }
      _lastMessageCount = count;
    });

    final scheme = Theme.of(context).colorScheme;
    final bubbleStyle = ref.watch(bubbleStyleProvider);
    final isTutorMode = data.maybeWhen(
      data: (d) => (_viewMode ?? d.session.mode) == 'face' && d.session.status == 'active',
      orElse: () => false,
    );
    final isReadOnly = data.maybeWhen(
      data: (d) => d.session.status != 'active',
      orElse: () => false,
    );

    return Scaffold(
      // Tutor mode is fullscreen — chrome lives inside [TutorModeView].
      // Read-only sessions always render the chat layout: it has the AppBar
      // we need for the status banner, and Tutor mode's mic / send chrome
      // makes no sense for a finished session.
      appBar: isTutorMode
          ? null
          : AppBar(
              title: data.maybeWhen(
                data: (d) => Text(
                  isReadOnly
                      ? 'Past conversation'
                      : 'Turn ${d.session.turnCount}',
                ),
                orElse: () => const Text('Conversation'),
              ),
              actions: [
                if (!isReadOnly)
                  data.maybeWhen(
                    data: (_) => IconButton(
                      tooltip: 'Tutor mode',
                      icon: const Icon(Icons.face_retouching_natural),
                      onPressed: () => setState(() => _viewMode = 'face'),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                if (!isReadOnly)
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
          final readOnly = d.session.status != 'active';
          final mode = _viewMode ?? d.session.mode;
          if (mode == 'face' && !readOnly) {
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
            readOnly: readOnly,
            status: d.session.status,
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
    this.readOnly = false,
    this.status,
  });

  final ScrollController scroll;
  final List<ConversationMessage> messages;
  final BubbleStyle bubbleStyle;
  final bool sending;
  final ColorScheme scheme;
  final TextEditingController input;
  final VoidCallback onSend;

  /// When true, hides the send composer and shows a banner explaining the
  /// session is finished. Used for completed and abandoned sessions opened
  /// from the history screen.
  final bool readOnly;
  final String? status;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (readOnly) _ReadOnlyBanner(status: status, scheme: scheme),
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Text(
                    readOnly
                        ? 'This session has no messages.'
                        : 'Send your first message to get started.',
                  ),
                )
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
        if (!readOnly)
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

class _ReadOnlyBanner extends StatelessWidget {
  const _ReadOnlyBanner({required this.status, required this.scheme});

  final String? status;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final label = status == 'abandoned' ? 'Abandoned' : 'Completed';
    return Container(
      width: double.infinity,
      color: scheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.history, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label · read-only',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
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

