# which cert do i have to input?

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-27T03:11:47.059Z

## User

which cert do i have to input?

## Assistant

Let me check what the project has for the Leaf CA setup:

## Assistant

You already have a Leaf CA generated in this repo. Point the GUI at these two files:

| Field | File |
| --- | --- |
| **Leaf CA cert (PEM)** | `c:\project\vLearn2\datamanage\ca\issued\license\leaf\license_leaf_ca.crt` |
| **Leaf CA key (PEM)**  | `c:\project\vLearn2\datamanage\ca\issued\license\leaf\license_leaf_ca.key` |

Click **Browse...** next to each row and pick them. The remembered paths persist in the registry so you only do this once per workstation.

Context on the chain (see [datamanage/ca/license/README.md](datamanage/ca/license/README.md) for the full design):

```
License Root CA   (self-signed, offline, 30 yr)
       ↓ signs
License Key CA    (semi-offline, 20 yr)
       ↓ signs
License Leaf CA   ← KeyGenVS2022 loads this pair
       ↓ signs
.lic file         ← what the GUI emits for each device
```

The Leaf CA is the only one the GUI touches. The chain above it (Root + Key) is what the backend's `LicenseService.verify` uses to validate a `.lic` blob coming back from a device; you generate that chain once via the `01_…` → `04_…` scripts under `datamanage/ca/license/` and store it in `vl_app_config.license.public_pem` on the backend.

If you ever need to regenerate the leaf — e.g. after the 5-year validity expires or if the key is suspected stolen — run `datamanage\ca\license\03_make_leaf_ca.ps1` again (the script refuses to overwrite without `-Force`).
