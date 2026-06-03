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
    this.onSwitchToChat,
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
  final VoidCallback? onSwitchToChat;
  final VoidCallback onEnd;
  final bool ending;

  @override
  ConsumerState<TutorModeView> createState() => _TutorModeViewState();
}

class _TutorModeViewState extends ConsumerState<TutorModeView> {
  TutorMood _mood = TutorMood.idle;
  double _amplitude = 0.0;
  String? _idleSuggestion;
  Timer? _idleTimer;
  Timer? _disappointedTimer;
  StreamSubscription<bool>? _ttsSub;
  StreamSubscription<double>? _ampSub;
  String? _lastSpokenId;

  @override
  void initState() {
    super.initState();
    final tts = ref.read(ttsServiceProvider);
    // Snapshot current state — broadcast stream only emits on changes, so a
    // widget mounted mid-TTS would never receive the "started" event.
    if (tts.isSpeaking) _mood = TutorMood.speaking;
    _ttsSub = tts.isSpeakingStream.listen((bool isSpeaking) {
      if (!mounted) return;
      setState(() {
        _mood = isSpeaking ? TutorMood.speaking : TutorMood.idle;
        if (!isSpeaking) _amplitude = 0.0;
      });
    });
    _ampSub = tts.amplitudeStream.listen((double amp) {
      if (!mounted) return;
      setState(() => _amplitude = amp);
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
    _disappointedTimer?.cancel();
    _ttsSub?.cancel();
    _ampSub?.cancel();
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
    _disappointedTimer?.cancel();
    _idleSuggestion = null;
    if (widget.messages.isEmpty) return;
    if (widget.messages.last.role != 'assistant') return;
    // After 20 s of inactivity: show encouraging suggestion.
    _idleTimer = Timer(const Duration(seconds: 20), _onIdleTimeout);
  }

  Future<void> _onIdleTimeout() async {
    if (!mounted) return;
    setState(() => _mood = TutorMood.encouraging);
    final s = await widget.onIdleSuggestion();
    if (!mounted) return;
    setState(() => _idleSuggestion = s);
    // After 15 more seconds still no reply: flash disappointed then back to idle.
    _disappointedTimer = Timer(const Duration(seconds: 15), _onDisappointedTimeout);
  }

  void _onDisappointedTimeout() {
    if (!mounted) return;
    setState(() {
      _mood = TutorMood.disappointed;
      _idleSuggestion = null;
    });
    // Mochi rig auto-returns to Idle visually after ~1.5 s;
    // sync Flutter mood after the same delay.
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _mood = TutorMood.idle);
    });
  }

  void _maybeSpeakLatestAssistantReply() {
    if (widget.messages.isEmpty) return;
    final last = widget.messages.last;
    if (last.role != 'assistant') return;
    if (last.id == _lastSpokenId) return;
    _lastSpokenId = last.id;

    if (!ref.read(speechReadyProvider)) return;
    final tts = ref.read(ttsServiceProvider);
    final voiceId = _pickVoice(tts.capabilities.availableVoices, widget.persona);
    final preview = last.content.length > 80
        ? '${last.content.substring(0, 80)}…'
        : last.content;
    debugPrint('[tts] speak voice=$voiceId len=${last.content.length} "$preview"');
    tts.speak(last.content, voiceId: voiceId).catchError((Object e, StackTrace st) {
      debugPrint('[tts] failed: $e');
      logRawError('tutor_mode.tts', e, st);
    });
  }

  /// Select the TTS voice for a persona, in priority order:
  ///   1. Direct SID override (`ttsVoiceSid`) → voices[sid]
  ///   2. Named voice id (`voiceId`) if it exists in the manifest
  ///   3. Gender + age heuristic on voice name fragments
  ///   4. First available voice
  String _pickVoice(List<String> voices, Persona persona) {
    if (voices.isEmpty) return '';

    // 1. Direct SID override.
    if (persona.ttsVoiceSid != null) {
      final idx = persona.ttsVoiceSid!.clamp(0, voices.length - 1);
      return voices[idx];
    }

    // 2. Named voice id.
    if (persona.voiceId != null && voices.contains(persona.voiceId)) {
      return persona.voiceId!;
    }

    // 3. Gender + age heuristic.
    const femaleHints = ['amy', 'jenny', 'linda', 'sarah', 'lisa', 'emma', 'aria'];
    const maleHints   = ['alan', 'james', 'john', 'ryan', 'guy', 'davis', 'tony'];
    const youngHints  = ['jenny', 'amy', 'aria', 'ryan'];
    const elderHints  = ['davis', 'alan', 'linda'];

    List<String> hints = [];
    if (persona.gender == 'female') hints = femaleHints;
    if (persona.gender == 'male')   hints = maleHints;

    // Narrow by age if set.
    if (persona.ttsAge == 'young' && hints.isNotEmpty) {
      hints = hints.where((h) => youngHints.contains(h)).toList();
      if (hints.isEmpty) hints = youngHints; // fallback to age-only hints
    } else if (persona.ttsAge == 'elder' && hints.isNotEmpty) {
      hints = hints.where((h) => elderHints.contains(h)).toList();
      if (hints.isEmpty) hints = elderHints;
    }

    if (hints.isNotEmpty) {
      final match = voices.firstWhere(
        (v) => hints.any((h) => v.toLowerCase().contains(h)),
        orElse: () => '',
      );
      if (match.isNotEmpty) return match;
    }

    // 4. First voice.
    return voices.first;
  }

  bool get _tutorSpeaking =>
      _mood == TutorMood.speaking &&
      _latestForRole('assistant') != null;

  Future<void> _startRecording() async {
    // Hard guard: don't open the mic while a previous turn is still
    // being transcribed / waiting for the AI reply. The mic button is
    // already disabled in this mood, but a programmatic toggle could
    // sneak through otherwise.
    if (_mood == TutorMood.thinking) return;
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
      debugPrint('[stt] mic.start failed — recorder returned false');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the microphone.')),
      );
      return;
    }
    debugPrint('[stt] mic.start ok — listening');
    setState(() => _mood = TutorMood.listening);
    await ref.read(ttsServiceProvider).stop();
  }

  Future<void> _stopRecording() async {
    final recorder = ref.read(audioRecorderProvider);
    final capture = await recorder.stop();
    if (!mounted) return;
    if (capture == null) {
      debugPrint('[stt] mic.stop -> no capture (null)');
      setState(() => _mood = TutorMood.idle);
      return;
    }
    debugPrint('[stt] mic.stop -> ${capture.pcm.length} bytes pcm captured');

    if (!ref.read(speechReadyProvider)) {
      debugPrint('[stt] aborted — speech models not ready');
      setState(() => _mood = TutorMood.idle);
      final snap = ref.read(modelRegistrySnapshotProvider).valueOrNull;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(speechModelsStatusMessage(snap)),
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }

    // From this point on we own the turn. Flip to `thinking` so the
    // mic button disables, the status pill shows a spinner, and the
    // avatar is in a neutral pose ready for the eventual TTS reply.
    // The mood is cleared in `finally` so a failure can't leave the
    // UI stuck disabled forever.
    setState(() => _mood = TutorMood.thinking);

    final stt = ref.read(sttServiceProvider);
    final swatch = Stopwatch()..start();
    try {
      final result = await stt.transcribe(capture.pcm, language: 'en');
      swatch.stop();
      final text = result.text.trim();
      debugPrint(
        '[stt] transcribed in ${swatch.elapsedMilliseconds}ms: '
        '"$text" (audio ${result.audioDuration.inMilliseconds}ms)',
      );
      if (text.isEmpty) {
        debugPrint('[stt] empty result — not sending');
        return;
      }
      // Sends the turn upstream and awaits the AI reply — keeps us
      // in `thinking` mood for the whole round-trip.
      await widget.onSendText(text);
    } catch (e, st) {
      swatch.stop();
      debugPrint('[stt] transcribe failed after ${swatch.elapsedMilliseconds}ms: $e');
      logRawError('tutor_mode.stt', e, st);
      if (mounted) {
        showPoliteErrorSnack(context, e, tag: 'tutor_mode.stt', stack: st);
      }
    } finally {
      if (mounted && _mood == TutorMood.thinking) {
        // The TTS isSpeakingStream subscriber will flip us to
        // `speaking` the moment audio playback starts; until then,
        // hand back to `idle` so the mic re-enables and the user
        // can interrupt with a new turn if they want.
        setState(() => _mood = TutorMood.idle);
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
                    amplitude: _amplitude,
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
    this.onSwitchToChat,
    required this.onEnd,
  });

  final int turnCount;
  final bool ending;
  final VoidCallback onBack;
  final VoidCallback? onSwitchToChat;
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
              if (onSwitchToChat != null)
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
  const _AvatarStage({
    required this.persona,
    required this.mood,
    required this.amplitude,
  });

  final Persona persona;
  final TutorMood mood;
  final double amplitude;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final statusLabel = switch (mood) {
      TutorMood.listening => 'Listening…',
      TutorMood.speaking => 'Speaking…',
      TutorMood.thinking => 'Thinking…',
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
      // Fill the full Expanded slot. Avatar gets the flexible top portion;
      // name + pill sit below at their natural height and can never overflow.
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final side = math.min(constraints.maxWidth, constraints.maxHeight);
                  final avatarSize = (side * 0.85).clamp(96.0, 280.0);
                  return TutorAvatar(
                    key: ValueKey(persona.id),
                    persona: persona,
                    mood: mood,
                    amplitude: amplitude,
                    size: avatarSize,
                  );
                },
              ),
            ),
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
          const SizedBox(height: 12),
        ],
      ),
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
      TutorMood.thinking => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
          Icons.hourglass_top_rounded,
        ),
      _ => (scheme.surfaceContainerHigh, scheme.onSurfaceVariant, Icons.mic_none),
    };

    // Tiny spinner replaces the static icon while we're awaiting the
    // AI reply, so the "Thinking…" pill is visibly alive.
    final leading = mood == TutorMood.thinking
        ? SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Icon(icon, size: 18, color: fg);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
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
    // Mic is locked while:
    //  * the tutor is speaking (don't talk over its TTS), and
    //  * we're awaiting the AI reply for the user's last turn.
    final enabled = mood != TutorMood.speaking && mood != TutorMood.thinking;
    return Material(
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: _MicButton(
            recording: recording,
            thinking: mood == TutorMood.thinking,
            enabled: enabled,
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
    required this.thinking,
    required this.enabled,
    required this.onToggle,
  });

  final bool recording;
  final bool thinking;
  final bool enabled;
  final Future<void> Function() onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = enabled || recording;
    final color = recording
        ? scheme.error
        : (thinking ? scheme.surfaceContainerHighest : scheme.primary);
    final fg = recording
        ? scheme.onError
        : (thinking ? scheme.onSurfaceVariant : scheme.onPrimary);

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
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: recording ? 0.45 : 0.28),
                blurRadius: recording ? 28 : 16,
                spreadRadius: recording ? 4 : 0,
              ),
            ],
          ),
          // Spinner replaces the mic glyph while the AI is thinking so
          // the user gets unmistakable feedback that a request is in
          // flight and the button is intentionally locked.
          child: thinking
              ? Padding(
                  padding: const EdgeInsets.all(22),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: fg,
                  ),
                )
              : Icon(
                  recording ? Icons.stop_rounded : Icons.mic_rounded,
                  size: recording ? 40 : 34,
                  color: fg,
                ),
        ),
      ),
    );
  }
}
