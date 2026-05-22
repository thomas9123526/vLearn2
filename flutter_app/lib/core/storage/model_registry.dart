import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../datapack/datapack_installer.dart' show unpackedRootForGroup;
import '../datapack/datapack_paths.dart';

/// Per-file entry from manifest.json.
class ModelFile {
  const ModelFile({
    required this.relativePath,
    required this.sha256,
    required this.sizeBytes,
  });

  factory ModelFile.fromJson(Map<String, dynamic> j) => ModelFile(
        relativePath: j['path'] as String,
        sha256: j['sha256'] as String,
        sizeBytes: (j['size'] as num).toInt(),
      );

  final String relativePath;
  final String sha256;
  final int sizeBytes;
}

/// Top-level manifest structure. The shape is intentionally tiny so an admin
/// can hand-write it if needed.
class ModelManifest {
  const ModelManifest({
    required this.version,
    required this.sttModel,
    required this.ttsModel,
    required this.vadModel,
    required this.voices,
    required this.files,
  });

  factory ModelManifest.fromJson(Map<String, dynamic> j) => ModelManifest(
        version: j['version'] as String,
        sttModel: j['stt']?['name'] as String? ?? 'unknown',
        ttsModel: j['tts']?['name'] as String? ?? 'unknown',
        vadModel: j['vad']?['name'] as String? ?? 'unknown',
        voices:
            ((j['tts']?['voices'] as List?) ?? const []).cast<String>(),
        files: ((j['files'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(ModelFile.fromJson)
            .toList(),
      );

  final String version;
  final String sttModel;
  final String ttsModel;
  final String vadModel;
  final List<String> voices;
  final List<ModelFile> files;
}

enum FileVerificationStatus { ok, missing, hashMismatch, sizeMismatch }

class FileVerification {
  const FileVerification({
    required this.file,
    required this.status,
    this.message,
  });
  final ModelFile file;
  final FileVerificationStatus status;
  final String? message;
}

enum ModelRegistryStatus { notReady, ready, corrupt, manifestMissing }

class ModelRegistrySnapshot {
  const ModelRegistrySnapshot({
    required this.status,
    required this.modelRoot,
    this.manifest,
    this.verifications = const [],
  });

  final ModelRegistryStatus status;
  final String modelRoot;
  final ModelManifest? manifest;
  final List<FileVerification> verifications;

  bool get isReady => status == ModelRegistryStatus.ready;
}

/// Owns the on-disk model bundle, the manifest, and verification.
class ModelRegistry {
  ModelRegistry({
    @visibleForTesting Directory? overrideRoot,
  }) : _overrideRoot = overrideRoot;

  final Directory? _overrideRoot;

  /// Resolves the on-disk root where the sherpa-onnx models live.
  ///
  /// Models now arrive via the **datapack** pipeline: the admin packs
  /// them into a `.dat` tagged `group: "speech"`, and the app unpacks
  /// that group (on-demand) into the unpacked tree under the admin's
  /// chosen `out_folder`. We read that exact location back from the
  /// install state file via [unpackedRootForGroup] — so the model
  /// root is wherever `out_folder` put it, no guessing.
  ///
  /// Before the speech group is installed there's no root, so we
  /// return a placeholder dir that won't contain `manifest.json` —
  /// `snapshot()` then reports `manifestMissing`, which routes the
  /// user to the speech-setup screen.
  ///
  /// A test `overrideRoot` still wins, resolving to `<override>/models`.
  Future<Directory> resolveModelRoot() async {
    Directory root;
    if (_overrideRoot != null) {
      root = Directory(p.join(_overrideRoot.path, 'models'));
    } else {
      final paths = await DataPackPaths.resolve();
      final subroot = await unpackedRootForGroup(paths, 'speech');
      root = subroot != null
          ? Directory(subroot)
          : Directory(p.join(paths.unpackedRoot.path, '_speech_not_installed'));
    }
    if (!root.existsSync()) {
      root.createSync(recursive: true);
    }
    return root;
  }

  Future<File> _manifestFile() async {
    final root = await resolveModelRoot();
    return File(p.join(root.path, 'manifest.json'));
  }

  Future<ModelManifest?> loadManifest() async {
    final file = await _manifestFile();
    if (!file.existsSync()) return null;
    try {
      final raw = await file.readAsString();
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return ModelManifest.fromJson(j);
    } catch (_) {
      return null;
    }
  }

  /// SHA-256 every file listed in the manifest.
  Future<List<FileVerification>> verifyAll(ModelManifest manifest) async {
    final root = await resolveModelRoot();
    final results = <FileVerification>[];
    for (final f in manifest.files) {
      final path = p.join(root.path, f.relativePath);
      final file = File(path);
      if (!file.existsSync()) {
        results.add(FileVerification(
          file: f,
          status: FileVerificationStatus.missing,
          message: 'Not found: $path',
        ));
        continue;
      }
      final stat = file.statSync();
      if (stat.size != f.sizeBytes) {
        results.add(FileVerification(
          file: f,
          status: FileVerificationStatus.sizeMismatch,
          message: 'Expected ${f.sizeBytes} bytes, got ${stat.size}',
        ));
        continue;
      }
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes).toString();
      if (digest != f.sha256) {
        results.add(FileVerification(
          file: f,
          status: FileVerificationStatus.hashMismatch,
          message: 'Hash mismatch',
        ));
        continue;
      }
      results.add(FileVerification(file: f, status: FileVerificationStatus.ok));
    }
    return results;
  }

  /// One-shot resolve → load manifest → verify → snapshot.
  Future<ModelRegistrySnapshot> snapshot() async {
    final root = await resolveModelRoot();
    final manifest = await loadManifest();
    if (manifest == null) {
      return ModelRegistrySnapshot(
        status: ModelRegistryStatus.manifestMissing,
        modelRoot: root.path,
      );
    }
    final verifications = await verifyAll(manifest);
    final allOk = verifications.every(
      (v) => v.status == FileVerificationStatus.ok,
    );
    return ModelRegistrySnapshot(
      status: allOk ? ModelRegistryStatus.ready : ModelRegistryStatus.corrupt,
      modelRoot: root.path,
      manifest: manifest,
      verifications: verifications,
    );
  }

  /// Resolves the absolute path to a file inside the model root.
  /// Used by sherpa-onnx services to point native code at the bundle.
  Future<String> resolveFile(String relativePath) async {
    final root = await resolveModelRoot();
    return p.join(root.path, relativePath);
  }
}

final modelRegistryProvider = Provider<ModelRegistry>((_) => ModelRegistry());

/// Snapshot used to gate UI (Models not installed screen, mic button visibility,
/// Settings → Storage tile).
final modelRegistrySnapshotProvider =
    FutureProvider<ModelRegistrySnapshot>((ref) async {
  return ref.read(modelRegistryProvider).snapshot();
});
