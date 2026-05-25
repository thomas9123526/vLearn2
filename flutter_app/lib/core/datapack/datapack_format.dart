// Mirror of `datamanage/src/format.h` — the binary layout of a `.ddp`
// pack. Both sides must agree byte-for-byte; if you change anything
// here, the matching change in format.h has to ship in the same
// commit.
//
// Layout:
//   [Header (64 bytes)]
//   [Manifest (JSON, UTF-8, header.manifestLen bytes)]
//   [Data (header.dataLen bytes)  — possibly compressed + encrypted]
//   [Certificate (header.certLen bytes, DER)        — when signed]
//   [Signature   (header.sigLen bytes, DER ECDSA)   — when signed]

import 'dart:typed_data';

const int kDataPackMagic    = 0x50444444; // "DDDP" little-endian
const int kDataPackVersion  = 1;

const int kFlagCompressed = 1 << 0; // zlib (DEFLATE inside RFC 1950 stream)
const int kFlagEncrypted  = 1 << 1; // AES-256-GCM with ECDH-derived key

/// Fixed 64-byte header at offset 0 of every `.ddp` file.
class DataPackHeader {
  const DataPackHeader({
    required this.magic,
    required this.version,
    required this.flags,
    required this.manifestLen,
    required this.manifestOffset,
    required this.dataLen,
    required this.dataOffset,
    required this.sigLen,
    required this.sigOffset,
    required this.certLen,
    required this.certOffset,
  });

  final int magic;
  final int version;
  final int flags;
  final int manifestLen;
  final int manifestOffset;
  final int dataLen;
  final int dataOffset;
  final int sigLen;
  final int sigOffset;
  final int certLen;
  final int certOffset;

  bool get isCompressed => (flags & kFlagCompressed) != 0;
  bool get isEncrypted  => (flags & kFlagEncrypted)  != 0;
  bool get isSigned     => sigLen > 0 && certLen > 0;

  /// Parse the 64-byte header from the start of [bytes]. Throws
  /// [FormatException] on bad magic or version.
  static DataPackHeader parse(Uint8List bytes) {
    if (bytes.length < 64) {
      throw const FormatException('.ddp too small to hold header');
    }
    final view = ByteData.sublistView(bytes, 0, 64);
    final magic   = view.getUint32(0,  Endian.little);
    final version = view.getUint32(4,  Endian.little);
    if (magic != kDataPackMagic) {
      throw FormatException(
          'bad magic: 0x${magic.toRadixString(16)} '
          '(expected 0x${kDataPackMagic.toRadixString(16)})');
    }
    if (version != kDataPackVersion) {
      throw FormatException(
          'unsupported .ddp version $version '
          '(this app supports $kDataPackVersion)');
    }
    return DataPackHeader(
      magic:           magic,
      version:         version,
      flags:           view.getUint32(8,  Endian.little),
      manifestLen:     view.getUint32(12, Endian.little),
      manifestOffset:  view.getUint64(16, Endian.little),
      dataLen:         view.getUint64(24, Endian.little),
      dataOffset:      view.getUint64(32, Endian.little),
      sigLen:          view.getUint32(40, Endian.little),
      sigOffset:       view.getUint64(44, Endian.little),
      certLen:         view.getUint32(52, Endian.little),
      certOffset:      view.getUint64(56, Endian.little),
    );
  }

  /// Re-encode the header into 64 bytes with [sigLen] and [sigOffset]
  /// zeroed. The packer signs over this representation; the verifier
  /// has to reconstruct it identically.
  Uint8List toBytesForSigVerification() {
    final out = Uint8List(64);
    final v = ByteData.sublistView(out);
    v.setUint32(0,  magic,           Endian.little);
    v.setUint32(4,  version,         Endian.little);
    v.setUint32(8,  flags,           Endian.little);
    v.setUint32(12, manifestLen,     Endian.little);
    v.setUint64(16, manifestOffset,  Endian.little);
    v.setUint64(24, dataLen,         Endian.little);
    v.setUint64(32, dataOffset,      Endian.little);
    // sig_len + sig_offset deliberately zeroed.
    v.setUint32(40, 0,               Endian.little);
    v.setUint64(44, 0,               Endian.little);
    v.setUint32(52, certLen,         Endian.little);
    v.setUint64(56, certOffset,      Endian.little);
    return out;
  }
}
