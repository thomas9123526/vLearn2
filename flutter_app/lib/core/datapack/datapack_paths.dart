// Where the admin drops `.ddp` files on the device and where the
// unpacker writes the decoded contents.
//
// Mirrors the path-resolution pattern from
// `lib/core/config/app_config.dart`: prefer the public
// `/storage/emulated/0/룡마/가상외국어회화/datapacks/` folder when
// `MANAGE_EXTERNAL_STORAGE` is granted, otherwise fall back to the
// app-scoped external dir under the same `룡마/가상외국어회화/`
// hierarchy. The admin sees the same folder from a USB transfer
// either way.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'datapack_log.dart';

class DataPackPaths {
  const DataPackPaths({
    required this.packsDir,
    required this.unpackedRoot,
    required this.stateFile,
  });

  /// Where the admin places `.ddp` files. Scanned at startup.
  final Directory packsDir;

  /// Root where decoded plaintext files land. Subfolders inside come
  /// from each manifest's `out_folder` value.
  final Directory unpackedRoot;

  /// JSON file tracking which `.ddp` files we've already unpacked
  /// (by SHA-256 fingerprint), so a relaunch doesn't redo the work.
  final File stateFile;

  /// Resolve the three paths for the current platform. Creates
  /// missing directories. Throws if the platform isn't supported
  /// (Android + Windows for now; iOS/macOS/Linux would need their
  /// own resolution rules).
  static Future<DataPackPaths> resolve() async {
    if (Platform.isAndroid) return _resolveAndroid();
    if (Platform.isWindows) return _resolveWindows();
    throw UnsupportedError(
        'DataPackPaths.resolve: unsupported platform '
        '${Platform.operatingSystem}');
  }

  static Future<DataPackPaths> _resolveAndroid() async {
    final publicPacks =
        Directory('/storage/emulated/0/룡마/가상외국어회화/datapacks');
    final extBase = await getExternalStorageDirectory() ??
        await getApplicationSupportDirectory();
    final fallbackPacks = Directory(
        p.join(extBase.path, '룡마', '가상외국어회화', 'datapacks'));

    final hasPermission =
        await Permission.manageExternalStorage.isGranted ||
            await Permission.storage.isGranted;

    final packs = hasPermission ? publicPacks : fallbackPacks;
    dpLog('paths: platform=Android, '
        'MANAGE_EXTERNAL_STORAGE granted=$hasPermission');
    dpLog('paths: ${hasPermission ? "using PUBLIC path" : "using FALLBACK "
        "path (permission not granted — public /storage/emulated/0/룡마/... "
        "is not reachable)"}');
    if (!packs.existsSync()) {
      try {
        packs.createSync(recursive: true);
        dpLog('paths: created packs dir (did not exist)');
      } catch (e) {
        // Public dir creation can fail before permission is granted;
        // fall back silently. The installer will see "no packs to
        // process" and exit clean.
        dpLog('paths: WARNING could not create packs dir: $e');
      }
    }

    final support = await getApplicationSupportDirectory();
    final unpacked = Directory(p.join(support.path, 'datapack_unpacked'));
    unpacked.createSync(recursive: true);

    final state = File(p.join(support.path, 'datapack_state.json'));

    dpLog('paths: .ddp folder (drop files here) = ${packs.path}');
    dpLog('paths: decoded files go to          = ${unpacked.path}');
    dpLog('paths: install state file           = ${state.path}');

    return DataPackPaths(
      packsDir:     packs,
      unpackedRoot: unpacked,
      stateFile:    state,
    );
  }

  static Future<DataPackPaths> _resolveWindows() async {
    // On Windows there's no equivalent of /sdcard; we just sit next
    // to the .exe so the admin can drop .ddp files in the same
    // folder as the rest of the app's config.
    final exeDir = File(Platform.resolvedExecutable).parent;
    final packs = Directory(p.join(exeDir.path, 'datapacks'));
    if (!packs.existsSync()) packs.createSync(recursive: true);

    final support = await getApplicationSupportDirectory();
    final unpacked = Directory(p.join(support.path, 'datapack_unpacked'));
    unpacked.createSync(recursive: true);

    final state = File(p.join(support.path, 'datapack_state.json'));

    dpLog('paths: platform=Windows');
    dpLog('paths: .ddp folder (drop files here) = ${packs.path}');
    dpLog('paths: decoded files go to          = ${unpacked.path}');
    dpLog('paths: install state file           = ${state.path}');

    return DataPackPaths(
      packsDir:     packs,
      unpackedRoot: unpacked,
      stateFile:    state,
    );
  }
}
