// Public API for unpacking a DataManage `.ddp` bundle.
//
//   final factory = DataUnpackFactory(
//     adminKeyPem: await rootBundle.loadString('assets/datamanage/admin.key'),
//     rootCaPem:   await rootBundle.loadString('assets/datamanage/root_ca.crt'),
//   );
//   final result = await factory.unpack(
//     packPath: '/sdcard/DataManage/out_font.ddp',
//     outRoot:  (await getApplicationSupportDirectory()).path,
//   );
//
// Internally walks the same pipeline as `datamanage/src/packer.cpp`
// in reverse: parse header → parse manifest → verify cert chain →
// verify signature → derive AES key (if encrypted) → for each blob:
// decrypt → decompress → SHA-256 verify → write to disk.

import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'datapack_cert.dart';
import 'datapack_crypto.dart';
import 'datapack_format.dart';
import 'datapack_manifest.dart';

class UnpackedFile {
  UnpackedFile(this.path, this.sizeBytes);
  final String path;
  final int sizeBytes;
}

class UnpackResult {
  UnpackResult(this.bundleName, this.files);
  final String bundleName;
  final List<UnpackedFile> files;
}

class DataUnpackFactory {
  DataUnpackFactory({
    required String adminKeyPem,
    required String rootCaPem,
  })  : _adminPriv = parsePemEcPrivateKey(adminKeyPem),
        _rootCa    = parsePemCert(rootCaPem);

  final BigInt _adminPriv;
  final ParsedCert _rootCa;

  /// Read [packPath], verify everything, and write each file into
  /// `outRoot/<file.outFolder>/<basename(file.relPath)>`. Throws on
  /// any verification failure (bad magic, bad chain, bad signature,
  /// bad hash) or I/O error.
  Future<UnpackResult> unpack({
    required String packPath,
    required String outRoot,
  }) async {
    final pack = Uint8List.fromList(await File(packPath).readAsBytes());

    // 1) Header.
    final hdr = DataPackHeader.parse(pack);

    // 2) Manifest.
    final manifestJson = String.fromCharCodes(Uint8List.sublistView(
      pack, hdr.manifestOffset, hdr.manifestOffset + hdr.manifestLen,
    ));
    final manifest = DataPackManifest.parse(manifestJson);

    // 3) Cert + chain validation. Anything without a cert + sig is
    //    refused — debug Stage-3 packs only work in dev tools.
    if (!hdr.isSigned) {
      throw const FormatException('.ddp is unsigned (refused in production)');
    }
    final adminCert = parseDerCert(Uint8List.sublistView(
      pack, hdr.certOffset, hdr.certOffset + hdr.certLen,
    ));
    if (!verifyCertSignedBy(adminCert, _rootCa)) {
      throw const FormatException(
          '.ddp admin cert does not chain to the pinned root CA');
    }

    // 4) Verify the pack signature. Mirror of the trick in
    //    packer.cpp: re-zero sig_len/sig_offset before hashing.
    final digest = _digestOverPack(pack, hdr);
    final sigBytes = Uint8List.sublistView(
      pack, hdr.sigOffset, hdr.sigOffset + hdr.sigLen,
    );
    final sigOk = verifyEcdsaP256(
      pubKey: adminCert.publicKeyPoint,
      messageDigest: digest,
      signatureDer: Uint8List.fromList(sigBytes),
    );
    if (!sigOk) {
      throw const FormatException(
          '.ddp signature does not verify against admin cert pubkey');
    }

    // 5) Derive AES key if the pack is encrypted.
    Uint8List? aesKey;
    if (hdr.isEncrypted) {
      if (manifest.ephemeralPubHex.length != 66) {
        throw const FormatException(
            'manifest.ephemeral_pub_hex must be 66 chars for P-256');
      }
      final ephBytes = _hexToBytes(manifest.ephemeralPubHex);
      final ephPoint = decompressP256Point(ephBytes);
      final shared = ecdhSharedSecret(_adminPriv, ephPoint);
      aesKey = hkdfSha256(
        ikm: shared,
        salt: Uint8List.fromList(kHkdfSalt.codeUnits),
        info: Uint8List.fromList(kHkdfInfo.codeUnits),
      );
    }

    // 6) Walk the manifest, decode + write each file.
    final outDir = Directory(outRoot);
    if (!await outDir.exists()) await outDir.create(recursive: true);

    final results = <UnpackedFile>[];
    for (final mf in manifest.files) {
      final stored = Uint8List.sublistView(
        pack, hdr.dataOffset + mf.offset,
              hdr.dataOffset + mf.offset + mf.storedSize,
      );

      Uint8List bytes = stored;
      if (aesKey != null) {
        bytes = aesGcmDecrypt(key: aesKey, blob: bytes);
      }
      if (hdr.isCompressed) {
        // archive's ZLibDecoder handles RFC 1950 zlib streams
        // (which is what encrypt.cpp::deflateZlib produces).
        bytes = Uint8List.fromList(const ZLibDecoder().decodeBytes(bytes));
      }

      if (bytes.length != mf.size) {
        throw FormatException(
            'decoded size ${bytes.length} != manifest size ${mf.size} '
            'for ${mf.relPath}');
      }
      final actualHash = _toHex(sha256Bytes(bytes));
      if (actualHash != mf.sha256Hex) {
        throw FormatException(
            'SHA-256 mismatch for ${mf.relPath}: '
            'expected ${mf.sha256Hex}, got $actualHash');
      }

      final outPath = _safeJoin(outRoot, mf.outFolder, mf.relPath);
      await Directory(_dirOf(outPath)).create(recursive: true);
      await File(outPath).writeAsBytes(bytes, flush: true);
      results.add(UnpackedFile(outPath, bytes.length));
    }
    return UnpackResult(manifest.bundleName, results);
  }

