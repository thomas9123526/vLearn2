import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/app_apis.dart';
import '../../core/config/layout_config_provider.dart';
import '../../core/errors/polite_error.dart';
import '../../core/guard/content_guard.dart';
import '../../core/models/models.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/personas_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/speech/audio_recorder.dart';
import '../../core/speech/speech_service.dart';
import '../../core/storage/model_registry.dart';
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
    // 'tutor' | 'message' | 'both' — controls which modes are available.
    final conversationMode =
        ref.watch(layoutConfigProvider).valueOrNull?.get<String>('conversation.mode') ?? 'both';

    // Resolve the effective view mode:
    //   tutor   → always face
    //   message → always chat
    //   both    → user's local toggle or the session's stored default
    String effectiveMode(_SessionData d) {
      if (conversationMode == 'tutor') return 'face';
      if (conversationMode == 'message') return 'chat';
      return _viewMode ?? d.session.mode;
    }

    final isTutorMode = data.maybeWhen(
      data: (d) => effectiveMode(d) == 'face' && d.session.status == 'active',
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
                // Toggle to tutor mode — only shown when both modes are enabled.
                if (!isReadOnly && conversationMode == 'both')
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
          final mode = effectiveMode(d);
          if (mode == 'face' && !readOnly) {
            return _TutorModeWrapper(
              sessionId: widget.sessionId,
              personaId: d.session.personaId,
              messages: d.messages,
              turnCount: d.session.turnCount,
              onSendText: _send,
              onIdleSuggestion: _fetchSuggestion,
              // Hide the switch-to-chat button when locked to tutor-only mode.
              onSwitchToChat: conversationMode == 'both'
                  ? () => setState(() => _viewMode = 'chat')
                  : null,
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
            onSendVoiceText: _send,
            readOnly: readOnly,
            status: d.session.status,
          );
        },
      ),
    );
  }
}

