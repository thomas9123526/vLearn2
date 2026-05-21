# how can i configure config.json for datamanager.exe

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-21T14:03:57.657Z

## User

how can i configure config.json for datamanager.exe

## Assistant

Here's the full schema, working from `datamanage/src/config.{h,cpp}` and `config.example.json`.

## Full schema

```jsonc
{
  "version": 1,                        // schema version — must be 1

  "pack_mode": {
    "compress": "zlib",                // "none" | "zlib"
    "encrypt":  "aes-256-gcm"          // "none" | "aes-256-gcm"
  },

  "signing": {                         // required when encrypt != "none"
    "cert_path": "path/to/admin.crt",  // PEM, X.509 v3, ECDSA P-256
    "key_path":  "path/to/admin.key"   // PEM, EC PRIVATE KEY
  },

  "bundles": [                         // 1+ bundles, each becomes <name>.ddp
    {
      "name":       "out_font",        // → output_dir/out_font.ddp
      "source_dir": "C:/data/fonts",   // recursively walked
      "out_folder": "fonts/editorial"  // where files land on the device
    },
    {
      "name":       "out_model",
      "source_dir": "C:/data/models",
      "out_folder": "models"
    }
  ],

  "output_dir": "./output"             // where .ddp files get written
}
```

## Field meanings

| Field | Required | What it does |
| --- | --- | --- |
| `version` | yes | Must be `1`. Bumped only on incompatible schema changes. |
| `pack_mode.compress` | no | `"none"` (default) emits raw blobs. `"zlib"` deflates each blob at level 9. |
| `pack_mode.encrypt` | no | `"none"` (default) skips encryption. `"aes-256-gcm"` runs ECIES — generates ephemeral ECDH keypair against `signing.cert_path`'s pubkey, derives AES-256 key, encrypts each blob. **Requires `signing` block.** |
| `signing.cert_path` | when encrypting or producing prod packs | Path to your admin sub-CA cert (from `issue_admin_ca.ps1`). Forward or backslashes both fine. Relative paths resolve against the **working directory** of `DataManage.exe`, not the config file. |
| `signing.key_path` | same | Path to the matching EC private key. |
| `bundles[].name` | yes | Logical name; output file is `<output_dir>/<name>.ddp`. Must not be empty. |
| `bundles[].source_dir` | yes | Absolute path that gets walked recursively. Every regular file inside becomes a manifest entry. Symlinks are skipped. |
| `bundles[].out_folder` | yes | Relative path under the app's data root where files land on the device. e.g. `out_folder: "fonts"` means a source file `lora/Lora.ttf` is unpacked to `<appDataRoot>/fonts/lora/Lora.ttf`. **Must be relative; no `..` segments; no drive letters.** |
| `output_dir` | no | Defaults to `./output`. Created if missing. |

## Three example configs

### Minimal dev pack (no signing, no encryption)

For local testing of the packer/unpacker mechanics without involving the CA:

```json
{
  "version": 1,
  "pack_mode": { "compress": "none", "encrypt": "none" },
  "bundles": [
    { "name": "test", "source_dir": "C:/data/test", "out_folder": "test" }
  ],
  "output_dir": "./output"
}
```

