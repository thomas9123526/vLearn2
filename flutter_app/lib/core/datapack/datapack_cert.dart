// Minimal X.509 cert parsing for DataManage chain validation.
//
// Scope: we only need enough of the cert to (a) extract its EC P-256
// pubkey, (b) re-hash the tbsCertificate for signature verification,
// and (c) verify an admin cert was signed by the pinned root CA.
// No need for distinguished-name pretty-printing, validity-range
// checking (the .ddp has no expiry), or full extension parsing.

import 'dart:convert';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:pointycastle/export.dart';

import 'datapack_crypto.dart';

/// Parsed cert with just what we need: the EC pubkey for ECDH +
/// signature verification, and the raw tbsCertificate bytes for
/// verifying the cert's own signature against an issuer.
class ParsedCert {
  ParsedCert({
    required this.derBytes,
    required this.tbsBytes,
    required this.signatureBytes,
    required this.publicKeyPoint,
  });

  /// Full cert in DER (as it lives in the .ddp section [4]).
  final Uint8List derBytes;

  /// The DER-encoded tbsCertificate. SHA-256 over this is what the
  /// issuer (root CA) signed.
  final Uint8List tbsBytes;

  /// DER-encoded ECDSA signature (SEQUENCE { r, s }) over [tbsBytes],
  /// produced by the issuer.
  final Uint8List signatureBytes;

  /// EC P-256 public key point. Used for signature verification of
  /// the data pack (when this is the admin cert) and ECDH key
  /// agreement (when this is the encryption recipient).
  final ECPoint publicKeyPoint;
}

/// Parse a DER X.509 cert. Tested against ECDSA P-256 certs as
/// produced by openssl 3.x via our `make_root_ca.ps1` and
/// `issue_admin_ca.ps1` scripts.
ParsedCert parseDerCert(Uint8List der) {
  final asn1 = ASN1Parser(der);
  final cert = asn1.nextObject();
  if (cert is! ASN1Sequence || cert.elements.length < 3) {
    throw const FormatException('cert: outer is not SEQUENCE of 3');
  }

  final tbs = cert.elements[0] as ASN1Sequence;
  final sigBitStr = cert.elements[2] as ASN1BitString;

  // tbsCertificate elements depend on whether the cert is v1 or v3.
  // v3 (openssl default) prepends an explicit [0] version tag.
  var tbsElements = tbs.elements;
  if (tbsElements.isNotEmpty && tbsElements.first.tag == 0xA0) {
    tbsElements = tbsElements.sublist(1);  // strip version
  }
  // Now: [0]=serialNumber, [1]=signatureAlgorithm, [2]=issuer,
  //      [3]=validity,    [4]=subject,             [5]=spki,
  //      optional [6]=extensions.
  if (tbsElements.length < 6) {
    throw FormatException(
        'cert: tbsCertificate has ${tbsElements.length} fields, '
        'expected ≥ 6');
  }
  final spki = tbsElements[5] as ASN1Sequence;

  // SubjectPublicKeyInfo ::= SEQUENCE { algorithm, subjectPublicKey BIT STRING }
  if (spki.elements.length != 2) {
    throw const FormatException('cert: SPKI not SEQUENCE of 2');
  }
  final pkBitStr = spki.elements[1] as ASN1BitString;
  final pubKeyBytes = Uint8List.fromList(pkBitStr.stringValue);
  // For ECDSA P-256 the BIT STRING content is the uncompressed point
  // 0x04 || X(32) || Y(32) — 65 bytes total. Compressed (0x02/0x03)
  // is legal but openssl never emits it for cert pubkeys.
  if (pubKeyBytes.length != 65 || pubKeyBytes[0] != 0x04) {
    throw FormatException(
        'cert: SPKI public key is not an uncompressed P-256 point '
        '(len ${pubKeyBytes.length}, prefix 0x${pubKeyBytes.isEmpty ? "?" : pubKeyBytes[0].toRadixString(16)})');
  }
  final point = kP256.curve.decodePoint(pubKeyBytes);
  if (point == null) {
    throw const FormatException('cert: cannot decode SPKI EC point');
  }

  // Strip leading unused-bits byte of the signatureValue BIT STRING.
  // For ECDSA, the BIT STRING contents are the DER-encoded
  // SEQUENCE { r, s } — directly consumable by our verifier.
  return ParsedCert(
    derBytes: der,
    tbsBytes: Uint8List.fromList(tbs.encodedBytes),
    signatureBytes: Uint8List.fromList(sigBitStr.stringValue),
    publicKeyPoint: point,
  );
}

