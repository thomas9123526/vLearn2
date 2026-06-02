library;

/// STT / TTS engine configuration.
///
/// ## How to configure
///
/// Edit `assets/speech_config.json` — it is loaded at startup by
/// [SpeechConfigLoader] and passed to the speech service factory.
/// No recompile needed for model swaps.
///
/// ## Supported STT engines
///
/// ### sherpaOnnxStreaming  (real-time, default)
///   True streaming transducer (Zipformer + RNN-T or Conformer + CTC).
///   Partial hypotheses appear while the user speaks.
///   Recommended model families:
///     • sherpa-onnx-streaming-zipformer-en-2023-06-26  (English-only, most accurate)
///     • sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20
///   Required manifest keys: stt/encoder, stt/decoder, stt/joiner, stt/tokens
///
/// ### sherpaOnnxWhisper  (batch, highest accuracy)
///   Non-streaming. Processes the complete utterance after VAD silence.
///   ~300–800 ms latency after speech ends (larger models = slower).
///   Recommended models (arm64, 6 GB RAM):
///     • whisper-large-v3-turbo  (fp16 ONNX, ~1 GB — best accuracy)
///     • whisper-medium.en       (int8 ONNX, ~400 MB — good balance)
///     • whisper-small.en        (int8 ONNX, ~150 MB — fastest)
///   Required manifest keys: stt/whisper-encoder, stt/whisper-decoder, stt/tokens
///
/// ## Quantization guide (arm64 phone, ≥ 6 GB RAM)
///
/// | Format | Memory  | Speed   | Accuracy loss | Recommended for          |
/// |--------|---------|---------|---------------|--------------------------|
/// | fp32   | 4 bytes | 1×      | —             | Development/reference    |
/// | fp16   | 2 bytes | ~1.5×   | < 0.5 %       | Whisper on arm64 ✓       |
/// | int8   | 1 byte  | ~2–3×   | < 1 %         | Streaming Zipformer ✓    |
///
/// ARM Cortex-A76+ (2019+) supports fp16 arithmetic natively (NEON FP16).
/// int8 dot-product is even faster and fits all A-series phones (2016+).
///
/// **Our recommendation for this device class:**
///   - Streaming STT (real-time): int8 Zipformer
///   - Batch STT (high accuracy):  fp16 Whisper large-v3-turbo
///   - TTS (VITS):                 fp32 (model < 100 MB, quality matters more)
///
/// ## Where to put model files
///
/// Models are packed into `.ddp` data bundles by the DataManage toolchain.
/// After unpacking, sherpa-onnx expects them at paths declared in the
/// model manifest (see ModelRegistry).  The manifest key names used by
/// SherpaOnnxSttService are:
///   stt/encoder   stt/decoder   stt/joiner   stt/tokens          ← streaming
///   stt/whisper-encoder   stt/whisper-decoder   stt/tokens        ← whisper
///   tts/model     tts/tokens    tts/data                          ← TTS
///
/// To swap models: replace the `.onnx` files in the bundle and update the
/// manifest.  The engine auto-detects which mode to use based on which keys
/// are present — no code change required.

enum SttEngine {
  /// Real-time streaming (Zipformer/RNN-T). Best for conversation flow.
  sherpaOnnxStreaming,

  /// Batch Whisper via sherpa-onnx. Highest accuracy, ~0.5 s lag after speech.
  sherpaOnnxWhisper,
  // Future: whisperCpp, moonshine, parakeet
}

enum QuantizationMode {
  fp32,
  fp16,
  int8,
}

/// Runtime speech configuration loaded from `assets/speech_config.json`.
class SpeechConfig {
  const SpeechConfig({
    this.sttEngine = SttEngine.sherpaOnnxStreaming,
    this.sttQuantization = QuantizationMode.int8,
    this.sttNumThreads = 4,
    this.ttsQuantization = QuantizationMode.fp32,
    this.ttsNumThreads = 2,
  });

  factory SpeechConfig.fromJson(Map<String, dynamic> j) {
    return SpeechConfig(
      sttEngine: _parseEngine(j['sttEngine'] as String?),
      sttQuantization: _parseQuant(j['sttQuantization'] as String?),
      sttNumThreads: (j['sttNumThreads'] as num?)?.toInt() ?? 4,
      ttsQuantization: _parseQuant(j['ttsQuantization'] as String?),
      ttsNumThreads: (j['ttsNumThreads'] as num?)?.toInt() ?? 2,
    );
  }

  // ── Fields ──────────────────────────────────────────────

  final SttEngine sttEngine;

  /// Informational — the actual quantization is baked into the .onnx file.
  /// Set this to match the model you downloaded so the UI can display it.
  final QuantizationMode sttQuantization;

  final int sttNumThreads;
  final QuantizationMode ttsQuantization;
  final int ttsNumThreads;

  static SttEngine _parseEngine(String? s) {
    switch (s) {
      case 'sherpaOnnxWhisper':
        return SttEngine.sherpaOnnxWhisper;
      default:
        return SttEngine.sherpaOnnxStreaming;
    }
  }

  static QuantizationMode _parseQuant(String? s) {
    switch (s) {
      case 'fp32': return QuantizationMode.fp32;
      case 'fp16': return QuantizationMode.fp16;
      default:     return QuantizationMode.int8;
    }
  }

  String get sttEngineLabel {
    switch (sttEngine) {
      case SttEngine.sherpaOnnxStreaming:
        return 'sherpa-onnx streaming (Zipformer)';
      case SttEngine.sherpaOnnxWhisper:
        return 'sherpa-onnx Whisper (batch)';
    }
  }

  String get sttQuantLabel {
    switch (sttQuantization) {
      case QuantizationMode.fp32: return 'fp32';
      case QuantizationMode.fp16: return 'fp16';
      case QuantizationMode.int8: return 'int8';
    }
  }
}
