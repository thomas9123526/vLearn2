// Stage 9: scan an external-storage directory for `.ddp` files,
// unpack any that haven't been processed before, and track state so
// relaunches are cheap.
//
// State file format (`datapack_state.json` next to the unpacked
// content):
// {
//   "schema": 1,
//   "installed": {
//     "out_font.ddp": {
//       "sha256":      "<64 hex>",
//       "bundle_name": "out_font",
//       "unpacked_at": "2026-05-21T10:00:00Z",
//       "files":       ["fonts/Lora-Regular.ttf", ...]
//     },
//     ...
//   }
// }
//
// The .ddp's SHA-256 is the install key — an updated .ddp with the
// same filename but new bytes triggers a re-unpack.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;

import 'datapack_log.dart';
import 'datapack_factory.dart';
import 'datapack_paths.dart';

/// One entry of `installer.installPending()`'s return value.
class DataPackInstallOutcome {
  DataPackInstallOutcome({
    required this.packPath,
    required this.bundleName,
    required this.status,
    required this.unpackedFileCount,
    this.error,
  });

  /// Absolute path to the source `.ddp`.
  final String packPath;

  /// `bundleName` from the manifest, or empty on early failure.
  final String bundleName;

  /// One of `installed`, `cached`, `failed`.
  final DataPackInstallStatus status;

  /// Number of files written. 0 on failure or cached (already installed).
  final int unpackedFileCount;

  /// Set when `status == failed` — the exception message.
  final String? error;
}

enum DataPackInstallStatus { installed, cached, failed }

class DataPackInstaller {
  DataPackInstaller({
    required this.factory,
    required this.paths,
  });

  final DataUnpackFactory factory;
  final DataPackPaths paths;

  /// Walk `paths.packsDir` for `*.ddp`, unpack any whose SHA-256 isn't
  /// already in the state file. Idempotent: callable on every
  /// launch with no side effect once everything is up to date.
  Future<List<DataPackInstallOutcome>> installPending() async {
    final outcomes = <DataPackInstallOutcome>[];

    dpLog('installer: scanning ${paths.packsDir.path}');
    if (!paths.packsDir.existsSync()) {
      dpLog('installer: packs dir does not exist — nothing to install');
      return outcomes;  // nothing to do — admin hasn't dropped any packs yet
    }

    final state = await _loadState();

    final candidates = paths.packsDir
        .listSync(followLinks: false)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.dat'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    dpLog('installer: found ${candidates.length} .dat pack file(s)');
    if (candidates.isEmpty) {
      dpLog('installer: drop .dat pack files into ${paths.packsDir.path} '
          'and relaunch');
    }

    var installed = 0, cached = 0, failed = 0;
    for (final pack in candidates) {
      final fileName = pack.uri.pathSegments.last;
      final fingerprint = await _hashFile(pack);
      final prior = state['installed']?[fileName];
      if (prior is Map &&
          prior['sha256'] == fingerprint) {
        dpLog('installer: CACHED  $fileName '
            '(sha256 ${fingerprint.substring(0, 12)}… already installed)');
        ++cached;
        outcomes.add(DataPackInstallOutcome(
          packPath:          pack.path,
          bundleName:        (prior['bundle_name'] as String?) ?? '',
          status:            DataPackInstallStatus.cached,
          unpackedFileCount: 0,
        ));
        continue;
      }

      dpLog('installer: INSTALL $fileName '
          '(sha256 ${fingerprint.substring(0, 12)}… — new or changed)');
      try {
        final result = await factory.unpack(
          packPath: pack.path,
          outRoot:  paths.unpackedRoot.path,
        );
        state['installed'] ??= <String, dynamic>{};
        state['installed'][fileName] = {
          'sha256':      fingerprint,
          'bundle_name': result.bundleName,
          'unpacked_at': DateTime.now().toUtc().toIso8601String(),
          'files':       result.files.map((f) => f.path).toList(),
        };
        ++installed;
        dpLog('installer: OK      $fileName → bundle "${result.bundleName}", '
            '${result.files.length} file(s)');
        outcomes.add(DataPackInstallOutcome(
          packPath:          pack.path,
          bundleName:        result.bundleName,
          status:            DataPackInstallStatus.installed,
          unpackedFileCount: result.files.length,
        ));
      } catch (e) {
        ++failed;
        dpLog('installer: FAILED  $fileName — $e');
        outcomes.add(DataPackInstallOutcome(
          packPath:          pack.path,
          bundleName:        '',
          status:            DataPackInstallStatus.failed,
          unpackedFileCount: 0,
          error:             e.toString(),
        ));
      }
    }

    await _saveState(state);
    dpLog('installer: done — $installed installed, $cached cached, '
        '$failed failed. State saved to ${paths.stateFile.path}');
    return outcomes;
  }

  Future<Map<String, dynamic>> _loadState() async {
    if (!paths.stateFile.existsSync()) {
      return <String, dynamic>{
        'schema':    1,
        'installed': <String, dynamic>{},
      };
    }
    try {
      final raw = jsonDecode(await paths.stateFile.readAsString());
      if (raw is Map<String, dynamic>) return raw;
    } catch (_) {
      // Corrupt state — start over. The unpacked files on disk are
      // fine to keep; re-installing overwrites them anyway.
    }
    return <String, dynamic>{
      'schema':    1,
      'installed': <String, dynamic>{},
    };
  }

  Future<void> _saveState(Map<String, dynamic> state) async {
    final tmp = File('${paths.stateFile.path}.tmp');
    await tmp.writeAsString(
        const JsonEncoder.withIndent('  ').convert(state),
        flush: true);
    await tmp.rename(paths.stateFile.path);
  }

  Future<String> _hashFile(File f) async {
    final digest = await crypto.sha256.bind(f.openRead()).first;
    return digest.toString();
  }
}