/// Parse a PEM-encoded X.509 cert (the `root_ca.crt` asset). Strips
/// the `-----BEGIN/END CERTIFICATE-----` armour, base64-decodes the
/// middle, then runs [parseDerCert].
ParsedCert parsePemCert(String pem) {
  final der = _pemToDer(pem, 'CERTIFICATE');
  return parseDerCert(der);
}

/// Verify that [admin] was signed by [issuer]. Decodes the issuer's
/// pubkey, re-hashes admin.tbsBytes with SHA-256, and ECDSA-verifies
/// admin.signatureBytes against the digest.
bool verifyCertSignedBy(ParsedCert admin, ParsedCert issuer) {
  final digest = sha256Bytes(admin.tbsBytes);
  return verifyEcdsaP256(
    pubKey: issuer.publicKeyPoint,
    messageDigest: digest,
    signatureDer: admin.signatureBytes,
  );
}

/// Parse a PEM-encoded EC private key (the `admin.key` asset) into
/// the raw private scalar. Handles both "EC PRIVATE KEY" (RFC 5915)
/// and "PRIVATE KEY" (PKCS#8) headers — openssl emits the former by
/// default; recent versions emit the latter.
BigInt parsePemEcPrivateKey(String pem) {
  Uint8List der;
  try {
    der = _pemToDer(pem, 'EC PRIVATE KEY');
  } on FormatException {
    der = _pemToDer(pem, 'PRIVATE KEY');
  }
  final outer = ASN1Parser(der).nextObject() as ASN1Sequence;

  // RFC 5915 ECPrivateKey ::= SEQUENCE {
  //     version              INTEGER (1),
  //     privateKey           OCTET STRING,
  //     parameters       [0] ECParameters OPTIONAL,
  //     publicKey        [1] BIT STRING   OPTIONAL  }
  //
  // PKCS#8 PrivateKeyInfo ::= SEQUENCE {
  //     version              INTEGER,
  //     algorithm            AlgorithmIdentifier,
  //     privateKey           OCTET STRING (which is itself ECPrivateKey) }
  ASN1OctetString privBytes;
  if (outer.elements.length >= 2 && outer.elements[1] is ASN1OctetString &&
      outer.elements[0] is ASN1Integer) {
    // RFC 5915 form — element[1] is the raw scalar OCTET STRING.
    final maybeRaw = outer.elements[1] as ASN1OctetString;
    if (outer.elements.length <= 3 || outer.elements[2].tag == 0xA0) {
      privBytes = maybeRaw;
    } else {
      // PKCS#8 form (algorithm at [1] is a SEQUENCE, not OCTET STRING).
      privBytes = _pkcs8Inner(outer);
    }
  } else {
    privBytes = _pkcs8Inner(outer);
  }

  // Some encodings stick the scalar at outer.elements[1] directly;
  // others wrap an inner ECPrivateKey SEQUENCE inside the OCTET STRING.
  Uint8List rawScalar;
  try {
    final inner =
        ASN1Parser(Uint8List.fromList(privBytes.contentBytes())).nextObject();
    if (inner is ASN1Sequence && inner.elements.length >= 2 &&
        inner.elements[1] is ASN1OctetString) {
      rawScalar = Uint8List.fromList(
          (inner.elements[1] as ASN1OctetString).contentBytes());
    } else {
      rawScalar = Uint8List.fromList(privBytes.contentBytes());
    }
  } catch (_) {
    rawScalar = Uint8List.fromList(privBytes.contentBytes());
  }

  if (rawScalar.length != 32) {
    throw FormatException(
        'EC private scalar must be 32 bytes for P-256, got ${rawScalar.length}');
  }
  var n = BigInt.zero;
  for (final b in rawScalar) {
    n = (n << 8) | BigInt.from(b);
  }
  return n;
}

ASN1OctetString _pkcs8Inner(ASN1Sequence outer) {
  // PKCS#8: SEQUENCE { version INTEGER, algo SEQUENCE, key OCTET STRING }
  if (outer.elements.length < 3 ||
      outer.elements[2] is! ASN1OctetString) {
    throw const FormatException('EC key: not PKCS#8 either');
  }
  return outer.elements[2] as ASN1OctetString;
}

Uint8List _pemToDer(String pem, String label) {
  final beginMarker = '-----BEGIN $label-----';
  final endMarker   = '-----END $label-----';
  final beginIdx = pem.indexOf(beginMarker);
  final endIdx   = pem.indexOf(endMarker);
  if (beginIdx < 0 || endIdx < 0 || endIdx <= beginIdx) {
    throw FormatException('PEM: missing $label markers');
  }
  final body = pem
      .substring(beginIdx + beginMarker.length, endIdx)
      .replaceAll(RegExp(r'\s+'), '');
  return Uint8List.fromList(base64.decode(body));
}
