import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/polite_error.dart';
import '../../../core/models/models.dart';
import '../../../core/speech/audio_recorder.dart';
import '../../../core/speech/speech_service.dart';
import 'tutor_avatar.dart';

/// Face-to-face Tutor mode. Renders the animated [TutorAvatar] centered on
/// screen with the most-recent assistant reply as a "live caption", a
/// push-to-talk mic button, and idle-prompt suggestions that fade in if the
/// user stays silent.
///
/// Compared to the chat-bubble view this:
///   * speaks each assistant reply via [TextToSpeechService.speak] as soon
///     as it arrives;
///   * lets the user reply by holding the mic instead of typing;
///   * surfaces tutor mood (idle / listening / speaking / praising /
///     disappointed / encouraging) to drive avatar animations and floating
///     emotion icons.
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

  /// Send a text turn through the regular ConversationsApi.sendMessage path
  /// so chat-mode and tutor-mode share the same backend flow.
  final Future<void> Function(String text) onSendText;

  /// Called once the idle timer fires — used by the parent to fetch an
  /// AI-generated suggestion from the backend. Returns the suggestion or
  /// null if none is available.
  final Future<String?> Function() onIdleSuggestion;

  @override
  ConsumerState<TutorModeView> createState() => _TutorModeViewState();
}

class _TutorModeViewState extends ConsumerState<TutorModeView> {
  TutorMood _mood = TutorMood.idle;
  String? _liveCaption;
  String? _idleSuggestion;
  Timer? _idleTimer;
  StreamSubscription<bool>? _ttsSub;

  /// Message id of the latest assistant turn we've spoken aloud. Stops us
  /// from re-speaking the same line when the parent rebuilds.
  String? _lastSpokenId;

  /// Tutor mode also accepts typed input now — useful when the user can't
  /// speak out loud (public place, broken mic, sherpa-onnx not installed).
  /// The avatar still animates and TTS still speaks each assistant reply.
  final TextEditingController _typedInput = TextEditingController();
  bool _typedSending = false;

  @override
  void initState() {
    super.initState();
    // Listen to TTS playback state so the avatar pulses with the audio.
    // The base interface exposes an always-present stream; the placeholder
    // returns Stream.empty() so this subscription stays safe even in
    // text-only mode.
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

  /// 20s of silence → ping the parent for a suggestion to show.
  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleSuggestion = null;
    if (widget.messages.isEmpty) return;
    final lastRole = widget.messages.last.role;
    if (lastRole != 'assistant') return;
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
    setState(() => _liveCaption = last.content);

    final tts = ref.read(ttsServiceProvider);
    if (!tts.isAvailable) return; // text-only mode — just show the caption
    final voiceId = widget.persona.voiceId ??
        (tts.capabilities.availableVoices.isNotEmpty
            ? tts.capabilities.availableVoices.first
            : '');
    // Fire and forget — the speak future resolves when playback finishes.
    tts.speak(last.content, voiceId: voiceId).catchError((Object e, StackTrace st) {
      logRawError('tutor_mode.tts', e, st);
    });
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
    // Also stop any in-flight TTS so the tutor isn't talking over the user.
    final tts = ref.read(ttsServiceProvider);
    await tts.stop();
  }

  Future<void> _stopRecording() async {
    final recorder = ref.read(audioRecorderProvider);
    final capture = await recorder.stop();
    if (!mounted) return;
    setState(() => _mood = TutorMood.idle);
    if (capture == null) return;

    final stt = ref.read(sttServiceProvider);
    if (!stt.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Speech models aren\'t installed — switch to chat mode or ask your admin.',
          ),
        ),
      );
      return;
    }
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final caption = _liveCaption ?? 'Tap and hold the mic to talk.';
    final suggestion = _idleSuggestion;

    return Container(
      width: double.infinity,
      color: scheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TutorAvatar(persona: widget.persona, mood: _mood),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        caption,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (suggestion != null) ...[
                      const SizedBox(height: 16),
                      _SuggestionChip(
                        text: suggestion,
                        onSend: () async {
                          setState(() {
                            _idleSuggestion = null;
                            _mood = TutorMood.idle;
                          });
                          await widget.onSendText(suggestion);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _typedInput,
                      minLines: 1,
                      maxLines: 3,
                      enabled: !_typedSending,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendTyped(),
                      decoration: const InputDecoration(
                        hintText: 'Or type if you can\'t talk…',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _typedSending ? null : _sendTyped,
                    icon: _typedSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _MicButton(
              recording: _mood == TutorMood.listening,
              onPressStart: _startRecording,
              onPressEnd: _stopRecording,
              onCancel: _cancelRecording,
            ),
            const SizedBox(height: 20),
          ],
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
      onLongPressCancel: () => onCancel(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: recording ? 84 : 72,
        height: recording ? 84 : 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: recording ? scheme.errorContainer : scheme.primaryContainer,
          boxShadow: [
            if (recording)
              BoxShadow(
                color: scheme.error.withValues(alpha: 0.45),
                blurRadius: 24,
                spreadRadius: 6,
              ),
          ],
        ),
        child: Icon(
          recording ? Icons.stop : Icons.mic,
          size: recording ? 36 : 32,
          color: recording ? scheme.onErrorContainer : scheme.onPrimaryContainer,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onSend,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lightbulb_outline,
                    size: 18, color: scheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Try: $text',
                    style: TextStyle(color: scheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.send, size: 16, color: scheme.onPrimaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