  // Build the hash input that the C++ signer hashed:
  //   header_with_sig_zeroed ‖ manifest ‖ data ‖ cert
  Uint8List _digestOverPack(Uint8List pack, DataPackHeader hdr) {
    final hdrBytes = hdr.toBytesForSigVerification();
    final builder = BytesBuilder(copy: false)
      ..add(hdrBytes)
      ..add(Uint8List.sublistView(
        pack, hdr.manifestOffset, hdr.manifestOffset + hdr.manifestLen))
      ..add(Uint8List.sublistView(
        pack, hdr.dataOffset, hdr.dataOffset + hdr.dataLen))
      ..add(Uint8List.sublistView(
        pack, hdr.certOffset, hdr.certOffset + hdr.certLen));
    return sha256Bytes(builder.toBytes());
  }
}

Uint8List _hexToBytes(String hex) {
  if (hex.length.isOdd) {
    throw FormatException('hex length must be even: $hex');
  }
  final out = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < out.length; ++i) {
    out[i] = int.parse(hex.substring(2 * i, 2 * i + 2), radix: 16);
  }
  return out;
}

String _toHex(Uint8List bytes) {
  final b = StringBuffer();
  for (final x in bytes) {
    b.write(x.toRadixString(16).padLeft(2, '0'));
  }
  return b.toString();
}

String _safeJoin(String root, String outFolder, String relPath) {
  // Manifest parsing already rejected absolute paths + `..` segments.
  // Defence in depth: normalise + check the joined path actually
  // stays under root.
  final baseName = relPath.split(RegExp(r'[/\\]')).last;
  final folderParts = outFolder.split(RegExp(r'[/\\]'));
  final joined = [
    root,
    ...folderParts.where((s) => s.isNotEmpty),
    baseName,
  ].join(Platform.pathSeparator);
  // Reject if the resulting path doesn't start with root (after
  // canonicalisation). Symlinks aside, this catches any escape.
  final canonRoot = Directory(root).absolute.path;
  final canonOut  = File(joined).absolute.path;
  if (!canonOut.startsWith(canonRoot)) {
    throw FormatException(
        'unpack: refused to write outside root\n'
        '  root: $canonRoot\n  target: $canonOut');
  }
  return joined;
}

String _dirOf(String path) {
  final sep = Platform.pathSeparator;
  final i = path.lastIndexOf(sep);
  return i < 0 ? '.' : path.substring(0, i);
}
