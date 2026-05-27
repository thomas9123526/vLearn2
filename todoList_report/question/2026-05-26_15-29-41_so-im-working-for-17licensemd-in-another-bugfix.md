# so , I'm working  for 17_license.md in another bug_fix claude tabs. While , I wa

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-26T06:29:41.199Z

## User

so , I'm working  for 17_license.md in another bug_fix claude tabs.
While , I want know the logic for keygenerator relationship with cert format

## Assistant

Here's the relationship, drawn out from the plan doc + the existing datamanage cert hierarchy:

## The cert chain

```
Root CA (offline, ~20 yr)
   │  signs
   ▼
Key CA           (offline, signs the per-product Leaf CAs)
   │  signs
   ▼
Leaf CA          ← the cert + key KeyGenerator loads
   │  signs each license
   ▼
License cert     ← what KeyGenerator emits — one per user/device
```

The first three exist already (reused from datamanage's PKI). KeyGenerator only touches the **last step** — issuing license certs.

## What KeyGenerator actually does

It's a GUI cert factory. Operator workflow:

1. **Load** the Leaf CA cert (`.cer`) + private key (`.key`) — files stay on the operator's machine, never shipped to the device.
2. **Enter** `machineId`, `userName`, `licenseDays`.
3. **Generate** — KeyGenerator builds an X.509 leaf cert in memory:
   - `Subject DN`: `CN=<userName>, O=<org>`
   - **Custom OID `1.3.6.1.4.1.99999.1`** in extensions → carries `machineId` (this is the device-binding hook)
   - `subjectAltName` → `machineId`, `userName`, `licenseMode`, `licenseDays`
   - `notBefore` = now, `notAfter` = now + days (permanent = 36500)
   - `keyUsage` = **`digitalSignature` only** — explicitly NOT `keyCertSign`, so the license can't be used to issue further certs
   - DER-encoded → base64-ish blob written to `.lic` file AND encoded as a QR
4. **Sign** the cert bytes with the Leaf CA private key (ECDSA P-256).
5. **Log** the issuance in `vLearnLicense.generate_log`.

## Why X.509 ECDSA P-256 ≤ 1 KB

Three constraints meet at one format:

| Constraint | Why this format wins |
|---|---|
| Same toolchain as the rest of the app | Datamanage already uses Root CA → Key CA → Leaf CA chain with ECDSA P-256. Operators don't learn new tooling, KeyGenerator can reuse `openssl`/`libcrypto` / `System.Security.Cryptography` calls. |
| Backend + Flutter parse it cheaply | OpenSSL on the server, pointycastle on the device. Both already in the codebase. No bespoke binary format to spec/validate. |
| Must fit in a QR Code | P-256 ECDSA leaf cert is **≈ 600–700 bytes** including signature. QR Version-22 alphanumeric holds ≈ 1700 bytes — comfortable margin. RSA-2048 wouldn't fit; that's what forces the curve choice. |

## What "subject public key" holds

X.509 certs normally bind a subject's own keypair. The plan says KeyGenerator does **NOT** generate a new keypair per license — the license isn't a key-binding cert, it's an **authorization token shaped as a cert** so it can ride the X.509 verifier for free. In practice that field will either carry a placeholder/derived public key or the Leaf CA's own; the meaningful fields are subject DN + custom OID + validity + the Leaf CA's signature over all of it.

## Backend verification (the inverse of KeyGenerator)

The backend has `license.public_pem` = Leaf CA public key (configured via admin tab → `vl_app_config`). For each `POST /license/verify`:

```ts
const leaf = new X509Certificate(buf);
if (!leaf.verify(this.publicKeyPem)) throw new InvalidLicense();
if (leaf.validTo < new Date())       throw new ExpiredLicense();
const machineId = extractCustomOid(leaf, '1.3.6.1.4.1.99999.1');
if (machineId !== body.machineId)    throw new BoundDeviceMismatch();
```

So the backend's only secret is the Leaf CA **public** key. The Leaf CA private key never leaves the operator's KeyGenerator machine. Anyone with the public key can verify, no one but the operator can issue.

## TL;DR of the KeyGenerator ↔ cert-format relationship

KeyGenerator **is** the format. The cert format is whatever bytes KeyGenerator decides to emit when its "Generate" button is pressed — namely an X.509 ECDSA P-256 leaf with the machineId custom OID, signed by the loaded Leaf CA. Backend + Flutter just parse-and-verify whatever shape KeyGenerator produces; if you change a field in KeyGenerator, you must mirror it in `extractCustomOid` on the server and in the Dart parser.
