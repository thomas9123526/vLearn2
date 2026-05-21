// Mirror of `datamanage/src/manifest.{h,cpp}` — the JSON manifest
// schema embedded in section [2] of every `.ddp`. Read-only on the
// Flutter side (we never write `.ddp` files).

import 'dart:convert';

class DataPackFile {
  const DataPackFile({
    required this.relPath,
    required this.outFolder,
    required this.size,
    required this.storedSize,
    required this.offset,
    required this.sha256Hex,
  });

  /// Original path inside the source directory at pack time.
  /// e.g. "fonts/Lora-Regular.ttf". Forward-slashes; never absolute;
  /// never contains "..".
  final String relPath;

  /// Where this file should land at unpack time, relative to the
  /// app's data root. The unpacker rejects absolute paths and
  /// `..` segments as a defence-in-depth check (the packer also
  /// rejects them at write time).
  final String outFolder;

  /// Plaintext size in bytes. SHA-256 hash is over this content.
  final int size;

  /// Byte length of the blob as stored on disk. Equals `size` when
  /// the pack is uncompressed + unencrypted; otherwise reflects the
  /// post-transform length:
  ///   compressed only: zlib output length.
  ///   encrypted only:  12 (IV) + plaintext + 16 (tag).
  ///   both:            12 + compressed + 16.
  final int storedSize;

  /// Byte offset inside the data section where this file's blob
  /// starts (NOT a file-absolute offset).
  final int offset;

  /// Lowercase hex SHA-256 of the **plaintext** content (after
  /// inflate + decrypt). Same on encrypted and unencrypted packs.
  final String sha256Hex;
}

class DataPackManifest {
  const DataPackManifest({
    required this.bundleName,
    required this.manifestVersion,
    required this.createdAt,
    required this.compression,
    required this.encryption,
    required this.ephemeralPubHex,
    required this.files,
  });

  final String bundleName;
  final int manifestVersion;
  final String createdAt;

  /// "none" or "zlib".
  final String compression;

  /// "none" or "aes-256-gcm".
  final String encryption;

  /// Compressed-point hex (66 chars, P-256) of the per-pack
  /// ephemeral ECDH pubkey. Required when [encryption] != "none";
  /// empty when "none".
  final String ephemeralPubHex;

  final List<DataPackFile> files;

  static DataPackManifest parse(String jsonText) {
    final Object? raw = jsonDecode(jsonText);
    if (raw is! Map<String, Object?>) {
      throw const FormatException('manifest: not a JSON object');
    }

    final compression = _str(raw, 'compression');
    final encryption  = _str(raw, 'encryption');
    if (compression != 'none' && compression != 'zlib') {
      throw FormatException("manifest: unknown compression '$compression'");
    }
    if (encryption != 'none' && encryption != 'aes-256-gcm') {
      throw FormatException("manifest: unknown encryption '$encryption'");
    }

    final ephHex = (raw['ephemeral_pub_hex'] as String?) ?? '';
    if (encryption != 'none' && ephHex.isEmpty) {
      throw const FormatException(
          "manifest: encryption != 'none' but ephemeral_pub_hex is empty");
    }

    final filesRaw = raw['files'];
    if (filesRaw is! List) {
      throw const FormatException("manifest: 'files' must be an array");
    }

    final files = <DataPackFile>[];
    for (final fr in filesRaw) {
      if (fr is! Map<String, Object?>) {
        throw const FormatException('manifest: file entry must be an object');
      }
      final relPath   = _str(fr, 'rel_path');
      final outFolder = _str(fr, 'out_folder');
      _validateRel(relPath,   'rel_path');
      _validateRel(outFolder, 'out_folder');

      final sha = _str(fr, 'sha256_hex');
      if (sha.length != 64 ||
          !RegExp(r'^[0-9a-fA-F]+$').hasMatch(sha)) {
        throw FormatException('manifest: bad sha256_hex: $sha');
      }
      files.add(DataPackFile(
        relPath:    relPath,
        outFolder:  outFolder,
        size:       _int(fr, 'size'),
        storedSize: _int(fr, 'stored_size'),
        offset:     _int(fr, 'offset'),
        sha256Hex:  sha.toLowerCase(),
      ));
    }

    return DataPackManifest(
      bundleName:       _str(raw, 'bundle_name'),
      manifestVersion:  _int(raw, 'manifest_version'),
      createdAt:        _str(raw, 'created_at'),
      compression:      compression,
      encryption:       encryption,
      ephemeralPubHex:  ephHex,
      files:            files,
    );
  }
}

String _str(Map<String, Object?> j, String key) {
  final v = j[key];
  if (v is! String) {
    throw FormatException("manifest: '$key' must be a string");
  }
  return v;
}

int _int(Map<String, Object?> j, String key) {
  final v = j[key];
  if (v is int) return v;
  if (v is num) return v.toInt();
  throw FormatException("manifest: '$key' must be an integer");
}

void _validateRel(String p, String field) {
  if (p.isEmpty) {
    throw FormatException('manifest: $field is empty');
  }
  if (p.startsWith('/') || p.startsWith('\\')) {
    throw FormatException("manifest: $field must be relative: '$p'");
  }
  if (p.length >= 2 && p[1] == ':' && _isLetter(p[0])) {
    throw FormatException("manifest: $field must not be a drive: '$p'");
  }
  for (final seg in p.split(RegExp(r'[/\\]'))) {
    if (seg == '..') {
      throw FormatException("manifest: $field contains '..': '$p'");
    }
  }
}

bool _isLetter(String c) =>
    (c.codeUnitAt(0) >= 0x41 && c.codeUnitAt(0) <= 0x5A) ||
    (c.codeUnitAt(0) >= 0x61 && c.codeUnitAt(0) <= 0x7A);
