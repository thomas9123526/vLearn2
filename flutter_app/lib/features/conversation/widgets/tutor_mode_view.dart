import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/polite_error.dart';
import '../../../core/models/models.dart';
import '../../../core/speech/audio_recorder.dart';
import '../../../core/speech/speech_service.dart';
import '../../../core/storage/model_registry.dart';
import 'tutor_avatar.dart';

/// Fullscreen voice-only tutor mode. Flexible layout (no fixed % heights),
/// large avatar, compact latest-speech cards, tap-to-toggle mic dock.
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
  TutorMood _mood = TutorMood.idle;
  String? _idleSuggestion;
  Timer? _idleTimer;
  StreamSubscription<bool>? _ttsSub;
  String? _lastSpokenId;

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
    super.dispose();
  }

  ConversationMessage? _latestForRole(String role) {
    for (var i = widget.messages.length - 1; i >= 0; i--) {
      if (widget.messages[i].role == role) return widget.messages[i];
    }
    return null;
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

  bool get _tutorSpeaking =>
      _mood == TutorMood.speaking &&
      _latestForRole('assistant') != null;

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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final latestTutor = _latestForRole('assistant');
    final latestUser = _latestForRole('user');
    final recording = _mood == TutorMood.listening;

    return ColoredBox(
      color: scheme.surface,
      child: Column(
        children: [
          _TutorTopBar(
            turnCount: widget.turnCount,
            ending: widget.ending,
            onBack: () => context.pop(),
            onSwitchToChat: widget.onSwitchToChat,
            onEnd: widget.onEnd,
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _AvatarStage(
                    persona: widget.persona,
                    mood: _mood,
                  ),
                ),
                _SpeechStrip(
                  personaName: widget.persona.name,
                  latestTutor: latestTutor,
                  latestUser: latestUser,
                  tutorSpeaking: _tutorSpeaking,
                  suggestion: _idleSuggestion,
                  onSendSuggestion: _idleSuggestion == null
                      ? null
                      : () async {
                          final line = _idleSuggestion!;
                          setState(() {
                            _idleSuggestion = null;
                            _mood = TutorMood.idle;
                          });
                          await widget.onSendText(line);
                        },
                ),
              ],
            ),
          ),
          _RecordDock(
            recording: recording,
            mood: _mood,
            onToggle: () async {
              if (recording) {
                await _stopRecording();
              } else {
                await _startRecording();
              }
            },
          ),
        ],
      ),
    );
  }
}

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
    return Material(
      color: scheme.surface,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
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
                tooltip: 'Chat mode (typing)',
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: onSwitchToChat,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: ending ? null : onEnd,
                  child: ending
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.primary,
                          ),
                        )
                      : const Text('End'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Avatar fills whatever vertical space remains — no fixed height %.
class _AvatarStage extends StatelessWidget {
  const _AvatarStage({required this.persona, required this.mood});

  final Persona persona;
  final TutorMood mood;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Reserve room for the name + status pill + spacing below the avatar
        // so the Column never overflows its slot on shorter screens.
        const reservedBelow = 12.0 + 30.0 + 8.0 + 36.0;
        final availableHeight =
            (constraints.maxHeight - reservedBelow).clamp(0.0, double.infinity);
        final side = math.min(constraints.maxWidth, availableHeight);
        final avatarSize = (side * 0.72).clamp(96.0, 280.0);

        final statusLabel = switch (mood) {
          TutorMood.listening => 'Listening…',
          TutorMood.speaking => 'Speaking…',
          TutorMood.encouraging => 'Your turn',
          _ => 'Tap the mic below to speak',
        };

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                scheme.primary.withValues(alpha: 0.06),
                scheme.surface,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TutorAvatar(
                  key: ValueKey(persona.id),
                  persona: persona,
                  mood: mood,
                  size: avatarSize,
                ),
                const SizedBox(height: 12),
                Text(
                  persona.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                _StatusPill(label: statusLabel, mood: mood),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.mood});

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
          Icons.graphic_eq_rounded,
        ),
      _ => (scheme.surfaceContainerHigh, scheme.onSurfaceVariant, Icons.mic_none),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Compact latest lines — bounded height, no scroll, no overflow.
class _SpeechStrip extends StatelessWidget {
  const _SpeechStrip({
    required this.personaName,
    required this.latestTutor,
    required this.latestUser,
    required this.tutorSpeaking,
    required this.suggestion,
    required this.onSendSuggestion,
  });

  final String personaName;
  final ConversationMessage? latestTutor;
  final ConversationMessage? latestUser;
  final bool tutorSpeaking;
  final String? suggestion;
  final Future<void> Function()? onSendSuggestion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (latestTutor != null)
            _SpeechCard(
              label: personaName,
              text: latestTutor!.content,
              isUser: false,
              active: tutorSpeaking,
            ),
          if (latestTutor != null && latestUser != null) const SizedBox(height: 6),
          if (latestUser != null)
            _SpeechCard(
              label: 'You',
              text: latestUser!.content,
              isUser: true,
              active: false,
            ),
          if (suggestion != null) ...[
            if (latestTutor != null || latestUser != null) const SizedBox(height: 6),
            _SuggestionChip(text: suggestion!, onSend: onSendSuggestion!),
          ],
        ],
      ),
    );
  }
}

class _SpeechCard extends StatelessWidget {
  const _SpeechCard({
    required this.label,
    required this.text,
    required this.isUser,
    required this.active,
  });

  final String label;
  final String text;
  final bool isUser;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isUser ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final fg = isUser ? scheme.onPrimaryContainer : scheme.onSurface;
    final border = active
        ? Border.all(color: scheme.primary, width: 2)
        : Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5));

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.88,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            border: border,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: fg.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: fg,
                        height: 1.35,
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

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.text, required this.onSend});

  final String text;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSend,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: scheme.tertiary.withValues(alpha: 0.5),
            ),
          ),
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
                'Use',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.tertiary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Voice-only dock — tap-to-toggle mic control.
class _RecordDock extends StatelessWidget {
  const _RecordDock({
    required this.recording,
    required this.mood,
    required this.onToggle,
  });

  final bool recording;
  final TutorMood mood;
  final Future<void> Function() onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: _MicButton(
            recording: recording,
            enabled: mood != TutorMood.speaking,
            onToggle: onToggle,
          ),
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.recording,
    required this.enabled,
    required this.onToggle,
  });

  final bool recording;
  final bool enabled;
  final Future<void> Function() onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = enabled || recording;

    return Opacity(
      opacity: active ? 1 : 0.45,
      child: GestureDetector(
        onTap: active ? onToggle : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: recording ? 88 : 76,
          height: recording ? 88 : 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: recording ? scheme.error : scheme.primary,
            boxShadow: [
              BoxShadow(
                color: (recording ? scheme.error : scheme.primary)
                    .withValues(alpha: recording ? 0.45 : 0.28),
                blurRadius: recording ? 28 : 16,
                spreadRadius: recording ? 4 : 0,
              ),
            ],
          ),
          child: Icon(
            recording ? Icons.stop_rounded : Icons.mic_rounded,
            size: recording ? 40 : 34,
            color: recording ? scheme.onError : scheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