/// Splits chat mode into its own widget so the build method stays
/// readable. Same chat-bubble list + send box as before, now with an
/// optional mic button for voice input.
class _ChatModeBody extends ConsumerStatefulWidget {
  const _ChatModeBody({
    required this.scroll,
    required this.messages,
    required this.bubbleStyle,
    required this.sending,
    required this.scheme,
    required this.input,
    required this.onSend,
    required this.onSendVoiceText,
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

  /// Called with the transcribed text when voice input completes and
  /// passes the content guard. Bypasses the text field.
  final Future<void> Function(String) onSendVoiceText;

  /// When true, hides the send composer and shows a banner explaining the
  /// session is finished. Used for completed and abandoned sessions opened
  /// from the history screen.
  final bool readOnly;
  final String? status;

  @override
  ConsumerState<_ChatModeBody> createState() => _ChatModeBodyState();
}

class _ChatModeBodyState extends ConsumerState<_ChatModeBody> {
  bool _recording = false;
  bool _transcribing = false;

  Future<void> _startRecording() async {
    final recorder = ref.read(audioRecorderProvider);
    final granted = await recorder.requestPermission();
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mic access is needed for voice input. Enable it in Settings.'),
        ),
      );
      return;
    }
    final started = await recorder.start();
    if (!started) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the microphone.')),
      );
      return;
    }
    setState(() => _recording = true);
  }

  Future<void> _stopRecording() async {
    setState(() => _recording = false);
    final recorder = ref.read(audioRecorderProvider);
    final capture = await recorder.stop();
    if (!mounted || capture == null) return;

    if (!ref.read(speechReadyProvider)) {
      final snap = ref.read(modelRegistrySnapshotProvider).valueOrNull;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(speechModelsStatusMessage(snap)),
            duration: const Duration(seconds: 6),
          ),
        );
      }
      return;
    }

    setState(() => _transcribing = true);
    try {
      final stt = ref.read(sttServiceProvider);
      final result = await stt.transcribe(capture.pcm, language: 'en');
      final text = result.text.trim();
      if (text.isEmpty || !mounted) return;

      final guard = ref.read(contentGuardProvider);
      final guardResult = guard.check(text);

      if (guardResult.severity == GuardSeverity.block) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Inappropriate content'),
            content: Text(
              'Your message contains words that cannot be sent:\n'
              '${guardResult.matchedTerms.join(', ')}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      if (guardResult.severity == GuardSeverity.warn) {
        if (!mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Language warning'),
            content: Text(
              'Your message may contain inappropriate language '
              '(${guardResult.matchedTerms.join(', ')}).\n\nSend it anyway?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Send'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      }

      await widget.onSendVoiceText(text);
    } catch (e, st) {
      if (mounted) {
        showPoliteErrorSnack(context, e, tag: 'chat_mode.stt', stack: st);
      }
    } finally {
      if (mounted) setState(() => _transcribing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final busy = widget.sending || _transcribing;
    return Column(
      children: [
        if (widget.readOnly) _ReadOnlyBanner(status: widget.status, scheme: scheme),
        Expanded(
          child: widget.messages.isEmpty
              ? Center(
                  child: Text(
                    widget.readOnly
                        ? 'This session has no messages.'
                        : 'Send your first message to get started.',
                  ),
                )
              : ListView.builder(
                  controller: widget.scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.messages.length,
                  itemBuilder: (_, i) => ChatBubble(
                    message: widget.messages[i],
                    style: widget.bubbleStyle,
                  ),
                ),
        ),
        if (!widget.readOnly)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _recording
                        ? _VoiceWaveform(
                            amplitudeStream:
                                ref.read(audioRecorderProvider).amplitudeStream,
                          )
                        : TextField(
                            controller: widget.input,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => widget.onSend(),
                            decoration: const InputDecoration(
                                hintText: 'Type your message…'),
                          ),
                  ),
                  const SizedBox(width: 8),
                  _ChatMicButton(
                    recording: _recording,
                    disabled: busy,
                    onToggle: _recording ? _stopRecording : _startRecording,
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: (busy || _recording) ? null : widget.onSend,
                    icon: (widget.sending || _transcribing)
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

class _ChatMicButton extends StatelessWidget {
  const _ChatMicButton({
    required this.recording,
    required this.disabled,
    required this.onToggle,
  });

  final bool recording;
  final bool disabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton.filled(
      onPressed: disabled ? null : onToggle,
      style: IconButton.styleFrom(
        backgroundColor: recording ? scheme.error : scheme.secondaryContainer,
        foregroundColor: recording ? scheme.onError : scheme.onSecondaryContainer,
      ),
      icon: Icon(recording ? Icons.stop_rounded : Icons.mic_rounded),
    );
  }
}

/// Animated bar visualiser that reacts to microphone amplitude (0.0–1.0).
/// Shown in place of the text field while the user is recording.
class _VoiceWaveform extends StatefulWidget {
  const _VoiceWaveform({required this.amplitudeStream});
  final Stream<double> amplitudeStream;

  @override
  State<_VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<_VoiceWaveform> {
  double _amplitude = 0.0;
  StreamSubscription<double>? _sub;

  // Per-bar multipliers so the bars reach different heights at the same
  // amplitude level, giving a natural multi-band equaliser appearance.
  static const _multipliers = [0.60, 0.90, 1.00, 0.85, 0.65];

  @override
  void initState() {
    super.initState();
    _sub = widget.amplitudeStream.listen((amp) {
      if (mounted) setState(() => _amplitude = amp);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_multipliers.length, (i) {
          final height = 6.0 + _amplitude * _multipliers[i] * 36.0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              curve: Curves.easeOut,
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
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
    this.onSwitchToChat,
    required this.onEnd,
    required this.ending,
  });

  final String sessionId;
  final String personaId;
  final List<ConversationMessage> messages;
  final int turnCount;
  final Future<void> Function(String text) onSendText;
  final Future<String?> Function() onIdleSuggestion;
  final VoidCallback? onSwitchToChat;
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

