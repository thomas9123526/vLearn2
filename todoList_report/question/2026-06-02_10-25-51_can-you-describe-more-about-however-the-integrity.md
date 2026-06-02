# can you describe more about "However — the integrity protection is still strong.

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-02T01:25:51.788Z

## User

can you describe more about
"However — the integrity protection is still strong. The root CA private key is not in the APK, so no one can forge a valid signed pack that the app will accept. The encryption only protects pack contents from extraction, not from tampering."

## Assistant

## How the signature chain works

A `.ddp` pack contains three things relevant to integrity:

```
[header] [manifest] [data blobs] [admin_cert] [signature]
```

### Step 1 — The packer signs the pack (on your build server)

When you create a `.ddp` pack using `datamanage/src/packer.cpp`, it:

1. Takes an **admin certificate** (a short-lived cert you generated, signed by your root CA)
2. Uses the **admin cert's private key** to sign `SHA-256(header ‖ manifest ‖ data ‖ cert)`
3. Embeds both the admin cert and the signature into the pack

The root CA private key is used **only once per admin cert** — to sign the admin cert itself. After that it can stay offline (or in a hardware security module).

---

### Step 2 — The app verifies (on the device)

The app does this in order (lines 163–205 of `datapack_factory.dart`):

```
1. Is the pack signed at all?
      hdr.isSigned == false → refuse immediately

2. Does the embedded admin_cert chain to the pinned root CA?
      verifyCertSignedBy(adminCert, _rootCa) → refuse if false

3. Does the signature verify against the admin cert's public key?
      verifyEcdsaP256(pubKey: adminCert.publicKeyPoint, ...) → refuse if false
```

---

### Why an attacker can't forge a pack

To produce a `.ddp` the app accepts, an attacker would need to:

| What they need | Where it lives | Can attacker get it? |
|---|---|---|
| Root CA private key (to sign a fake admin cert) | Your server / offline storage | **No** — not in the APK |
| Admin cert private key (to sign the pack) | Your build server | **No** — not in the APK |
| Root CA public key (to verify) | `root_ca.crt` in the APK | Yes, but this is useless for forging |

The attacker **can** extract `root_ca.crt` from the APK. But a public certificate only lets you *verify* signatures — you cannot *create* signatures with it. Creating a valid signature requires the corresponding private key, which only you hold.

So even if an attacker:
- Extracts the APK completely
- Reverse engineers the pack format
- Crafts a modified `.ddp` with different data

…the app will reject it at step 2 or 3, because the fake admin cert won't be validly signed by your root CA.

---

### What `admin.key` (in the APK) actually unlocks

The `admin.key` is the **ECDH decryption key** — a completely separate key from the signing keys. It only lets someone derive the AES key for an existing legitimate pack to *read its contents*. It has no power to create new valid signatures.

```
Signing chain:   root_CA_priv  →  admin_cert  →  pack signature    (ECDSA)
Encryption:      admin_priv  ←→  ephemeral_pub  →  AES key          (ECDH)
```

These are two separate key pairs for two separate purposes. One is about *authenticity* (can't be faked), the other is about *confidentiality* (can be read if you have the key).
