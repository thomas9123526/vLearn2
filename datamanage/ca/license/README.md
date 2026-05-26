# License CA chain

PKI for the vLearn2 **license** feature. Separate from the
DataManage admin CA (`../make_root_ca.ps1`) because:

* DataManage's root pins `pathlen:1` -- it cannot host a two-deep
  CA hierarchy below itself.
* Different blast radii: compromising the license root does not
  invalidate `.ddp` signatures, and vice versa.

## Hierarchy

```
+--------------------+
| License Root CA    |  ECDSA P-256, self-signed, 30 yr,
|  (offline)         |  pathlen:2
+---------+----------+
          | signs
          v
+--------------------+
| License Key CA     |  ECDSA P-256, 20 yr, pathlen:1
|  (semi-offline)    |
+---------+----------+
          | signs
          v
+--------------------+
| License Leaf CA    |  ECDSA P-256, 5 yr, pathlen:0
|  (KeyGenerator     |  -- the cert + key the KeyGenerator GUI
|   workstation)     |     actually loads
+---------+----------+
          | signs (KeyGenerator)
          v
+--------------------+
| Per-device license |  X.509 leaf, ~1 yr - 100 yr depending
|  cert (.lic)       |  on what the operator selects in the GUI
+--------------------+
```

The intermediate split (Root signs Key; Key signs Leaf) lets the
Root key stay fully offline -- it is used exactly twice in its
lifetime (mint itself, sign the Key CA). All routine Leaf-CA
rotations are done with the Key CA only.

## Scripts

Run in order from this directory. Each is idempotent and refuses
to overwrite an existing key without `-Force`.

| # | Script | What it produces |
| - | --- | --- |
| 1 | `01_make_root_ca.ps1` | `issued/license/root/license_root_ca.{key,crt}` |
| 2 | `02_make_key_ca.ps1`  | `issued/license/key/license_key_ca.{key,csr,crt}` |
| 3 | `03_make_leaf_ca.ps1` | `issued/license/leaf/license_leaf_ca.{key,csr,crt}` |
| 4 | `04_build_chain.ps1`  | `issued/license/chain/license_chain.crt` and `license_chain_full.crt` |
| 5 | `05_verify_chain.ps1` | runs `openssl verify` against the chain |

```powershell
cd datamanage\ca\license
.\01_make_root_ca.ps1
.\02_make_key_ca.ps1
.\03_make_leaf_ca.ps1
.\04_build_chain.ps1
.\05_verify_chain.ps1
```

Defaults are reasonable. To override:

```powershell
.\01_make_root_ca.ps1 -CommonName "Acme License Root" -Organization Acme -ValidityDays 7300
```

## What gets committed

Nothing under `issued/`. The repo-level `datamanage/.gitignore`
covers `ca/issued/` -- the chain you generate stays local.

The scripts themselves and this README are tracked.

## Plugging the Leaf CA into the KeyGenerator

After step 3 you have:

```
datamanage/ca/issued/license/leaf/license_leaf_ca.crt
datamanage/ca/issued/license/leaf/license_leaf_ca.key
```

In the KeyGenerator GUI (`thirdparty/KeyGenerator/KeyGenerator.exe`):

1. **Leaf CA cert (PEM)** -> Browse to `license_leaf_ca.crt`.
2. **Leaf CA key (PEM)**  -> Browse to `license_leaf_ca.key`.
3. Fill in machine ID + user + days, click Generate.

The path is remembered between launches via QSettings, so you
only point at the files once per workstation.

## What the backend pins

The backend's `LicenseService.verify` validates incoming `.lic`
blobs against the **Root + Key** chain (i.e. `license_chain.crt`
or just `license_root_ca.crt` plus the Key CA as `untrusted`).
The Leaf CA itself is not pinned -- when it rotates, only the
backend's stored intermediate updates; the Root stays.

Configure the backend with:

```sql
UPDATE vl_app_config
   SET value = (paste contents of license_chain_full.crt as PEM text)
 WHERE key   = 'license.public_pem';
```

(or via the admin panel's License tab once it accepts a PEM
upload).

## Security checklist

- [ ] `01_make_root_ca.ps1` run on a machine that is normally offline.
- [ ] `license_root_ca.key` moved off the dev machine to a locked
      drawer / hardware token immediately after step 1.
- [ ] `license_key_ca.key` kept on a workstation that comes online
      only for Leaf-CA rotation.
- [ ] `license_leaf_ca.key` only ever on the operator's
      KeyGenerator workstation, full-disk encrypted.
- [ ] No `.key`, `.csr`, `.pem` files committed (the parent
      gitignore enforces).
- [ ] `05_verify_chain.ps1` returns "OK" before the Leaf CA goes
      into production use.

## Algorithm choices

- **ECDSA P-256** everywhere -- smaller signatures than RSA, faster
  verify on mobile. License blobs are size-sensitive (they ride
  in a QR code), so signature size matters.
- **SHA-256** as the signing hash.
- **30 / 20 / 5 year validities** -- root and key go long to keep
  re-pinning rare; leaf goes short so routine rotation is cheap.
