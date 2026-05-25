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
  // Splash pass: installPending defaults to phase "splash", so only
  // packs tagged unpack_phase == "splash" are unpacked here. Packs
  // tagged "on-demand" come back `deferred` and are unpacked later by
  // the feature that needs them (Stage C).
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

// ─── on-demand group unpacking (Stage C) ──────────────────────────────────

/// Lifecycle phase of an on-demand group unpack.
enum DataPackGroupPhase { idle, running, done, error }

/// UI-facing state for [DataPackGroupController]. A progress view
/// renders straight off `fraction` + `status`.
class DataPackGroupState {
  const DataPackGroupState({
    required this.phase,
    this.group = '',
    this.fraction = 0.0,
    this.status = '',
    this.error,
    this.failedPacks = const [],
  });

  final DataPackGroupPhase phase;
  final String group;
  final double fraction;   // 0.0 – 1.0
  final String status;     // human-readable line
  final String? error;
  final List<String> failedPacks;  // "pack.dat: reason" lines

  bool get isRunning => phase == DataPackGroupPhase.running;
  bool get isDone    => phase == DataPackGroupPhase.done;
  bool get isError   => phase == DataPackGroupPhase.error;
}

// ── isolate plumbing ──

/// Args handed to the group-unpack worker isolate. Every field is
/// sendable (SendPort, all-string inputs, plain String).
class _GroupWorkerArgs {
  _GroupWorkerArgs(this.sendPort, this.inputs, this.group);
  final SendPort sendPort;
  final DataPackInstallInputs inputs;
  final String group;
}

/// Worker→controller messages over the isolate's SendPort.
class _GroupProgress {
  _GroupProgress(this.fraction, this.status);
  final double fraction;
  final String status;
}

class _GroupDone {
  _GroupDone(this.outcomes);
  final List<DataPackInstallOutcome> outcomes;
}

class _GroupError {
  _GroupError(this.message);
  final String message;
}

/// Background-isolate entry point for an on-demand group unpack.
/// Reconstructs the installer from the plain-string inputs and runs
/// `installGroup`, streaming per-file progress back over [args.sendPort].
Future<void> _groupWorker(_GroupWorkerArgs args) async {
  final send = args.sendPort;
  try {
    final factory = DataUnpackFactory(
      adminKeyPem: args.inputs.adminKeyPem,
      rootCaPem:   args.inputs.rootCaPem,
    );
    final paths = DataPackPaths(
      packsDir:     Directory(args.inputs.packsDirPath),
      unpackedRoot: Directory(args.inputs.unpackedRootPath),
      stateFile:    File(args.inputs.stateFilePath),
    );
    final installer = DataPackInstaller(factory: factory, paths: paths);
    final outcomes = await installer.installGroup(
      args.group,
      onProgress: (fraction, status) =>
          send.send(_GroupProgress(fraction, status)),
    );
    send.send(_GroupDone(outcomes));
  } catch (e) {
    send.send(_GroupError(e.toString()));
  }
}

/// Drives on-demand unpacking of a feature group (e.g. "speech").
///
/// A feature calls `ref.read(dataPackGroupControllerProvider.notifier)
/// .ensureGroup("speech")` the first time it needs that data, and
/// `ref.watch(dataPackGroupControllerProvider)` to render progress.
/// The unpack runs on a background isolate — the UI thread stays free,
/// no ANR — with per-file progress streamed back into the state.
class DataPackGroupController extends Notifier<DataPackGroupState> {
  @override
  DataPackGroupState build() =>
      const DataPackGroupState(phase: DataPackGroupPhase.idle);

  /// Unpack every not-yet-installed `.dat` in [group]. Idempotent and
  /// cheap when the group is already installed (the worker reports
  /// everything `cached` and finishes near-instantly). Safe to call
  /// again after a failure — finished packs are checkpointed.
  Future<void> ensureGroup(String group) async {
    if (state.isRunning) {
      dpLog('group-controller: ensureGroup("$group") ignored — '
          'a group unpack is already running');
      return;
    }
    state = DataPackGroupState(
      phase: DataPackGroupPhase.running,
      group: group,
      status: 'Starting…',
    );

    final DataPackInstallInputs inputs;
    try {
      inputs = await ref.read(dataPackInstallInputsProvider.future);
    } catch (e) {
      state = DataPackGroupState(
        phase: DataPackGroupPhase.error, group: group,
        error: 'could not resolve datapack inputs: $e');
      return;
    }

    final rp = ReceivePort();
    try {
      await Isolate.spawn(
          _groupWorker, _GroupWorkerArgs(rp.sendPort, inputs, group));
    } catch (e) {
      rp.close();
      state = DataPackGroupState(
        phase: DataPackGroupPhase.error, group: group,
        error: 'could not spawn worker isolate: $e');
      return;
    }

    dpLog('group-controller: isolate spawned for group "$group"');
    await for (final msg in rp) {
      if (msg is _GroupProgress) {
        state = DataPackGroupState(
          phase: DataPackGroupPhase.running, group: group,
          fraction: msg.fraction, status: msg.status);
      } else if (msg is _GroupDone) {
        final failed = msg.outcomes
            .where((o) => o.status == DataPackInstallStatus.failed)
            .map((o) {
          final name = o.packPath.split(RegExp(r'[/\\]')).last;
          return '$name: ${o.error ?? "unknown"}';
        }).toList();
        state = DataPackGroupState(
          phase: failed.isEmpty
              ? DataPackGroupPhase.done
              : DataPackGroupPhase.error,
          group: group,
          fraction: 1.0,
          status: failed.isEmpty ? 'Ready' : 'Completed with errors',
          failedPacks: failed,
          error: failed.isEmpty ? null : failed.join('\n'),
        );
        rp.close();
        break;
      } else if (msg is _GroupError) {
        state = DataPackGroupState(
          phase: DataPackGroupPhase.error, group: group,
          error: msg.message);
        rp.close();
        break;
      }
    }
    dpLog('group-controller: group "$group" finished — '
        'phase ${state.phase.name}');
  }

  /// Reset to idle (e.g. after the UI has shown a `done`/`error`).
  void reset() =>
      state = const DataPackGroupState(phase: DataPackGroupPhase.idle);
}

final dataPackGroupControllerProvider =
    NotifierProvider<DataPackGroupController, DataPackGroupState>(
        DataPackGroupController.new);
