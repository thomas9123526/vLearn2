// Cryptographic primitives the .ddp unpacker needs. Everything is
// pure Dart through pointycastle — no FFI, no native plugin. Backends
// must agree byte-for-byte with `datamanage/src/{sha256,signer,encrypt}.cpp`.

import 'dart:typed_data';

// pointycastle's directory layout drifts across versions and the
// per-subdir imports get noisy. `export.dart` re-exports everything
// we need (ECDH, ECDSA, AES, GCM, HKDF, SHA-256, EC types).
import 'package:pointycastle/export.dart';

/// NIST P-256 / secp256r1 — the curve every part of DataManage uses.
final ECDomainParameters kP256 = ECDomainParameters('secp256r1');

/// HKDF salt + info — must match `encrypt.cpp::kHkdfSalt` / `kHkdfInfo`.
const String kHkdfSalt = 'DataManage v1 ECIES salt';
const String kHkdfInfo = 'DataManage v1 ECIES aes-256-gcm';

/// Returns SHA-256 of [bytes] as raw 32-byte digest.
Uint8List sha256Bytes(Uint8List bytes) {
  final d = SHA256Digest();
  return d.process(bytes);
}

/// ECDH P-256: shared = priv · pub. Returns the **X coordinate** of
/// the result as a fixed 32-byte big-endian buffer (this is the
/// SECG SEC1 standard ECDH output, matching `mbedtls_mpi_write_binary(
/// &shared.X, z, 32)` on the pack side).
Uint8List ecdhSharedSecret(BigInt privateScalar, ECPoint peerPub) {
  final agreement = ECDHBasicAgreement();
  agreement.init(ECPrivateKey(privateScalar, kP256));
  final shared = agreement.calculateAgreement(
      ECPublicKey(peerPub, kP256));
  return _bigIntToFixedBytes(shared, 32);
}

/// HKDF-SHA-256(ikm, salt, info) → [length]-byte derived key.
Uint8List hkdfSha256({
  required Uint8List ikm,
  required Uint8List salt,
  required Uint8List info,
  int length = 32,
}) {
  final hkdf = HKDFKeyDerivator(SHA256Digest());
  hkdf.init(HkdfParameters(ikm, length, salt, info));
  final out = Uint8List(length);
  hkdf.deriveKey(null, 0, out, 0);
  return out;
}

/// Decrypt one AES-256-GCM blob produced by `encrypt.cpp::encrypt()`.
/// Input layout: `[12-byte IV][ciphertext][16-byte tag]`. Throws on
/// auth failure (tag mismatch).
Uint8List aesGcmDecrypt({
  required Uint8List key,
  required Uint8List blob,
}) {
  if (key.length != 32) {
    throw ArgumentError('AES key must be 32 bytes, got ${key.length}');
  }
  if (blob.length < 12 + 16) {
    throw ArgumentError('blob too small for IV+tag: ${blob.length}');
  }
  final iv  = Uint8List.sublistView(blob, 0, 12);
  final ct  = Uint8List.sublistView(blob, 12, blob.length - 16);
  final tag = Uint8List.sublistView(blob, blob.length - 16);

  // pointycastle's GCM `process()` expects the tag *appended* to the
  // ciphertext, so we hand it (ct ‖ tag) — exactly the slice that lives
  // after the IV. Reassemble for clarity.
  final ctWithTag = Uint8List(ct.length + tag.length)
    ..setRange(0, ct.length, ct)
    ..setRange(ct.length, ct.length + tag.length, tag);

  final cipher = GCMBlockCipher(AESEngine());
  cipher.init(
    false, // decrypt
    AEADParameters(
      KeyParameter(key),
      16 * 8,        // tag size in bits
      iv,
      Uint8List(0),  // no AAD — matches encrypt.cpp
    ),
  );
  return cipher.process(ctWithTag);
}

