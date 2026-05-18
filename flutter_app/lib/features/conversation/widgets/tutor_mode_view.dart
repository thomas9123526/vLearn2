import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/polite_error.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/speech/audio_recorder.dart';
import '../../../core/speech/speech_service.dart';
import '../../../core/storage/model_registry.dart';
import '../../../core/theme/bubble_style.dart';
import 'chat_bubble.dart';
import 'tutor_avatar.dart';

/// Tutor (face) mode: large **stage** (avatar + status), scrollable **transcript**
/// (tutor / you bubbles + optional suggestion), and a bottom **dock** (mic + type).
class TutorModeView extends ConsumerStatefulWidget {
  const TutorModeView({
    required this.sessionId,
    required this.persona,
    required this.messages,
    required this.onSendText,
    required this.onIdleSuggestion,
    super.key,
  });

  final String sessionId;
  final Persona persona;
  final List<ConversationMessage> messages;

  final Future<void> Function(String text) onSendText;
  final Future<String?> Function() onIdleSuggestion;

  @override
  ConsumerState<TutorModeView> createState() => _TutorModeViewState();
}

class _TutorModeViewState extends ConsumerState<TutorModeView> {
  static const _stageHeightFraction = 0.65;

  TutorMood _mood = TutorMood.idle;
  String? _idleSuggestion;
  Timer? _idleTimer;
  StreamSubscription<bool>? _ttsSub;
  String? _lastSpokenId;
  final _transcriptScroll = ScrollController();
  final _typedInput = TextEditingController();
  bool _typedSending = false;
  bool _showTypeBar = false;

  @override
  void initState() {
    super.initState();
    final tts = ref.read(ttsServiceProvider);
    _ttsSub = tts.isSpeakingStream.listen((bool isSpeaking) {
      if (!mounted) return;
      setState(() => _mood = isSpeaking ? TutorMood.speaking : TutorMood.idle);
    });
    _resetIdleTimer();
  }

  @override
  void didUpdateWidget(covariant TutorModeView old) {
    super.didUpdateWidget(old);
    _maybeSpeakLatestAssistantReply();
    _resetIdleTimer();
    if (widget.messages.length != old.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTranscriptToEnd());
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _ttsSub?.cancel();
    _typedInput.dispose();
    _transcriptScroll.dispose();
    super.dispose();
  }

  void _scrollTranscriptToEnd() {
    if (!_transcriptScroll.hasClients) return;
    _transcriptScroll.animateTo(
      _transcriptScroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendTyped() async {
    final text = _typedInput.text.trim();
    if (text.isEmpty || _typedSending) return;
    setState(() => _typedSending = true);
    try {
      await widget.onSendText(text);
      _typedInput.clear();
    } finally {
      if (mounted) setState(() => _typedSending = false);
    }
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleSuggestion = null;
    if (widget.messages.isEmpty) return;
    if (widget.messages.last.role != 'assistant') return;
    _idleTimer = Timer(const Duration(seconds: 20), _fetchIdleSuggestion);
  }

  Future<void> _fetchIdleSuggestion() async {
    if (!mounted) return;
    setState(() => _mood = TutorMood.encouraging);
    final s = await widget.onIdleSuggestion();
    if (!mounted) return;
    setState(() => _idleSuggestion = s);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTranscriptToEnd());
  }

  void _maybeSpeakLatestAssistantReply() {
    if (widget.messages.isEmpty) return;
    final last = widget.messages.last;
    if (last.role != 'assistant') return;
    if (last.id == _lastSpokenId) return;
    _lastSpokenId = last.id;

    if (!ref.read(speechReadyProvider)) return;
    final tts = ref.read(ttsServiceProvider);
    final voiceId = widget.persona.voiceId ??
        (tts.capabilities.availableVoices.isNotEmpty
            ? tts.capabilities.availableVoices.first
            : '');
    tts.speak(last.content, voiceId: voiceId).catchError((Object e, StackTrace st) {
      logRawError('tutor_mode.tts', e, st);
    });
  }

  String? get _highlightedAssistantId {
    if (_mood != TutorMood.speaking) return null;
    for (var i = widget.messages.length - 1; i >= 0; i--) {
      if (widget.messages[i].role == 'assistant') return widget.messages[i].id;
    }
    return null;
  }

  Future<void> _startRecording() async {
    final recorder = ref.read(audioRecorderProvider);
    final granted = await recorder.requestPermission();
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mic access is needed for Tutor mode. Enable it in Settings.',
          ),
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
    setState(() => _mood = TutorMood.listening);
    await ref.read(ttsServiceProvider).stop();
  }

