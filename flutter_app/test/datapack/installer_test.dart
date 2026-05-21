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

    // Updated .ddp: rewrite pack_a with different content, same name.
    await File('${packsDir.path}/pack_a.ddp').delete();
    await _pack(
      dmExe: dmExe, tmp: tmp.path, name: 'pack_a',
      sourceFiles: {'a.txt': 'AAA_v2'},
      aliceCrt: aliceCrt, aliceKey: aliceKey,
      outDir: packsDir.path,
    );

    final third = await installer.installPending();
    final updated = third.firstWhere((o) =>
        o.packPath.endsWith('pack_a.ddp'));
    expect(updated.status, DataPackInstallStatus.installed,
        reason: 'updated .ddp triggers re-install');
    final stillCached = third.firstWhere((o) =>
        o.packPath.endsWith('pack_b.ddp'));
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

    // Write a bogus .ddp — wrong magic.
    await File('${packsDir.path}/bogus.ddp').writeAsBytes(
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
}

Future<void> _pack({
  required String dmExe,
  required String tmp,
  required String name,
  required Map<String, String> sourceFiles,
  required String aliceCrt,
  required String aliceKey,
  required String outDir,
}) async {
  final srcDir = Directory('$tmp/src_$name');
  if (srcDir.existsSync()) srcDir.deleteSync(recursive: true);
  srcDir.createSync(recursive: true);
  for (final entry in sourceFiles.entries) {
    final f = File('${srcDir.path}/${entry.key}');
    f.parent.createSync(recursive: true);
    await f.writeAsString(entry.value);
  }

  final config = {
    'version': 1,
    'pack_mode': {'compress': 'zlib', 'encrypt': 'aes-256-gcm'},
    'signing': {
      'cert_path': File(aliceCrt).absolute.path.replaceAll(r'\', '/'),
      'key_path':  File(aliceKey).absolute.path.replaceAll(r'\', '/'),
    },
    'bundles': [
      {
        'name': name,
        'source_dir': srcDir.absolute.path.replaceAll(r'\', '/'),
        'out_folder': name,
      },
    ],
    'output_dir': Directory(outDir).absolute.path.replaceAll(r'\', '/'),
  };
  final configPath = '$tmp/config_$name.json';
  await File(configPath).writeAsString(jsonEncode(config));

  final result = await Process.run(dmExe, ['pack', '--config', configPath]);
  if (result.exitCode != 0) {
    throw StateError('DataManage.exe failed for $name:\n${result.stderr}');
  }
}
