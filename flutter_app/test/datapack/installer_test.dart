// Stage-9 test: idempotent install + cache-on-second-run.
//
// Builds two real .ddp files via DataManage.exe into a temp
// "external storage" dir, then runs the installer twice:
//   1st run: both packs report `installed`
//   2nd run: both report `cached` (no re-unpack)
// Plus a "updated .ddp" case: same filename, different content
// (different SHA-256) -> reports `installed` again.

@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/core/datapack/datapack_factory.dart';
import 'package:flutter_app/core/datapack/datapack_installer.dart';
import 'package:flutter_app/core/datapack/datapack_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const repoRel = '..';
  const dmExe    = '$repoRel/datamanage/build-x64/bin/DataManage.exe';
  const aliceCrt = '$repoRel/datamanage/ca/issued/admins/alice/admin.crt';
  const aliceKey = '$repoRel/datamanage/ca/issued/admins/alice/admin.key';
  const rootCrt  = '$repoRel/datamanage/ca/issued/root/root_ca.crt';

  final precondsOk = File(dmExe).existsSync()
      && File(aliceCrt).existsSync()
      && File(aliceKey).existsSync()
      && File(rootCrt).existsSync();

  test('installer: first run installs, second run caches', () async {
    if (!precondsOk) return;

    final tmp = await Directory.systemTemp.createTemp('dm_install_test_');
    addTearDown(() async {
      try { await tmp.delete(recursive: true); } catch (_) {}
    });

    // Lay out the temp "external storage" world.
    final packsDir    = Directory('${tmp.path}/external_packs')..createSync();
    final unpackRoot  = Directory('${tmp.path}/unpacked')..createSync();
    final stateFile   = File('${tmp.path}/datapack_state.json');

    final paths = DataPackPaths(
      packsDir:     packsDir,
      unpackedRoot: unpackRoot,
      stateFile:    stateFile,
    );

    // Build two .ddp files via DataManage.exe.
    await _pack(
      dmExe: dmExe, tmp: tmp.path, name: 'pack_a',
      sourceFiles: {'a.txt': 'AAA'},
      aliceCrt: aliceCrt, aliceKey: aliceKey,
      outDir: packsDir.path,
    );
    await _pack(
      dmExe: dmExe, tmp: tmp.path, name: 'pack_b',
      sourceFiles: {'b.txt': 'BBB', 'sub/c.txt': 'CCC'},
      aliceCrt: aliceCrt, aliceKey: aliceKey,
      outDir: packsDir.path,
    );

    final factory = DataUnpackFactory(
      adminKeyPem: await File(aliceKey).readAsString(),
      rootCaPem:   await File(rootCrt).readAsString(),
    );
    final installer = DataPackInstaller(factory: factory, paths: paths);

    // 1st run.
    final first = await installer.installPending();
    expect(first.length, 2);
    expect(
      first.map((o) => o.status).toSet(),
      {DataPackInstallStatus.installed},
      reason: 'first run installs both packs',
    );
    expect(first.firstWhere((o) => o.bundleName == 'pack_a')
              .unpackedFileCount, 1);
    expect(first.firstWhere((o) => o.bundleName == 'pack_b')
              .unpackedFileCount, 2);
    expect(stateFile.existsSync(), isTrue,
        reason: 'state file written after first run');

    // 2nd run — nothing changed on disk, both should be cached.
    final second = await installer.installPending();
    expect(
      second.map((o) => o.status).toSet(),
      {DataPackInstallStatus.cached},
      reason: 'second run hits cache for both packs',
    );

    // Updated pack: rewrite pack_a with different content, same name.
    await File('${packsDir.path}/pack_a.dat').delete();
    await _pack(
      dmExe: dmExe, tmp: tmp.path, name: 'pack_a',
      sourceFiles: {'a.txt': 'AAA_v2'},
      aliceCrt: aliceCrt, aliceKey: aliceKey,
      outDir: packsDir.path,
    );

    final third = await installer.installPending();
    final updated = third.firstWhere((o) =>
        o.packPath.endsWith('pack_a.dat'));
    expect(updated.status, DataPackInstallStatus.installed,
        reason: 'updated pack triggers re-install');
    final stillCached = third.firstWhere((o) =>
        o.packPath.endsWith('pack_b.dat'));
    expect(stillCached.status, DataPackInstallStatus.cached);
  });

  test('installer: failure path produces a `failed` outcome', () async {
    if (!precondsOk) return;

    final tmp = await Directory.systemTemp.createTemp('dm_install_fail_');
    addTearDown(() async {
      try { await tmp.delete(recursive: true); } catch (_) {}
    });

    final packsDir   = Directory('${tmp.path}/packs')..createSync();
    final unpackRoot = Directory('${tmp.path}/unpacked')..createSync();
    final stateFile  = File('${tmp.path}/state.json');

    // Write a bogus .dat pack — wrong magic.
    await File('${packsDir.path}/bogus.dat').writeAsBytes(
        List.filled(128, 0));

    final paths = DataPackPaths(
      packsDir: packsDir, unpackedRoot: unpackRoot, stateFile: stateFile,
    );
    final factory = DataUnpackFactory(
      adminKeyPem: await File(aliceKey).readAsString(),
      rootCaPem:   await File(rootCrt).readAsString(),
    );
    final installer = DataPackInstaller(factory: factory, paths: paths);

    final outcomes = await installer.installPending();
    expect(outcomes.length, 1);
    expect(outcomes.single.status, DataPackInstallStatus.failed);
    expect(outcomes.single.error, isNotNull);
  });

  test('installer: phase filter — splash installs, on-demand deferred',
      () async {
    if (!precondsOk) return;

    final tmp = await Directory.systemTemp.createTemp('dm_install_phase_');
    addTearDown(() async {
      try { await tmp.delete(recursive: true); } catch (_) {}
    });

    final packsDir   = Directory('${tmp.path}/packs')..createSync();
    final unpackRoot = Directory('${tmp.path}/unpacked')..createSync();
    final stateFile  = File('${tmp.path}/state.json');

    // Two packs: one tagged splash, one tagged on-demand.
    await _pack(
      dmExe: dmExe, tmp: tmp.path, name: 'core_fonts',
      sourceFiles: {'a.txt': 'AAA'},
      aliceCrt: aliceCrt, aliceKey: aliceKey, outDir: packsDir.path,
      group: 'core', unpackPhase: 'splash',
    );
    await _pack(
      dmExe: dmExe, tmp: tmp.path, name: 'speech_models',
      sourceFiles: {'m.txt': 'MMM'},
      aliceCrt: aliceCrt, aliceKey: aliceKey, outDir: packsDir.path,
      group: 'speech', unpackPhase: 'on-demand',
    );

    final paths = DataPackPaths(
      packsDir: packsDir, unpackedRoot: unpackRoot, stateFile: stateFile,
    );
    final factory = DataUnpackFactory(
      adminKeyPem: await File(aliceKey).readAsString(),
      rootCaPem:   await File(rootCrt).readAsString(),
    );
    final installer = DataPackInstaller(factory: factory, paths: paths);

    // Splash pass — core_fonts installs, speech_models is deferred.
    final splash = await installer.installPending();  // default phase
    final coreOutcome = splash.firstWhere(
        (o) => o.packPath.endsWith('core_fonts.dat'));
    final speechOutcome = splash.firstWhere(
        (o) => o.packPath.endsWith('speech_models.dat'));
    expect(coreOutcome.status, DataPackInstallStatus.installed,
        reason: 'splash phase: core pack installs');
    expect(speechOutcome.status, DataPackInstallStatus.deferred,
        reason: 'splash phase: on-demand pack is deferred, not installed');

    // On-demand pass — now speech_models installs, core_fonts is the
    // one deferred (already done, but also wrong phase for this pass).
    final onDemand =
        await installer.installPending(phase: 'on-demand');
    final speechNow = onDemand.firstWhere(
        (o) => o.packPath.endsWith('speech_models.dat'));
    expect(speechNow.status, DataPackInstallStatus.installed,
        reason: 'on-demand phase: speech pack installs');
  });

  test('installer: installGroup unpacks only the named group + reports '
      'progress to 100%', () async {
    if (!precondsOk) return;

    final tmp = await Directory.systemTemp.createTemp('dm_install_group_');
    addTearDown(() async {
      try { await tmp.delete(recursive: true); } catch (_) {}
    });

    final packsDir   = Directory('${tmp.path}/packs')..createSync();
    final unpackRoot = Directory('${tmp.path}/unpacked')..createSync();
    final stateFile  = File('${tmp.path}/state.json');

    // A "core" pack and a 2-file "speech" pack.
    await _pack(
      dmExe: dmExe, tmp: tmp.path, name: 'core_pack',
      sourceFiles: {'c.txt': 'C'},
      aliceCrt: aliceCrt, aliceKey: aliceKey, outDir: packsDir.path,
      group: 'core', unpackPhase: 'splash',
    );
    await _pack(
      dmExe: dmExe, tmp: tmp.path, name: 'speech_pack',
      sourceFiles: {'s1.txt': 'S1', 's2.txt': 'S2'},
      aliceCrt: aliceCrt, aliceKey: aliceKey, outDir: packsDir.path,
      group: 'speech', unpackPhase: 'on-demand',
    );

    final paths = DataPackPaths(
      packsDir: packsDir, unpackedRoot: unpackRoot, stateFile: stateFile,
    );
    final factory = DataUnpackFactory(
      adminKeyPem: await File(aliceKey).readAsString(),
      rootCaPem:   await File(rootCrt).readAsString(),
    );
    final installer = DataPackInstaller(factory: factory, paths: paths);

    final fractions = <double>[];
    final outcomes = await installer.installGroup(
      'speech',
      onProgress: (frac, status) => fractions.add(frac),
    );

    // Only the speech pack — core_pack is a different group, untouched.
    expect(outcomes.length, 1,
        reason: 'installGroup returns only the named group\'s packs');
    expect(outcomes.single.bundleName, 'speech_pack');
    expect(outcomes.single.status, DataPackInstallStatus.installed);
    expect(outcomes.single.unpackedFileCount, 2);

    // Progress was reported and reached 100%.
    expect(fractions, isNotEmpty, reason: 'onProgress fired');
    expect(fractions.last, closeTo(1.0, 0.0001),
        reason: 'progress ends at 100%');

    // Second call — the pack is now cached.
    final again = await installer.installGroup('speech');
    expect(again.single.status, DataPackInstallStatus.cached,
        reason: 'group already installed → cached on the next call');
  });
}