  Future<void> _stopRecording() async {
    final recorder = ref.read(audioRecorderProvider);
    final capture = await recorder.stop();
    if (!mounted) return;
    setState(() => _mood = TutorMood.idle);
    if (capture == null) return;

    if (!ref.read(speechReadyProvider)) {
      final snap = ref.read(modelRegistrySnapshotProvider).valueOrNull;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(speechModelsStatusMessage(snap)),
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }
    final stt = ref.read(sttServiceProvider);
    try {
      final result = await stt.transcribe(capture.pcm, language: 'en');
      final text = result.text.trim();
      if (text.isEmpty) return;
      await widget.onSendText(text);
    } catch (e, st) {
      logRawError('tutor_mode.stt', e, st);
      if (mounted) {
        showPoliteErrorSnack(context, e, tag: 'tutor_mode.stt', stack: st);
      }
    }
  }

  Future<void> _cancelRecording() async {
    await ref.read(audioRecorderProvider).cancel();
    if (!mounted) return;
    setState(() => _mood = TutorMood.idle);
  }

  String _stageStatusLabel() => switch (_mood) {
        TutorMood.listening => 'Listening…',
        TutorMood.speaking => 'Speaking…',
        TutorMood.encouraging => 'Take your turn',
        TutorMood.praising => 'Nice work!',
        TutorMood.disappointed => 'Let\'s try again',
        TutorMood.idle => widget.messages.isEmpty
            ? 'Tap and hold the mic to talk'
            : 'Hold mic to reply',
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bubbleStyle = ref.watch(bubbleStyleProvider);
    final suggestion = _idleSuggestion;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return ColoredBox(
      color: scheme.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stageHeight = (constraints.maxHeight * _stageHeightFraction)
              .clamp(220.0, constraints.maxHeight - 140);

          return Column(
            children: [
              SizedBox(
                height: stageHeight,
                width: double.infinity,
                child: _TutorStage(
                  persona: widget.persona,
                  mood: _mood,
                  statusLabel: _stageStatusLabel(),
                  stageHeight: stageHeight,
                ),
              ),
              Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
              Expanded(
                child: _TutorTranscript(
                  scrollController: _transcriptScroll,
                  messages: widget.messages,
                  personaName: widget.persona.name,
                  bubbleStyle: bubbleStyle,
                  highlightedAssistantId: _highlightedAssistantId,
                  suggestion: suggestion,
                  onSendSuggestion: suggestion == null
                      ? null
                      : () async {
                          setState(() {
                            _idleSuggestion = null;
                            _mood = TutorMood.idle;
                          });
                          await widget.onSendText(suggestion);
                        },
                ),
              ),
              _TutorDock(
                showTypeBar: _showTypeBar || keyboardOpen,
                typedInput: _typedInput,
                typedSending: _typedSending,
                recording: _mood == TutorMood.listening,
                onToggleType: () => setState(() => _showTypeBar = !_showTypeBar),
                onSendTyped: _sendTyped,
                onPressStart: _startRecording,
                onPressEnd: _stopRecording,
                onCancel: _cancelRecording,
                hideMic: keyboardOpen,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Top ~65% — large avatar, persona name, live status (no duplicate caption).
class _TutorStage extends StatelessWidget {
  const _TutorStage({
    required this.persona,
    required this.mood,
    required this.statusLabel,
    required this.stageHeight,
  });

  final Persona persona;
  final TutorMood mood;
  final String statusLabel;
  final double stageHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avatarSize = (stageHeight * 0.52).clamp(160.0, 300.0);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.35),
            scheme.surface,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TutorAvatar(persona: persona, mood: mood, size: avatarSize),
            const SizedBox(height: 12),
            Text(
              persona.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            _StatusChip(label: statusLabel, mood: mood),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.mood});

  final String label;
  final TutorMood mood;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg, IconData icon) = switch (mood) {
      TutorMood.listening => (scheme.errorContainer, scheme.onErrorContainer, Icons.mic),
      TutorMood.speaking => (scheme.primaryContainer, scheme.onPrimaryContainer, Icons.volume_up_rounded),
      _ => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant, Icons.record_voice_over_outlined),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg)),
        ],
      ),
    );
  }
}

