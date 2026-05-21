# CA setup for DataManage

PKI used to sign `.ddp` files so the Flutter app can verify they
were produced by an authorised admin.

## Hierarchy

```
            ┌────────────────────┐
            │   Root CA          │   ECDSA P-256, self-signed, ~20 yr
            │  (offline)         │   public key pinned in Flutter app
            └────────┬───────────┘
                     │ signs
        ┌────────────┼────────────┐
        ▼            ▼            ▼
   admin: alice  admin: bob   admin: ops-1     ECDSA P-256, ~5 yr
                                                each used by its admin
                                                to sign .ddp packs
```

The **root CA private key** is the keys to the kingdom. Generate it
once on an offline machine, store on a locked drawer or hardware
token, and pin the corresponding **public key** in the Flutter app
(Stage 8). Every admin then gets their own sub-CA cert signed by the
root.

Compromise model:

- **Admin key leak:** revoke that admin's cert, re-issue a new one,
  ship a CRL update with the next .ddp. App keeps trusting root.
- **Root key leak:** game over. Ship a new Flutter app build with a
  new pinned root, re-issue every admin, re-pack every bundle.

## Scripts

### `make_root_ca.ps1`

Run once per project deployment. Generates `issued/root/root_ca.key`
+ `root_ca.crt`. Refuses to overwrite an existing key.

```powershell
PS> .\make_root_ca.ps1
# or with explicit subject:
PS> .\make_root_ca.ps1 -CommonName "DataManage Root CA" -Organization "Acme"
```

### `issue_admin_ca.ps1 -Name <admin>`

Per admin. Generates `issued/admins/<name>/admin.key` + `admin.crt`,
signed by the root CA. Refuses to overwrite without `-Force`.

```powershell
PS> .\issue_admin_ca.ps1 -Name alice
PS> .\issue_admin_ca.ps1 -Name ops-1 -ValidityDays 730
PS> .\issue_admin_ca.ps1 -Name alice -Force   # re-issue
```

## What gets committed

Nothing under `issued/`. The `.gitignore` excludes it entirely.

Scripts (`*.ps1`) and this README stay tracked. The generated
private keys + certs are per-deployment artefacts; each project's
admin holds their own root.

## Verifying a chain

```powershell
PS> & 'C:\Program Files\Git\usr\bin\openssl.exe' `
       verify -CAfile issued\root\root_ca.crt issued\admins\alice\admin.crt
# alice\admin.crt: OK
```

## What the admin does with these in Stage 6

`config.json`:

```json
{
  "signing": {
    "cert_path": "ca/issued/admins/alice/admin.crt",
    "key_path":  "ca/issued/admins/alice/admin.key"
  }
}
```

The packer (Stage 6) signs each `.ddp` with `admin.key` and embeds
`admin.crt` in the file's certificate section. The unpacker (Stage
8) walks the chain `admin.crt → root_ca` and refuses any pack whose
chain doesn't end at the pinned root.

## Algorithm choices

- **ECDSA P-256** — smaller signatures than RSA-2048, faster verify
  on Android. Industry standard.
- **SHA-256** — used by `openssl x509 -req` as the signing hash
  (matches our pack-content hash in Stage 3).
- **20-year root validity** — root rotations require re-shipping
  the Flutter app, so we lean long.
- **5-year admin validity** — re-issuance is cheap (one script
  invocation); shorter lifetimes limit blast radius if a key leaks.

## Security checklist

- [ ] `make_root_ca.ps1` run on a machine that's normally offline.
- [ ] `root_ca.key` moved off the dev machine to a locked drawer
      or hardware token after generation.
- [ ] Root CA's pubkey fingerprint pinned in Flutter source
      (Stage 8).
- [ ] Each admin's `admin.key` protected with full-disk encryption
      and not shared between admins.
- [ ] No `.key`, `.pem`, `.csr` files committed (gitignore
      enforces).
