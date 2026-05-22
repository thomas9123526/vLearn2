// Riverpod glue so any part of the app can run the unpacker on
// demand. Usage from a startup screen:
//
//   final outcomes = await ref.read(installPendingDataPacksProvider.future);
//   final installed = outcomes.where((o) => o.status == DataPackInstallStatus.installed);
//   final failed    = outcomes.where((o) => o.status == DataPackInstallStatus.failed);
//
// IMPORTANT — the actual install (PEM parsing, scanning, AES-GCM
// decryption, zlib inflate, SHA-256, file writes) runs on a
// **background isolate** via `Isolate.run`. Pure-Dart crypto on
// tens-of-MB model bundles takes far longer than Android's ~5 s ANR
// watchdog allows; doing it on the main isolate froze the whole UI
// and tripped "App isn't responding". The main isolate only does the
// plugin-dependent prep (path resolution + asset loads) which can't
// run off-isolate anyway.

import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'datapack_factory.dart';
import 'datapack_installer.dart';
import 'datapack_log.dart';
import 'datapack_paths.dart';

const String _kAdminKeyAsset = 'assets/datamanage/admin.key';
const String _kRootCaAsset   = 'assets/datamanage/root_ca.crt';

/// Everything the background isolate needs to run an install. Every
/// field is a plain `String`, so the whole object copies cleanly
/// across the isolate boundary.
class DataPackInstallInputs {
  const DataPackInstallInputs({
    required this.adminKeyPem,
    required this.rootCaPem,
    required this.packsDirPath,
    required this.unpackedRootPath,
    required this.stateFilePath,
  });

  final String adminKeyPem;
  final String rootCaPem;
  final String packsDirPath;
  final String unpackedRootPath;
  final String stateFilePath;
}

/// Resolves install inputs on the **main isolate**. Path resolution
/// (path_provider) and asset reads (rootBundle) both depend on
/// Flutter plugins / the asset bundle, neither of which is available
/// on a background isolate — so this prep stays here. The result is
/// pure strings, ready to ship to `Isolate.run`.
final dataPackInstallInputsProvider =
    FutureProvider<DataPackInstallInputs>((ref) async {
  final adminKey = await rootBundle.loadString(_kAdminKeyAsset);
  final rootCa   = await rootBundle.loadString(_kRootCaAsset);
  final paths    = await DataPackPaths.resolve();
  return DataPackInstallInputs(
    adminKeyPem:      adminKey,
    rootCaPem:        rootCa,
    packsDirPath:     paths.packsDir.path,
    unpackedRootPath: paths.unpackedRoot.path,
    stateFilePath:    paths.stateFile.path,
  );
});

/// Background-isolate entry point. Reconstructs the factory + paths +
/// installer from the plain-string [inputs] and runs the full
/// install. All the heavy lifting — PEM parse, .ddp scan + hash,
/// AES-GCM decrypt, zlib inflate, SHA-256 verify, file writes —
/// happens here, off the UI thread.
///
/// Top-level (not a closure / instance method) so it's a valid
/// `Isolate.run` body. `dpLog` still works from a background
/// isolate — debugPrint falls through to `print`, which the engine
/// merges into the process log stream.
Future<List<DataPackInstallOutcome>> _installOnIsolate(
    DataPackInstallInputs inputs) async {
  final factory = DataUnpackFactory(
    adminKeyPem: inputs.adminKeyPem,
    rootCaPem:   inputs.rootCaPem,
  );
  final paths = DataPackPaths(
    packsDir:     Directory(inputs.packsDirPath),
    unpackedRoot: Directory(inputs.unpackedRootPath),
    stateFile:    File(inputs.stateFilePath),
  );
  final installer = DataPackInstaller(factory: factory, paths: paths);
  return installer.installPending();
}

/// Runs `installPending()` on a background isolate. Read this from a
/// startup screen with `ref.watch(...)` to render progress / error
/// states — the UI thread stays free the whole time the isolate
/// crunches, so spinners animate and there's no ANR.
final installPendingDataPacksProvider =
    FutureProvider.autoDispose<List<DataPackInstallOutcome>>((ref) async {
  final inputs = await ref.watch(dataPackInstallInputsProvider.future);
  dpLog('provider: spawning background isolate for install pass');
  final outcomes =
      await Isolate.run(() => _installOnIsolate(inputs));
  dpLog('provider: background isolate finished — '
      '${outcomes.length} pack(s) processed');
  return outcomes;
});
