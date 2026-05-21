// Riverpod glue so any part of the app can run the unpacker on
// demand. Usage from a startup screen:
//
//   final outcomes = await ref.read(installPendingDataPacksProvider.future);
//   final installed = outcomes.where((o) => o.status == DataPackInstallStatus.installed);
//   final failed    = outcomes.where((o) => o.status == DataPackInstallStatus.failed);
//
// `dataPackInstallerProvider` resolves paths + reads the admin key
// and root CA out of Flutter assets exactly once per launch.

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'datapack_factory.dart';
import 'datapack_installer.dart';
import 'datapack_paths.dart';

const String _kAdminKeyAsset = 'assets/datamanage/admin.key';
const String _kRootCaAsset   = 'assets/datamanage/root_ca.crt';

/// Lazy-built `DataPackInstaller`. The Future memoises — provider
/// stays alive for the app's lifetime so the heavy parse-PEM /
/// allocate-EC-keys cost runs once.
final dataPackInstallerProvider =
    FutureProvider<DataPackInstaller>((ref) async {
  final adminKey = await rootBundle.loadString(_kAdminKeyAsset);
  final rootCa   = await rootBundle.loadString(_kRootCaAsset);
  final paths    = await DataPackPaths.resolve();
  final factory  = DataUnpackFactory(
    adminKeyPem: adminKey,
    rootCaPem:   rootCa,
  );
  return DataPackInstaller(factory: factory, paths: paths);
});

/// Runs `installPending()` against the resolved installer. Read this
/// from a startup screen with `ref.watch(...)` to render progress /
/// error states. Re-reading invalidates the cache and reruns; in
/// practice you only want this once per launch.
final installPendingDataPacksProvider =
    FutureProvider.autoDispose<List<DataPackInstallOutcome>>((ref) async {
  final installer = await ref.watch(dataPackInstallerProvider.future);
  return installer.installPending();
});
