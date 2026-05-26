# DataManage - Stage 5: CA setup (root + admin sub-CAs)

## What landed

Two PowerShell scripts under `datamanage/ca/` plus a workflow README.
They produce the PKI that Stages 6 and 8 will use to sign and verify
.ddp packs. No C++ code changes; this stage is purely operational
scripts + docs.

### Files added

- `datamanage/ca/make_root_ca.ps1` - one-time. Generates ECDSA P-256
  root CA private key + self-signed certificate. Default validity
  20 years.
- `datamanage/ca/issue_admin_ca.ps1` - per admin. Generates an
  ECDSA P-256 key + cert signed by the root CA. Default validity
  5 years. Verifies the chain with `openssl verify` before
  declaring success.
- `datamanage/ca/README.md` - hierarchy diagram, compromise model,
  config.json usage example, security checklist.

### Files modified

- `datamanage/.gitignore`:
  - Removed blanket `ca/` exclusion (would have killed scripts).
  - Replaced with `ca/issued/` so scripts stay tracked while
    generated keys + certs do not.
  - Added `*.csr` and `*.srl` to defensive global ignores.
- `datamanage/README.md` - Status row Stage 5 marked done.

## Design decisions

| Question | Pick | Reason |
|---|---|---|
| Algorithm | ECDSA P-256 | smaller signatures + faster verify than RSA-2048; what we already decided for Stage 6. |
| Hash | SHA-256 (openssl default for x509 -req) | matches our pack-content hash. |
| Hierarchy depth | Root -> Admin (one level) | user asked for "sub CA for admins". `pathlen:1` on root + `pathlen:0` on admin caps the tree at two levels - admin can't spawn deeper CAs even if compromised. |
| Root validity | 20 years | rotating root means re-shipping the Flutter app (new pinned key), so we lean long. |
| Admin validity | 5 years | re-issuance is one script call; shorter lifetimes limit blast radius. |
| OpenSSL binary | Git for Windows' `C:\Program Files\Git\usr\bin\openssl.exe` (auto-detected if not on PATH) | already on admin's box; no new install. |
| Key encryption | unencrypted PEM | simpler for Stage 6 packer; admin can wrap with AES later if they want. Documented in README's security checklist. |
| Overwrite protection | refuse without `-Force` (admin); refuse outright (root) | re-rolling root orphans every admin cert ever issued - too dangerous to be a one-flag command. |

## Verification on this box

```text
PS> .\make_root_ca.ps1
[root-ca] using C:\Program Files\Git\usr\bin\openssl.exe
[root-ca] generating P-256 EC private key...
[root-ca] generating self-signed root certificate...
[root-ca] root CA generated:
          key: ...\ca\issued\root\root_ca.key
          crt: ...\ca\issued\root\root_ca.crt
subject=CN=DataManage Root CA, O=DataManage
issuer=CN=DataManage Root CA, O=DataManage
notBefore=May 21 11:24:39 2026 GMT
notAfter=May 16 11:24:39 2046 GMT
sha256 Fingerprint=BE:A7:31:D0:...:67:9C:1C

PS> .\issue_admin_ca.ps1 -Name alice
[admin-ca:alice] generating P-256 EC private key...
[admin-ca:alice] generating CSR...
[admin-ca:alice] signing CSR with root CA...
Certificate request self-signature ok
subject=CN=alice, O=DataManage
[admin-ca:alice] verifying chain...
...alice\admin.crt: OK
notBefore=May 21 11:26:14 2026 GMT
notAfter=May 20 11:26:14 2031 GMT

PS> .\issue_admin_ca.ps1 -Name alice   # without -Force
[admin-ca:alice] ERROR: ...alice\admin.key already exists.
[admin-ca:alice] Re-run with -Force to overwrite.

PS> .\make_root_ca.ps1                  # without manual delete
[root-ca] ERROR: ...root_ca.key already exists.
[root-ca] Delete it manually if you really want to re-roll the CA.
[root-ca] Re-rolling orphans every admin cert ever issued.
```

Chain verification: `openssl verify -CAfile root_ca.crt admin.crt` ->
`admin.crt: OK`. Confirmed both that the root is self-signed and the
admin cert chains up to it.

`git status` confirms:
- `ca/README.md`, `ca/make_root_ca.ps1`, `ca/issue_admin_ca.ps1` are
  untracked and will be staged on commit.
- `ca/issued/...` is excluded by `.gitignore` rule
  `ca/issued/` (verified with `git check-ignore -v`).

## Bumps + fixes

1. **`issue_admin_ca.ps1` failed to parse** on first run with
   "Unexpected token 'issued' in expression or statement". Root
   cause: I'd written em-dashes (`-` UTF-8 `E2 80 94`) inside the
   `throw "..."` string at line 144. Windows PowerShell 5.1 reads
   `.ps1` files in the system code page (cp1252) by default unless
   a UTF-8 BOM is present, so the 3-byte UTF-8 sequence got
   misinterpreted as cp1252 chars including a literal `"` that
   broke string parsing.
   - `make_root_ca.ps1` happened to escape the same problem because
     its em-dashes were all in the `<# ... #>` comment block, which
     PS's comment parser is lenient about.
   - Fix: global replace of em-dashes with ASCII hyphens in both
     scripts. Could alternatively have saved as UTF-8 with BOM, but
     plain ASCII is simpler and the documentation reads fine.

## Out of scope (intentionally deferred)

- **Key password protection.** Admin keys are unencrypted PEM. Stage
  6 reads them directly. Adding `-aes256` to the key generation
  would force a password prompt during pack, complicating the GUI.
  Documented in the README security checklist as a future hardening
  option.
- **CRL generation.** No CRL infrastructure yet. Admin key
  revocation in Stage 6/8 will likely use a simple "revoked
  fingerprints" list embedded in the Flutter app rather than
  classical X.509 CRLs - simpler and avoids needing a CRL endpoint.

## Stage 6 preview

Wire the actual signing into the packer:

- Read admin's `signing.cert_path` + `signing.key_path` from
  `config.json`.
- After writing the .ddp body (header + manifest + data), append
  the admin's cert as section [4] (cert section).
- Compute SHA-256 over header || manifest || data || cert.
- Sign with the admin's P-256 key, append as section [5]
  (signature section).
- Patch `cert_len`/`cert_offset`/`sig_len`/`sig_offset` in the
  header.

For ECDSA signing we'll likely use the same Windows CNG (BCrypt
provider) that already does SHA-256 - same API family,
`BCRYPT_ECDSA_P256_ALGORITHM`. Avoids the need to vendor mbedTLS
in Stage 6 just to sign. mbedTLS lands in Stage 7 for AES-GCM +
ECDH key wrap.

## User prompt (verbatim)

> 1

(option 1: openssl via Git for Windows)
