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
import 'datapack_log.dart';
import 'datapack_manifest.dart';

class UnpackedFile {
  UnpackedFile(this.path, this.sizeBytes);
  final String path;
  final int sizeBytes;
}

/// Read just the header + manifest of a `.dat` — no signature
/// verification, no decrypt, no file writes. Cheap: reads only the
/// 64-byte header plus the (plaintext) manifest section, never the
/// multi-MB data section.
///
/// Used by the installer to learn a pack's `group` / `unpackPhase`
/// *before* deciding whether to unpack it this phase. The manifest is
/// routing metadata only — the real security gate (cert chain +
/// signature) still runs inside [DataUnpackFactory.unpack].
Future<DataPackManifest> readPackManifest(String packPath) async {
  final raf = await File(packPath).open();
  try {
    final headerBytes = await raf.read(64);
    if (headerBytes.length < 64) {
      throw const FormatException('.dat too small to hold header');
    }
    final hdr = DataPackHeader.parse(Uint8List.fromList(headerBytes));
    await raf.setPosition(hdr.manifestOffset);
    final manifestBytes = await raf.read(hdr.manifestLen);
    if (manifestBytes.length < hdr.manifestLen) {
      throw const FormatException('.dat truncated — manifest section short');
    }
    return DataPackManifest.parse(
        String.fromCharCodes(manifestBytes));
  } finally {
    await raf.close();
  }
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
  /// [onFileProgress] (optional) fires once per file as the data
  /// section is decoded — `(filesDone, filesTotal)`. Used by the
  /// on-demand group unpack to drive a 0–100% progress bar.
  Future<UnpackResult> unpack({
    required String packPath,
    required String outRoot,
    void Function(int filesDone, int filesTotal)? onFileProgress,
  }) async {
    dpLog('unpack: START $packPath');
    dpLog('unpack:   → output root $outRoot');

    // Streamed: only the section / file blob currently being processed
    // is held in memory. The previous implementation read the WHOLE
    // pack into a Uint8List up-front, which OOM'd on Android for
    // multi-hundred-MB `.dat`s (the user-visible "Out of Memory" on
    // 2.dat).
    final raf = await File(packPath).open();
    try {
      // 1) Header — first 64 bytes.
      final headerBytes = await raf.read(64);
      if (headerBytes.length < 64) {
        throw const FormatException('.dat too small to hold header');
      }
      final hdr = DataPackHeader.parse(headerBytes);
      dpLog('unpack:   [1/6] header OK — version ${hdr.version}, '
          'compressed=${hdr.isCompressed}, encrypted=${hdr.isEncrypted}, '
          'signed=${hdr.isSigned}');

      // 2) Manifest section (always small — JSON text).
      await raf.setPosition(hdr.manifestOffset);
      final manifestBytes = await raf.read(hdr.manifestLen);
      if (manifestBytes.length < hdr.manifestLen) {
        throw const FormatException('.dat truncated — manifest section short');
      }
      final manifest =
          DataPackManifest.parse(String.fromCharCodes(manifestBytes));
      dpLog('unpack:   [2/6] manifest OK — bundle "${manifest.bundleName}", '
          '${manifest.files.length} file(s), '
          'compression=${manifest.compression}, '
          'encryption=${manifest.encryption}');

      // 3) Cert + chain validation. Anything without a cert + sig is
      //    refused — debug Stage-3 packs only work in dev tools.
      if (!hdr.isSigned) {
        throw const FormatException(
            '.ddp is unsigned (refused in production)');
      }
      await raf.setPosition(hdr.certOffset);
      final certBytes = await raf.read(hdr.certLen);
      if (certBytes.length < hdr.certLen) {
        throw const FormatException('.dat truncated — cert section short');
      }
      final adminCert = parseDerCert(certBytes);
      if (!verifyCertSignedBy(adminCert, _rootCa)) {
        throw const FormatException(
            '.ddp admin cert does not chain to the pinned root CA');
      }
      dpLog('unpack:   [3/6] cert chain OK — admin cert chains to pinned root');

      // 4) Verify the pack signature. Hash is computed over
      //      header_with_sig_zeroed ‖ manifest ‖ data ‖ cert
      //    — same as packer.cpp. The data section is streamed in 64 KB
      //    chunks straight from the file; nothing larger than one chunk
      //    is held for hashing.
      final digest =
          await _streamedDigest(raf, hdr, manifestBytes, certBytes);
      await raf.setPosition(hdr.sigOffset);
      final sigBytes = await raf.read(hdr.sigLen);
      if (sigBytes.length < hdr.sigLen) {
        throw const FormatException('.dat truncated — signature section short');
      }
      final sigOk = verifyEcdsaP256(
        pubKey: adminCert.publicKeyPoint,
        messageDigest: digest,
        signatureDer: sigBytes,
      );
      if (!sigOk) {
        throw const FormatException(
            '.ddp signature does not verify against admin cert pubkey');
      }
      dpLog('unpack:   [4/6] signature OK — ECDSA verifies against admin cert');

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
        dpLog('unpack:   [5/6] AES-256 key derived via ECDH + HKDF');
      } else {
        dpLog('unpack:   [5/6] pack not encrypted — no key derivation');
      }

      // 6) Walk the manifest one blob at a time. Per-iteration peak
      //    memory is bounded by ONE file's encrypted + decrypted +
      //    decompressed bytes — the rest of the pack stays on disk.
      dpLog('unpack:   [6/6] decoding ${manifest.files.length} file(s)…');
      final outDir = Directory(outRoot);
      if (!await outDir.exists()) await outDir.create(recursive: true);

      final results = <UnpackedFile>[];
      final total = manifest.files.length;
      var index = 0;
      for (final mf in manifest.files) {
        ++index;
        final steps = <String>[];

        await raf.setPosition(hdr.dataOffset + mf.offset);
        Uint8List bytes = await raf.read(mf.storedSize);
        if (bytes.length < mf.storedSize) {
          throw FormatException(
              '.dat truncated — short read on ${mf.relPath} '
              '(${bytes.length} of ${mf.storedSize}B)');
        }
        steps.add('read ${mf.storedSize}B');

        if (aesKey != null) {
          bytes = aesGcmDecrypt(key: aesKey, blob: bytes);
          steps.add('decrypt');
        }
        if (hdr.isCompressed) {
          // archive's ZLibDecoder handles RFC 1950 zlib streams
          // (which is what encrypt.cpp::deflateZlib produces).
          bytes = Uint8List.fromList(const ZLibDecoder().decodeBytes(bytes));
          steps.add('inflate→${bytes.length}B');
        }

        if (bytes.length != mf.size) {
          dpLog('unpack:   [$index/$total] FAIL ${mf.relPath} — '
              'decoded ${bytes.length}B != manifest ${mf.size}B');
          throw FormatException(
              'decoded size ${bytes.length} != manifest size ${mf.size} '
              'for ${mf.relPath}');
        }
        final actualHash = _toHex(sha256Bytes(bytes));
        if (actualHash != mf.sha256Hex) {
          dpLog('unpack:   [$index/$total] FAIL ${mf.relPath} — '
              'SHA-256 mismatch');
          throw FormatException(
              'SHA-256 mismatch for ${mf.relPath}: '
              'expected ${mf.sha256Hex}, got $actualHash');
        }
        steps.add('sha256 OK');

        final outPath = _safeJoin(outRoot, mf.outFolder, mf.relPath);
        await Directory(_dirOf(outPath)).create(recursive: true);
        await File(outPath).writeAsBytes(bytes, flush: true);
        results.add(UnpackedFile(outPath, bytes.length));
        dpLog('unpack:   [$index/$total] ${mf.relPath}  '
            '(${steps.join(" → ")})  →  $outPath');
        onFileProgress?.call(index, total);
      }
      dpLog('unpack: DONE "${manifest.bundleName}" — $total file(s) written '
          'under $outRoot');
      return UnpackResult(manifest.bundleName, results);
    } finally {
      await raf.close();
    }
  }

  /// Streaming SHA-256 over the signed prefix
  ///   header_with_sig_zeroed ‖ manifest ‖ data ‖ cert
  /// — the same byte sequence packer.cpp signed. Manifest and cert are
  /// already in memory; the data section (the only large piece) is
  /// read from [raf] in 64 KB chunks so nothing the size of the pack
  /// is ever materialised.
  Future<Uint8List> _streamedDigest(
    RandomAccessFile raf,
    DataPackHeader hdr,
    Uint8List manifestBytes,
    Uint8List certBytes,
  ) async {
    final st = Sha256Streamer();
    st.add(hdr.toBytesForSigVerification());
    st.add(manifestBytes);
    await raf.setPosition(hdr.dataOffset);
    var remaining = hdr.dataLen;
    const chunkSize = 64 * 1024;
    while (remaining > 0) {
      final n = remaining < chunkSize ? remaining : chunkSize;
      final buf = await raf.read(n);
      if (buf.length != n) {
        throw const FormatException(
            '.dat truncated — short read in data section while hashing');
      }
      st.add(buf);
      remaining -= n;
    }
    st.add(certBytes);
    return st.finalize();
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
  // Final location is  <root>/<outFolder>/<relPath>  with the FULL
  // directory structure of relPath preserved — relPath carries the
  // path the file had inside the packed source dir (e.g.
  // "encoder/model.onnx"), so we keep every segment, not just the
  // basename. Manifest parsing already rejected absolute paths and
  // `..` segments in both fields; splitting on separators here is a
  // belt-and-braces normalisation before the under-root check.
  final folderParts =
      outFolder.split(RegExp(r'[/\\]')).where((s) => s.isNotEmpty);
  final relParts =
      relPath.split(RegExp(r'[/\\]')).where((s) => s.isNotEmpty);
  final joined = [
    root,
    ...folderParts,
    ...relParts,
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