The Flutter unpacker **refuses these** at runtime (no signature → can't verify chain to pinned root). Only useful from the C++ smoke tests.

### Signed only (compressed, no encryption)

For production where you want integrity but don't need confidentiality:

```json
{
  "version": 1,
  "pack_mode": { "compress": "zlib", "encrypt": "none" },
  "signing": {
    "cert_path": "ca/issued/admins/alice/admin.crt",
    "key_path":  "ca/issued/admins/alice/admin.key"
  },
  "bundles": [
    { "name": "out_font",  "source_dir": "C:/data/fonts",  "out_folder": "fonts"  },
    { "name": "out_model", "source_dir": "C:/data/models", "out_folder": "models" }
  ],
  "output_dir": "./output"
}
```

### Full production (compressed + signed + encrypted)

What you'll ship:

```json
{
  "version": 1,
  "pack_mode": { "compress": "zlib", "encrypt": "aes-256-gcm" },
  "signing": {
    "cert_path": "ca/issued/admins/alice/admin.crt",
    "key_path":  "ca/issued/admins/alice/admin.key"
  },
  "bundles": [
    { "name": "out_font",  "source_dir": "C:/data/fonts",  "out_folder": "fonts"  },
    { "name": "out_model", "source_dir": "C:/data/models", "out_folder": "models" }
  ],
  "output_dir": "./output"
}
```

## Gotchas (verified against the parser in [config.cpp](datamanage/src/config.cpp))

- **`bundles[]` must be non-empty** — `config: 'bundles' must be a non-empty array`.
- **`bundles[].name` must not be empty** — `config: bundle.name must not be empty`.
- **Unknown algorithm values are rejected up front.** Only `"none"` and `"zlib"` for compress; only `"none"` and `"aes-256-gcm"` for encrypt. So no typos slip through.
- **Encryption requires signing.** Inside the packer:
  ```
  encryption requires signing block — the admin's cert is the encryption recipient too
  ```
  (The admin's cert pubkey is what the ephemeral ECDH targets, so it has to be present.)
- **`out_folder` must be relative.** Same rules as the manifest validator: no leading `/` or `\`, no `C:` drive prefix, no `..` segments.
- **Paths in `signing.cert_path` and `signing.key_path` are taken verbatim.** They resolve from the cwd of `DataManage.exe`. For reliability, use absolute paths or always run `DataManage.exe` from a known directory.
- **JSON only.** Comments aren't allowed (despite my schema block above using `// ...` for explanation). Strip them in real files.
- **Forward slashes are safer than backslashes on Windows.** JSON treats `\` as the escape char, so `"C:/data/fonts"` is preferred over `"C:\\data\\fonts"` — both parse, but forward-slash is the unambiguous choice.

## How to use

```powershell
# Default — looks for ./config.json in current directory
cd c:\project\vLearn2\datamanage
.\build-x64\bin\DataManage.exe pack

# Explicit config path
.\build-x64\bin\DataManage.exe pack --config "C:\some\path\config.json"

# Or via the GUI:
#   1. Launch DataManage.exe
#   2. File → Open Config… → pick your config.json
#   3. Pack → Run Pack…
```

The CLI prints per-file progress and a per-bundle summary; the GUI shows a final MessageBox with output paths + sizes.

## A complete real example for your project

If you want a copy-pasteable starting point, here's one using the alice keys from Stage 5:

```json
{
  "version": 1,
  "pack_mode": { "compress": "zlib", "encrypt": "aes-256-gcm" },
  "signing": {
    "cert_path": "c:/project/vLearn2/datamanage/ca/issued/admins/alice/admin.crt",
    "key_path":  "c:/project/vLearn2/datamanage/ca/issued/admins/alice/admin.key"
  },
  "bundles": [
    {
      "name":       "fonts_editorial",
      "source_dir": "c:/project/vLearn2/flutter_app/assets/fonts/editorial",
      "out_folder": "fonts/editorial"
    },
    {
      "name":       "sherpa_models",
      "source_dir": "c:/data/sherpa-onnx/your_model_dir",
      "out_folder": "models/sherpa"
    }
  ],
  "output_dir": "c:/project/vLearn2/datamanage/output"
}
```

Save that as `c:\project\vLearn2\datamanage\config.json`, run `DataManage.exe pack`, and you'll get `output/fonts_editorial.ddp` + `output/sherpa_models.ddp` — both signed by alice, both AES-256-GCM encrypted, both zlib-compressed. Copy them to `/sdcard/룡마/가상외국어회화/datapacks/` on the device, launch the app, the installer unpacks them into `<appSupport>/datapack_unpacked/fonts/editorial/` and `.../models/sherpa/` respectively.

Want me to write a starter `config.json` to disk for you with paths matched to your tree?
