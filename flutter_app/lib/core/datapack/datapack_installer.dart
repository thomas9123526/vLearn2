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
import 'datapack_manifest.dart';
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

  /// One of `installed`, `cached`, `deferred`, `failed`.
  final DataPackInstallStatus status;

  /// Number of files written. 0 on failure / cached / deferred.
  final int unpackedFileCount;

  /// Set when `status == failed` — the exception message.
  final String? error;
}

/// - `installed` — unpacked this run.
/// - `cached`    — already unpacked in a prior run (SHA-256 match).
/// - `deferred`  — skipped: its `unpack_phase` isn't the phase being
///                 installed (e.g. an "on-demand" pack at splash).
/// - `failed`    — could not be read or unpacked; see `error`.
enum DataPackInstallStatus { installed, cached, deferred, failed }

/// A `.dat` discovered during a scan: the file, its peeked manifest,
/// and its SHA-256 fingerprint. Internal to `installGroup`.
class _ScannedPack {
  _ScannedPack(this.file, this.manifest, this.sha);
  final File file;
  final DataPackManifest manifest;
  final String sha;
}

/// Where the [group]'s pack(s) were unpacked to, read straight from
/// the install state file — the absolute model-root directory
/// (`<unpackedRoot>/<out_folder>`). Returns null if the group isn't
/// installed yet. Lets a feature (e.g. ModelRegistry → "speech")
/// locate its data without re-reading any `.dat`.
Future<String?> unpackedRootForGroup(
    DataPackPaths paths, String group) async {
  if (!paths.stateFile.existsSync()) return null;
  try {
    final raw = jsonDecode(await paths.stateFile.readAsString());
    if (raw is! Map) return null;
    final installed = raw['installed'];
    if (installed is! Map) return null;
    for (final entry in installed.values) {
      if (entry is Map &&
          entry['group'] == group &&
          entry['unpacked_subroot'] is String) {
        return entry['unpacked_subroot'] as String;
      }
    }
  } catch (_) {
    // Corrupt state file — treat the group as not installed.
  }
  return null;
}

class DataPackInstaller {
  DataPackInstaller({
    required this.factory,
    required this.paths,
  });

  final DataUnpackFactory factory;
  final DataPackPaths paths;

  /// Walk `paths.packsDir` for `*.dat`, and for every pack whose
  /// `unpack_phase` matches [phase], unpack any whose SHA-256 isn't
  /// already in the state file. Packs of a different phase are
  /// reported `deferred` and left untouched. Idempotent: callable on
  /// every launch with no side effect once everything is up to date.
  ///
  /// [phase] defaults to `"splash"` — the startup pass. The on-demand
  /// pass (Stage C) calls it with `phase: "on-demand"` (plus a group
  /// filter).
  Future<List<DataPackInstallOutcome>> installPending({
    String phase = 'splash',
  }) async {
    final outcomes = <DataPackInstallOutcome>[];

    dpLog('installer: scanning ${paths.packsDir.path} (phase "$phase")');
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

    var installed = 0, cached = 0, deferred = 0, failed = 0;
    for (final pack in candidates) {
      final fileName = pack.uri.pathSegments.last;

      // Peek the manifest (header + manifest only — cheap, no decrypt,
      // no whole-file read) to learn this pack's phase before deciding
      // whether to touch it this run.
      DataPackManifest manifest;
      try {
        manifest = await readPackManifest(pack.path);
      } catch (e) {
        ++failed;
        dpLog('installer: FAILED  $fileName — cannot read manifest: $e');
        outcomes.add(DataPackInstallOutcome(
          packPath:          pack.path,
          bundleName:        '',
          status:            DataPackInstallStatus.failed,
          unpackedFileCount: 0,
          error:             e.toString(),
        ));
        continue;
      }

      // Wrong phase — leave it for whoever installs that phase.
      if (manifest.unpackPhase != phase) {
        ++deferred;
        dpLog('installer: DEFER   $fileName '
            '(phase "${manifest.unpackPhase}", group "${manifest.group}" '
            '— not this run\'s phase "$phase")');
        outcomes.add(DataPackInstallOutcome(
          packPath:          pack.path,
          bundleName:        manifest.bundleName,
          status:            DataPackInstallStatus.deferred,
          unpackedFileCount: 0,
        ));
        continue;
      }

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
          'sha256':           fingerprint,
          'bundle_name':      result.bundleName,
          'group':            manifest.group,
          'unpacked_subroot': _subrootFor(manifest),
          'unpacked_at':      DateTime.now().toUtc().toIso8601String(),
          'files':            result.files.map((f) => f.path).toList(),
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
        '$deferred deferred, $failed failed. '
        'State saved to ${paths.stateFile.path}');
    return outcomes;
  }

