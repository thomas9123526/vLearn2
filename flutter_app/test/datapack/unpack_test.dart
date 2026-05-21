// End-to-end test for the .ddp unpacker.
//
// Drives `DataManage.exe pack` to produce a real signed + encrypted
// .ddp from a temp source directory, then runs `DataUnpackFactory`
// on the result and asserts every file came back byte-identical.
//
// Skips itself cleanly if DataManage.exe or the alice CA artefacts
// aren't on disk (so the test passes on a clean clone before the
// admin has run Stage 5 / built DataManage).

@TestOn('vm')  // dart:io + Process — desktop only.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_app/core/datapack/datapack_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // `flutter test` runs with cwd == flutter_app/, so the datamanage
  // sibling project is one level up.
  const repoRel = '..';
  const dmExe    = '$repoRel/datamanage/build-x64/bin/DataManage.exe';
  const aliceCrt = '$repoRel/datamanage/ca/issued/admins/alice/admin.crt';
  const aliceKey = '$repoRel/datamanage/ca/issued/admins/alice/admin.key';
  const rootCrt  = '$repoRel/datamanage/ca/issued/root/root_ca.crt';

  final precondsOk = File(dmExe).existsSync()
      && File(aliceCrt).existsSync()
      && File(aliceKey).existsSync()
      && File(rootCrt).existsSync();

  test('round-trip: pack via DataManage.exe → unpack via DataUnpackFactory',
       () async {
    if (!precondsOk) {
      // ignore: avoid_print
      print('SKIP — DataManage.exe or alice CA files missing\n'
            '       dmExe=${File(dmExe).existsSync()}\n'
            '       aliceCrt=${File(aliceCrt).existsSync()}\n'
            '       aliceKey=${File(aliceKey).existsSync()}\n'
            '       rootCrt=${File(rootCrt).existsSync()}');
      return;
    }

    final tmp = await Directory.systemTemp.createTemp('dm_unpack_test_');
    addTearDown(() async {
      try { await tmp.delete(recursive: true); } catch (_) {}
    });

    final srcDir    = Directory('${tmp.path}/src')..createSync();
    final outDir    = Directory('${tmp.path}/pack_out')..createSync();
    final unpackDir = Directory('${tmp.path}/unpacked')..createSync();

    // Two files with deterministic content.
    final helloBytes = utf8.encode('hello world\n');
    final zerosBytes = Uint8List(4096); // all zeros — compresses dramatically
    await File('${srcDir.path}/hello.txt').writeAsBytes(helloBytes);
    await File('${srcDir.path}/zeros.bin').writeAsBytes(zerosBytes);

    final config = {
      'version': 1,
      'pack_mode': {'compress': 'zlib', 'encrypt': 'aes-256-gcm'},
      'signing': {
        'cert_path': _fwd(File(aliceCrt).absolute.path),
        'key_path':  _fwd(File(aliceKey).absolute.path),
      },
      'bundles': [
        {
          'name': 'roundtrip',
          'source_dir': _fwd(srcDir.absolute.path),
          'out_folder': 'rt',
        },
      ],
      'output_dir': _fwd(outDir.absolute.path),
    };
    final configPath = '${tmp.path}/config.json';
    await File(configPath).writeAsString(jsonEncode(config));

    final pack = await Process.run(dmExe, ['pack', '--config', configPath]);
    expect(pack.exitCode, 0,
        reason: 'DataManage.exe failed.\nstderr:\n${pack.stderr}\n'
                'stdout:\n${pack.stdout}');

    final packPath = '${outDir.path}/roundtrip.ddp';
    expect(File(packPath).existsSync(), isTrue,
        reason: 'expected .ddp at $packPath');

    final factory = DataUnpackFactory(
      adminKeyPem: await File(aliceKey).readAsString(),
      rootCaPem:   await File(rootCrt).readAsString(),
    );
    final result = await factory.unpack(
      packPath: packPath,
      outRoot:  unpackDir.path,
    );

    expect(result.bundleName, 'roundtrip');
    expect(result.files.length, 2);

    final helloOut = File('${unpackDir.path}/rt/hello.txt');
    final zerosOut = File('${unpackDir.path}/rt/zeros.bin');
    expect(helloOut.existsSync(), isTrue);
    expect(zerosOut.existsSync(), isTrue);
    expect(await helloOut.readAsBytes(), helloBytes);
    expect(await zerosOut.readAsBytes(), zerosBytes);
  });

  test('tamper detection: byte-flip in manifest must fail signature check',
       () async {
    if (!precondsOk) return;

    final tmp = await Directory.systemTemp.createTemp('dm_tamper_test_');
    addTearDown(() async {
      try { await tmp.delete(recursive: true); } catch (_) {}
    });

    final srcDir    = Directory('${tmp.path}/src')..createSync();
    final outDir    = Directory('${tmp.path}/pack_out')..createSync();
    final unpackDir = Directory('${tmp.path}/unpacked')..createSync();
    await File('${srcDir.path}/a.txt').writeAsString('A');

    final config = {
      'version': 1,
      'pack_mode': {'compress': 'zlib', 'encrypt': 'aes-256-gcm'},
      'signing': {
        'cert_path': _fwd(File(aliceCrt).absolute.path),
        'key_path':  _fwd(File(aliceKey).absolute.path),
      },
      'bundles': [
        {'name': 'tamper',
         'source_dir': _fwd(srcDir.absolute.path),
         'out_folder': 'tt'},
      ],
      'output_dir': _fwd(outDir.absolute.path),
    };
    final configPath = '${tmp.path}/config.json';
    await File(configPath).writeAsString(jsonEncode(config));
    final pack = await Process.run(dmExe, ['pack', '--config', configPath]);
    expect(pack.exitCode, 0);

    final packPath = '${outDir.path}/tamper.ddp';
    final pristine = Uint8List.fromList(await File(packPath).readAsBytes());
    // Flip one byte inside the manifest region (offset 64 = start of
    // manifest section in standard packs — bump 10 bytes in to land
    // somewhere inside a key/value pair).
    final mutated = Uint8List.fromList(pristine);
    mutated[74] ^= 0xFF;
    final mutatedPath = '${tmp.path}/mutated.ddp';
    await File(mutatedPath).writeAsBytes(mutated);

    final factory = DataUnpackFactory(
      adminKeyPem: await File(aliceKey).readAsString(),
      rootCaPem:   await File(rootCrt).readAsString(),
    );
    await expectLater(
      factory.unpack(packPath: mutatedPath, outRoot: unpackDir.path),
      throwsA(isA<Exception>()),
      reason: 'tampered .ddp must be rejected',
    );
  });
}

/// Normalise a Windows path to forward slashes — DataManage's
/// config.json schema accepts both but forward slashes round-trip
/// through JSON without escaping.
String _fwd(String path) => path.replaceAll(r'\', '/');