/// Verify an ECDSA P-256 signature over `messageDigest` (already
/// hashed; SHA-256 → 32 bytes). The signature is a DER-encoded
/// SEQUENCE { INTEGER r, INTEGER s } as emitted by `mbedtls_pk_sign`
/// and openssl.
bool verifyEcdsaP256({
  required ECPoint pubKey,
  required Uint8List messageDigest,
  required Uint8List signatureDer,
}) {
  final (r, s) = _parseEcdsaSignature(signatureDer);

  // ECDSASigner wants the digest, not the raw message, when we tell it
  // not to compute the hash itself. Pass the digest verbatim by
  // initialising with a "null" digest path — we use the constructor
  // overload that takes no digest, then the message we pass in is
  // treated as already-hashed.
  final signer = ECDSASigner()
    ..init(false, PublicKeyParameter<ECPublicKey>(
        ECPublicKey(pubKey, kP256)));
  return signer.verifySignature(messageDigest, ECSignature(r, s));
}

/// Decompress a 33-byte SEC1 compressed point (`0x02|0x03 ‖ X`) on
/// P-256 into a full `(X, Y)` ECPoint. The packer ships ephemeral
/// pubkeys this way (33 bytes vs 65 for uncompressed) — half the size,
/// trivially reversible.
ECPoint decompressP256Point(Uint8List compressed) {
  if (compressed.length != 33) {
    throw ArgumentError(
        'compressed P-256 point must be 33 bytes, got ${compressed.length}');
  }
  final prefix = compressed[0];
  if (prefix != 0x02 && prefix != 0x03) {
    throw ArgumentError(
        'compressed P-256 point must start with 0x02 or 0x03, '
        'got 0x${prefix.toRadixString(16)}');
  }
  // pointycastle handles compressed-point decoding directly.
  final point = kP256.curve.decodePoint(compressed);
  if (point == null) {
    throw const FormatException('failed to decode compressed P-256 point');
  }
  return point;
}

// ───── helpers ─────

Uint8List _bigIntToFixedBytes(BigInt n, int size) {
  // Two's-complement-free big-endian conversion. pointycastle's
  // `encodeBigInt` is for signed; for fixed-size unsigned secrets we
  // do this by hand.
  final out = Uint8List(size);
  var v = n;
  for (var i = size - 1; i >= 0; --i) {
    out[i] = (v & BigInt.from(0xff)).toInt();
    v = v >> 8;
  }
  if (v != BigInt.zero) {
    throw ArgumentError('BigInt does not fit in $size bytes');
  }
  return out;
}

/// Parse an ECDSA DER signature `SEQUENCE { INTEGER r, INTEGER s }`
/// into (r, s) BigInts. Hand-rolled rather than dragging in another
/// asn1 dependency for this one tiny structure.
(BigInt, BigInt) _parseEcdsaSignature(Uint8List der) {
  if (der.isEmpty || der[0] != 0x30) {
    throw const FormatException('ECDSA signature: expected SEQUENCE');
  }
  var i = 1;
  final (seqLen, after) = _readDerLength(der, i);
  i = after;
  if (i + seqLen != der.length) {
    throw const FormatException(
        'ECDSA signature: trailing bytes after SEQUENCE');
  }
  final r = _readDerInteger(der, i); i = r.$2;
  final s = _readDerInteger(der, i); i = s.$2;
  if (i != der.length) {
    throw const FormatException(
        'ECDSA signature: extra bytes after r,s');
  }
  return (r.$1, s.$1);
}

(int, int) _readDerLength(Uint8List der, int i) {
  if (i >= der.length) {
    throw const FormatException('DER: length runs off end');
  }
  final b = der[i++];
  if (b < 0x80) return (b, i);
  final n = b & 0x7f;
  if (n == 0 || n > 4) {
    throw FormatException('DER: unsupported length-of-length $n');
  }
  var len = 0;
  for (var k = 0; k < n; ++k) {
    len = (len << 8) | der[i++];
  }
  return (len, i);
}

(BigInt, int) _readDerInteger(Uint8List der, int i) {
  if (der[i] != 0x02) {
    throw const FormatException('DER: expected INTEGER tag');
  }
  i += 1;
  final (len, after) = _readDerLength(der, i);
  i = after;
  final slice = Uint8List.sublistView(der, i, i + len);
  // Strip a leading 0x00 inserted to keep the BigInt unsigned.
  final raw = (slice.isNotEmpty && slice[0] == 0x00)
      ? Uint8List.sublistView(slice, 1)
      : slice;
  var n = BigInt.zero;
  for (final byte in raw) {
    n = (n << 8) | BigInt.from(byte);
  }
  return (n, i + len);
}