  /// Unpack every `.dat` whose manifest `group` matches [group] and
  /// that isn't already installed — the on-demand counterpart to
  /// [installPending]. A feature calls this the first time it needs
  /// its data (e.g. the conversation screen for the "speech" group).
  ///
  /// [onProgress] fires with an overall fraction (0.0–1.0) across all
  /// of the group's not-yet-installed packs, plus a human-readable
  /// status — enough to drive a 0–100% progress bar. Already-cached
  /// packs are reported `cached` and counted as instantly complete.
  ///
  /// The state file is checkpointed after every pack, so a group
  /// unpack interrupted partway resumes cleanly on the next call.
  Future<List<DataPackInstallOutcome>> installGroup(
    String group, {
    void Function(double fraction, String status)? onProgress,
  }) async {
    final outcomes = <DataPackInstallOutcome>[];
    dpLog('installer: group "$group" — scanning ${paths.packsDir.path}');

    if (!paths.packsDir.existsSync()) {
      dpLog('installer: packs dir missing — nothing for group "$group"');
      onProgress?.call(1.0, 'No data packs found');
      return outcomes;
    }

    final state = await _loadState();
    final candidates = paths.packsDir
        .listSync(followLinks: false)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.dat'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    // Peek each manifest; keep this group's packs.
    final inGroup = <_ScannedPack>[];
    for (final pack in candidates) {
      DataPackManifest manifest;
      try {
        manifest = await readPackManifest(pack.path);
      } catch (e) {
        dpLog('installer: FAILED  ${pack.uri.pathSegments.last} — '
            'cannot read manifest: $e');
        outcomes.add(DataPackInstallOutcome(
          packPath:          pack.path,
          bundleName:        '',
          status:            DataPackInstallStatus.failed,
          unpackedFileCount: 0,
          error:             e.toString(),
        ));
        continue;
      }
      if (manifest.group != group) continue;
      inGroup.add(_ScannedPack(pack, manifest, await _hashFile(pack)));
    }
    dpLog('installer: group "$group" — ${inGroup.length} pack(s) matched');

    // Split: already-cached vs needs-unpack.
    final toUnpack = <_ScannedPack>[];
    for (final sp in inGroup) {
      final fileName = sp.file.uri.pathSegments.last;
      final prior = state['installed']?[fileName];
      if (prior is Map && prior['sha256'] == sp.sha) {
        dpLog('installer: CACHED  $fileName (group "$group")');
        outcomes.add(DataPackInstallOutcome(
          packPath:          sp.file.path,
          bundleName:        sp.manifest.bundleName,
          status:            DataPackInstallStatus.cached,
          unpackedFileCount: 0,
        ));
      } else {
        toUnpack.add(sp);
      }
    }

    final totalFiles =
        toUnpack.fold<int>(0, (s, e) => s + e.manifest.files.length);
    if (totalFiles == 0) {
      onProgress?.call(1.0, 'Already set up');
      dpLog('installer: group "$group" — all packs already installed');
      return outcomes;
    }

    var filesDoneBefore = 0;
    for (final sp in toUnpack) {
      final fileName  = sp.file.uri.pathSegments.last;
      final packFiles = sp.manifest.files.length;
      dpLog('installer: INSTALL $fileName '
          '(group "$group", $packFiles file(s))');
      try {
        final result = await factory.unpack(
          packPath: sp.file.path,
          outRoot:  paths.unpackedRoot.path,
          onFileProgress: (done, total) {
            final overall = (filesDoneBefore + done) / totalFiles;
            // No bundle/model name in the user-facing status — it
            // would leak the internal pack identity. Plain file count.
            onProgress?.call(
              overall.clamp(0.0, 1.0),
              'Unpacking $done of $total files',
            );
          },
        );
        state['installed'] ??= <String, dynamic>{};
        state['installed'][fileName] = {
          'sha256':           sp.sha,
          'bundle_name':      result.bundleName,
          'group':            sp.manifest.group,
          'unpacked_subroot': _subrootFor(sp.manifest),
          'unpacked_at':      DateTime.now().toUtc().toIso8601String(),
          'files':            result.files.map((f) => f.path).toList(),
        };
        await _saveState(state);  // checkpoint after each pack
        outcomes.add(DataPackInstallOutcome(
          packPath:          sp.file.path,
          bundleName:        result.bundleName,
          status:            DataPackInstallStatus.installed,
          unpackedFileCount: result.files.length,
        ));
        dpLog('installer: OK      $fileName → "${result.bundleName}", '
            '${result.files.length} file(s)');
      } catch (e) {
        dpLog('installer: FAILED  $fileName — $e');
        outcomes.add(DataPackInstallOutcome(
          packPath:          sp.file.path,
          bundleName:        sp.manifest.bundleName,
          status:            DataPackInstallStatus.failed,
          unpackedFileCount: 0,
          error:             e.toString(),
        ));
      }
      filesDoneBefore += packFiles;
    }

    onProgress?.call(1.0, 'Done');
    dpLog('installer: group "$group" — done');
    return outcomes;
  }

  /// Absolute directory the bundle's files land in:
  /// `<unpackedRoot>/<out_folder>`. Every file in a bundle shares the
  /// same `out_folder` (the packer sets it bundle-wide), so the first
  /// file's is representative. Recorded in the state file so
  /// [unpackedRootForGroup] can answer "where is group X?" without
  /// re-reading the .dat.
  String _subrootFor(DataPackManifest manifest) {
    if (manifest.files.isEmpty) return paths.unpackedRoot.path;
    final outFolder = manifest.files.first.outFolder
        .replaceAll('/', Platform.pathSeparator);
    return outFolder.isEmpty
        ? paths.unpackedRoot.path
        : '${paths.unpackedRoot.path}${Platform.pathSeparator}$outFolder';
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