Future<void> _pack({
  required String dmExe,
  required String tmp,
  required String name,
  required Map<String, String> sourceFiles,
  required String aliceCrt,
  required String aliceKey,
  required String outDir,
  String? group,
  String? unpackPhase,
}) async {
  final srcDir = Directory('$tmp/src_$name');
  if (srcDir.existsSync()) srcDir.deleteSync(recursive: true);
  srcDir.createSync(recursive: true);
  for (final entry in sourceFiles.entries) {
    final f = File('${srcDir.path}/${entry.key}');
    f.parent.createSync(recursive: true);
    await f.writeAsString(entry.value);
  }

  final bundle = <String, Object?>{
    'name': name,
    'source_dir': srcDir.absolute.path.replaceAll(r'\', '/'),
    'out_folder': name,
  };
  if (group != null) bundle['group'] = group;
  if (unpackPhase != null) bundle['unpack_phase'] = unpackPhase;

  final config = {
    'version': 1,
    'pack_mode': {'compress': 'zlib', 'encrypt': 'aes-256-gcm'},
    'signing': {
      'cert_path': File(aliceCrt).absolute.path.replaceAll(r'\', '/'),
      'key_path':  File(aliceKey).absolute.path.replaceAll(r'\', '/'),
    },
    'bundles': [bundle],
    'output_dir': Directory(outDir).absolute.path.replaceAll(r'\', '/'),
  };
  final configPath = '$tmp/config_$name.json';
  await File(configPath).writeAsString(jsonEncode(config));

  final result = await Process.run(dmExe, ['pack', '--config', configPath]);
  if (result.exitCode != 0) {
    throw StateError('DataManage.exe failed for $name:\n${result.stderr}');
  }
}