/// Scrollable tutor / you bubbles plus optional suggestion card.
class _TutorTranscript extends StatelessWidget {
  const _TutorTranscript({
    required this.scrollController,
    required this.messages,
    required this.personaName,
    required this.bubbleStyle,
    required this.highlightedAssistantId,
    required this.suggestion,
    required this.onSendSuggestion,
  });

  final ScrollController scrollController;
  final List<ConversationMessage> messages;
  final String personaName;
  final BubbleStyle bubbleStyle;
  final String? highlightedAssistantId;
  final String? suggestion;
  final Future<void> Function()? onSendSuggestion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final itemCount = messages.length + (suggestion != null ? 1 : 0);

    if (itemCount == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Your conversation will appear here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < messages.length) {
          final msg = messages[index];
          final isUser = msg.role == 'user';
          final highlighted =
              !isUser && msg.id == highlightedAssistantId;
          return _TranscriptTurn(
            label: isUser ? 'You' : personaName,
            icon: isUser ? Icons.mic_none_outlined : Icons.smart_toy_outlined,
            alignEnd: isUser,
            highlighted: highlighted,
            child: ChatBubble(message: msg, style: bubbleStyle),
          );
        }
        return _SuggestedReplyCard(
          text: suggestion!,
          onSend: onSendSuggestion!,
        );
      },
    );
  }
}

class _TranscriptTurn extends StatelessWidget {
  const _TranscriptTurn({
    required this.label,
    required this.icon,
    required this.alignEnd,
    required this.highlighted,
    required this.child,
  });

  final String label;
  final IconData icon;
  final bool alignEnd;
  final bool highlighted;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (highlighted) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.graphic_eq, size: 14, color: scheme.primary),
                ],
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: highlighted
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: scheme.primary, width: 2),
                  )
                : null,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _SuggestedReplyCard extends StatelessWidget {
  const _SuggestedReplyCard({required this.text, required this.onSend});

  final String text;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: scheme.outline,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onSend,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 16, color: scheme.tertiary),
                    const SizedBox(width: 6),
                    Text(
                      'Suggested reply',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.tertiary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      'Tap to send',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  text,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorDock extends StatelessWidget {
  const _TutorDock({
    required this.showTypeBar,
    required this.typedInput,
    required this.typedSending,
    required this.recording,
    required this.onToggleType,
    required this.onSendTyped,
    required this.onPressStart,
    required this.onPressEnd,
    required this.onCancel,
    required this.hideMic,
  });

  final bool showTypeBar;
  final TextEditingController typedInput;
  final bool typedSending;
  final bool recording;
  final VoidCallback onToggleType;
  final Future<void> Function() onSendTyped;
  final Future<void> Function() onPressStart;
  final Future<void> Function() onPressEnd;
  final Future<void> Function() onCancel;
  final bool hideMic;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 8,
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showTypeBar)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: typedInput,
                        minLines: 1,
                        maxLines: 3,
                        enabled: !typedSending,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => onSendTyped(),
                        decoration: const InputDecoration(
                          hintText: 'Type your reply…',
                          isDense: true,
                          filled: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: typedSending ? null : onSendTyped,
                      icon: typedSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              if (showTypeBar) const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!hideMic) ...[
                    _MicButton(
                      recording: recording,
                      onPressStart: onPressStart,
                      onPressEnd: onPressEnd,
                      onCancel: onCancel,
                    ),
                    const SizedBox(width: 16),
                  ],
                  TextButton.icon(
                    onPressed: onToggleType,
                    icon: Icon(showTypeBar ? Icons.mic : Icons.keyboard_outlined),
                    label: Text(showTypeBar ? 'Use mic' : 'Type instead'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.recording,
    required this.onPressStart,
    required this.onPressEnd,
    required this.onCancel,
  });

  final bool recording;
  final Future<void> Function() onPressStart;
  final Future<void> Function() onPressEnd;
  final Future<void> Function() onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onLongPressStart: (_) => onPressStart(),
      onLongPressEnd: (_) => onPressEnd(),
      onLongPressCancel: onCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: recording ? 76 : 64,
        height: recording ? 76 : 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: recording ? scheme.errorContainer : scheme.primaryContainer,
          boxShadow: [
            if (recording)
              BoxShadow(
                color: scheme.error.withValues(alpha: 0.45),
                blurRadius: 20,
                spreadRadius: 4,
              ),
          ],
        ),
        child: Icon(
          recording ? Icons.stop : Icons.mic,
          size: recording ? 32 : 28,
          color: recording ? scheme.onErrorContainer : scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
