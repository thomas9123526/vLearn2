# I can see  admin.key, root_ca.crt in the android apk what are they and  is it sa

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-02T01:22:29.622Z

## User

I can see  admin.key, root_ca.crt in the android apk
what are they and  is it safe to put inside the apk?

## Assistant

Let me look at the datapack code to understand how these files are used.

## Assistant

**Short answer: `root_ca.crt` is fine; `admin.key` is a real risk.**

---

## What each file does

### `root_ca.crt` — safe to ship
This is a public X.509 certificate, the **root of trust** for verifying `.ddp` pack signatures. Embedding it in the APK is the correct pattern (like TLS certificate pinning). It contains no secrets — its counterpart private key is what matters, and that lives on your build/signing server, not in the APK.

### `admin.key` — **private key, should NOT be in the APK**
This is an **EC P-256 private key**. The code uses it at line 216 of `datapack_factory.dart`:
```dart
final shared = ecdhSharedSecret(_adminPriv, ephPoint);
aesKey = hkdfSha256(ikm: shared, ...);
```
It performs **ECDH** with an ephemeral public key embedded in each pack to derive the AES-256 decryption key. In other words: this key IS the decryption capability for any encrypted `.ddp` pack.

---

## The actual risk

An APK is a ZIP file. Anyone can run:
```
unzip vlearn2.apk assets/datamanage/admin.key
```
or use `apktool`. No rooted device needed. They get the private key, and can then decrypt any `.ddp` pack you've ever distributed or will distribute.

However — the **integrity protection is still strong**. The root CA private key is *not* in the APK, so no one can forge a valid signed pack that the app will accept. The encryption only protects pack *contents* from extraction, not from tampering.

---

## Options

| Approach | Protection level | Effort |
|---|---|---|
| Leave as-is | Soft DRM — stops casual extraction, not reverse engineers | None |
| Store key in Android Keystore (provisioned at first launch via a server-side key exchange) | Key never extractable from device | High |
| Drop encryption entirely, keep only signatures | Honest about what you have — integrity still strong | Low |

**If the packs contain fonts, ML models, or other non-secret content** (just app data you want to distribute, not credentials or user data), the current scheme is comparable to standard game/app DRM — a determined attacker can extract it, but it raises the bar for casual users. Signature verification still guarantees no one can tamper with the packs.

**If the packs contain anything genuinely secret** (license keys, proprietary training data, etc.), `admin.key` being in the APK fully undermines that protection and you should move to server-side decryption or Android Keystore provisioning.
