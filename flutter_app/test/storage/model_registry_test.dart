import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_app/core/storage/model_registry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('mr_test_');
  });

  tearDown(() async {
    if (tmp.existsSync()) await tmp.delete(recursive: true);
  });

  /// Write `bytes` to `<tmp>/models/<rel>` and return its SHA-256 hex digest.
  String writeFile(String rel, List<int> bytes) {
    final file = File(p.join(tmp.path, 'models', rel));
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
    return sha256.convert(bytes).toString();
  }

  /// Dump `manifest` as JSON at `<tmp>/models/manifest.json`.
  void writeManifest(Map<String, dynamic> manifest) {
    final file = File(p.join(tmp.path, 'models', 'manifest.json'));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(manifest));
  }

  ModelRegistry buildRegistry() => ModelRegistry(overrideRoot: tmp);

  group('loadManifest', () {
    test('returns null when manifest.json is absent', () async {
      final reg = buildRegistry();
      expect(await reg.loadManifest(), isNull);
    });

    test('parses a well-formed manifest', () async {
      writeManifest(<String, dynamic>{
        'version': 'test-1',
        'stt': <String, dynamic>{'name': 'whisper-tiny'},
        'tts': <String, dynamic>{
          'name': 'vits-piper',
          'voices': <String>['en_US-amy', 'en_GB-jenny'],
        },
        'vad': <String, dynamic>{'name': 'silero-v4'},
        'files': <Map<String, dynamic>>[
          <String, dynamic>{
            'path': 'stt/encoder.onnx',
            'sha256': 'a' * 64,
            'size': 10,
          },
        ],
      });

      final reg = buildRegistry();
      final m = await reg.loadManifest();
      expect(m, isNotNull);
      expect(m!.version, 'test-1');
      expect(m.sttModel, 'whisper-tiny');
      expect(m.ttsModel, 'vits-piper');
      expect(m.voices, ['en_US-amy', 'en_GB-jenny']);
      expect(m.files.single.relativePath, 'stt/encoder.onnx');
      expect(m.files.single.sizeBytes, 10);
    });
  });

  group('verifyAll', () {
    test('reports OK for a clean bundle', () async {
      final encoderBytes = utf8.encode('encoder-bytes');
      final encoderHash = writeFile('stt/encoder.onnx', encoderBytes);
      writeManifest(<String, dynamic>{
        'version': 'test-1',
        'stt': <String, dynamic>{'name': 'whisper-tiny'},
        'tts': <String, dynamic>{
          'name': 'vits-piper',
          'voices': <String>[],
        },
        'vad': <String, dynamic>{'name': 'silero-v4'},
        'files': <Map<String, dynamic>>[
          <String, dynamic>{
            'path': 'stt/encoder.onnx',
            'sha256': encoderHash,
            'size': encoderBytes.length,
          },
        ],
      });

      final reg = buildRegistry();
      final snap = await reg.snapshot();
      expect(snap.status, ModelRegistryStatus.ready);
      expect(snap.verifications.single.status, FileVerificationStatus.ok);
    });

    test('reports missing when a file is absent', () async {
      writeManifest(<String, dynamic>{
        'version': 'test-1',
        'stt': <String, dynamic>{'name': 'whisper-tiny'},
        'tts': <String, dynamic>{
          'name': 'vits-piper',
          'voices': <String>[],
        },
        'vad': <String, dynamic>{'name': 'silero-v4'},
        'files': <Map<String, dynamic>>[
          <String, dynamic>{
            'path': 'stt/encoder.onnx',
            'sha256': 'a' * 64,
            'size': 10,
          },
        ],
      });

      final reg = buildRegistry();
      final snap = await reg.snapshot();
      expect(snap.status, ModelRegistryStatus.corrupt);
      expect(snap.verifications.single.status, FileVerificationStatus.missing);
    });

    test('reports hashMismatch when a file is tampered', () async {
      final realBytes = utf8.encode('original');
      writeFile('stt/encoder.onnx', realBytes);
      writeManifest(<String, dynamic>{
        'version': 'test-1',
        'stt': <String, dynamic>{'name': 'whisper-tiny'},
        'tts': <String, dynamic>{
          'name': 'vits-piper',
          'voices': <String>[],
        },
        'vad': <String, dynamic>{'name': 'silero-v4'},
        'files': <Map<String, dynamic>>[
          <String, dynamic>{
            'path': 'stt/encoder.onnx',
            // wrong hash on purpose
            'sha256': 'f' * 64,
            'size': realBytes.length,
          },
        ],
      });

      final reg = buildRegistry();
      final snap = await reg.snapshot();
      expect(snap.status, ModelRegistryStatus.corrupt);
      expect(snap.verifications.single.status, FileVerificationStatus.hashMismatch);
    });

    test('reports sizeMismatch when bytes have a different length', () async {
      final realBytes = utf8.encode('original');
      final hash = writeFile('stt/encoder.onnx', realBytes);
      writeManifest(<String, dynamic>{
        'version': 'test-1',
        'stt': <String, dynamic>{'name': 'whisper-tiny'},
        'tts': <String, dynamic>{
          'name': 'vits-piper',
          'voices': <String>[],
        },
        'vad': <String, dynamic>{'name': 'silero-v4'},
        'files': <Map<String, dynamic>>[
          <String, dynamic>{
            'path': 'stt/encoder.onnx',
            'sha256': hash,
            // claim the file is bigger than it really is
            'size': realBytes.length + 5,
          },
        ],
      });

      final reg = buildRegistry();
      final snap = await reg.snapshot();
      expect(snap.status, ModelRegistryStatus.corrupt);
      expect(snap.verifications.single.status, FileVerificationStatus.sizeMismatch);
    });
  });
}
