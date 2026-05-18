import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/polite_error.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/speech/audio_recorder.dart';
import '../../../core/speech/speech_service.dart';
import '../../../core/storage/model_registry.dart';
import '../../../core/theme/bubble_style.dart';
import 'chat_bubble.dart';
import 'tutor_avatar.dart';

/// Fullscreen tutor mode: large stage, **one** latest tutor bubble + **one**
/// latest user bubble (no scroll history), dock for mic / type.
class TutorModeView extends ConsumerStatefulWidget {
  const TutorModeView({
    required this.sessionId,
    required this.persona,
    required this.messages,
    required this.turnCount,
    required this.onSendText,
    required this.onIdleSuggestion,
    required this.onSwitchToChat,
    required this.onEnd,
    required this.ending,
    super.key,
  });

  final String sessionId;
  final Persona persona;
  final List<ConversationMessage> messages;
  final int turnCount;
  final Future<void> Function(String text) onSendText;
  final Future<String?> Function() onIdleSuggestion;
  final VoidCallback onSwitchToChat;
  final VoidCallback onEnd;
  final bool ending;

  @override
  ConsumerState<TutorModeView> createState() => _TutorModeViewState();
}

class _TutorModeViewState extends ConsumerState<TutorModeView> {
  /// Stage uses most of the screen; bubbles + dock sit below.
  static const _stageHeightFraction = 0.62;

  TutorMood _mood = TutorMood.idle;
  String? _idleSuggestion;
  Timer? _idleTimer;
  StreamSubscription<bool>? _ttsSub;
  String? _lastSpokenId;
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
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _ttsSub?.cancel();
    _typedInput.dispose();
    super.dispose();
  }

  ConversationMessage? _latestForRole(String role) {
    for (var i = widget.messages.length - 1; i >= 0; i--) {
      if (widget.messages[i].role == role) return widget.messages[i];
    }
    return null;
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
    return _latestForRole('assistant')?.id;
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
    final latestTutor = _latestForRole('assistant');
    final latestUser = _latestForRole('user');

    return ColoredBox(
      color: scheme.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stageHeight = (constraints.maxHeight * _stageHeightFraction)
              .clamp(240.0, constraints.maxHeight - 120);

          return Column(
            children: [
              SizedBox(
                height: stageHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _TutorStage(
                      persona: widget.persona,
                      mood: _mood,
                      statusLabel: _stageStatusLabel(),
                      stageHeight: stageHeight,
                    ),
                    _TutorTopBar(
                      turnCount: widget.turnCount,
                      ending: widget.ending,
                      onBack: () => context.pop(),
                      onSwitchToChat: widget.onSwitchToChat,
                      onEnd: widget.onEnd,
                    ),
                  ],
                ),
              ),
              _LatestBubblesPane(
                latestTutor: latestTutor,
                latestUser: latestUser,
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

/// Floating chrome over the stage (fullscreen — no scaffold app bar).
class _TutorTopBar extends StatelessWidget {
  const _TutorTopBar({
    required this.turnCount,
    required this.ending,
    required this.onBack,
    required this.onSwitchToChat,
    required this.onEnd,
  });

  final int turnCount;
  final bool ending;
  final VoidCallback onBack;
  final VoidCallback onSwitchToChat;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              color: scheme.onSurface,
              onPressed: onBack,
            ),
            Expanded(
              child: Text(
                'Turn $turnCount',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            IconButton(
              tooltip: 'Chat mode',
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: onSwitchToChat,
            ),
            TextButton.icon(
              onPressed: ending ? null : onEnd,
              icon: ending
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    )
                  : const Icon(Icons.flag_outlined, size: 18),
              label: const Text('End'),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final topInset = MediaQuery.paddingOf(context).top + 48;
    final avatarSize =
        (stageHeight - topInset - 72).clamp(180.0, 340.0);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.4),
            scheme.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: topInset),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TutorAvatar(persona: persona, mood: mood, size: avatarSize),
                const SizedBox(height: 10),
                Text(
                  persona.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                _StatusChip(label: statusLabel, mood: mood),
              ],
            ),
          ),
        ],
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
      TutorMood.listening =>
        (scheme.errorContainer, scheme.onErrorContainer, Icons.mic),
      TutorMood.speaking => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
          Icons.volume_up_rounded
        ),
      _ => (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
          Icons.record_voice_over_outlined
        ),
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
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

/// At most one tutor line + one user line — current turn only, no scrolling.
class _LatestBubblesPane extends StatelessWidget {
  const _LatestBubblesPane({
    required this.latestTutor,
    required this.latestUser,
    required this.personaName,
    required this.bubbleStyle,
    required this.highlightedAssistantId,
    required this.suggestion,
    required this.onSendSuggestion,
  });

  final ConversationMessage? latestTutor;
  final ConversationMessage? latestUser;
  final String personaName;
  final BubbleStyle bubbleStyle;
  final String? highlightedAssistantId;
  final String? suggestion;
  final Future<void> Function()? onSendSuggestion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasBubbles = latestTutor != null || latestUser != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!hasBubbles && suggestion == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Your latest lines appear here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          if (latestTutor != null)
            _TranscriptTurn(
              label: personaName,
              icon: Icons.smart_toy_outlined,
              alignEnd: false,
              highlighted: latestTutor!.id == highlightedAssistantId,
              child: ChatBubble(message: latestTutor!, style: bubbleStyle),
            ),
          if (latestUser != null)
            _TranscriptTurn(
              label: 'You',
              icon: Icons.mic_none_outlined,
              alignEnd: true,
              highlighted: false,
              child: ChatBubble(message: latestUser!, style: bubbleStyle),
            ),
          if (suggestion != null)
            _SuggestedReplyCard(
              text: suggestion!,
              onSend: onSendSuggestion!,
            ),
        ],
      ),
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 2),
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
            child: ClipRect(
              child: Align(
                alignment: alignEnd
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                heightFactor: 1,
                child: child,
              ),
            ),
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
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onSend,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 16, color: scheme.tertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Text(
                  'Send',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
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
      elevation: 6,
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
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
                        maxLines: 2,
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
              if (showTypeBar) const SizedBox(height: 6),
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
                    const SizedBox(width: 12),
                  ],
                  TextButton.icon(
                    onPressed: onToggleType,
                    icon: Icon(
                      showTypeBar ? Icons.mic : Icons.keyboard_outlined,
                    ),
                    label: Text(showTypeBar ? 'Mic' : 'Type'),
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
        width: recording ? 72 : 60,
        height: recording ? 72 : 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: recording ? scheme.errorContainer : scheme.primaryContainer,
          boxShadow: [
            if (recording)
              BoxShadow(
                color: scheme.error.withValues(alpha: 0.45),
                blurRadius: 18,
                spreadRadius: 3,
              ),
          ],
        ),
        child: Icon(
          recording ? Icons.stop : Icons.mic,
          size: recording ? 30 : 26,
          color:
              recording ? scheme.onErrorContainer : scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
