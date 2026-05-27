# how about "In admin panel → Config → set license.public_pem to the contents of l

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-26T09:54:17.739Z

## User

how about "In admin panel → Config → set license.public_pem to the contents of license_leaf_ca.crt"

## Assistant

The cert is at `datamanage\ca\issued\license\leaf\license_leaf_ca.crt`. Here's how to set it:

**Option A — Copy-paste in the admin panel UI**

1. Open that file in any text editor — it looks like:
   ```
   -----BEGIN CERTIFICATE-----
   MIIBxTCCAWugAwIBAgI...
   -----END CERTIFICATE-----
   ```
2. Select and copy the entire content (including the `-----BEGIN/END-----` lines)
3. Open the admin panel → **Config** tab
4. Find the row `license.public_pem`
5. Click Edit, paste the full PEM text, Save

**Option B — Let me read the cert and show you the exact content to paste**

## Assistant

Copy the entire block below and paste it into `license.public_pem` in the admin panel Config:

```
-----BEGIN CERTIFICATE-----
MIIB0DCCAXWgAwIBAgIUX1bO0W5g1OUksBB6PmwsS+9tu8gwCgYIKoZIzj0EAwIw
MzEfMB0GA1UEAwwWdkxlYXJuMiBMaWNlbnNlIEtleSBDQTEQMA4GA1UECgwHdkxl
YXJuMjAeFw0yNjA1MjYwODMyMDZaFw0zMTA1MjUwODMyMDZaMDQxIDAeBgNVBAMM
F3ZMZWFybjIgTGljZW5zZSBMZWFmIENBMRAwDgYDVQQKDAd2TGVhcm4yMFkwEwYH
KoZIzj0CAQYIKoZIzj0DAQcDQgAEKiMKXv76Ca67pXPvPrt85lAGBgI//9VoxJuE
fTECtMAEsHOuhd+YwUBUhtCKWk6hrT3ccnbcd9VHbyrqbhzb8aNmMGQwEgYDVR0T
AQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8EBAMCAQYwHQYDVR0OBBYEFF3HfmNHcDnC
VVg8waY7jfdwhCXLMB8GA1UdIwQYMBaAFFr2tU/ewpzplXTpHz0VBt4ggAX1MAoG
CCqGSM49BAMCA0kAMEYCIQDs5tgmM6r1CyvbQjJ3v6T5vs1poRgm4UEV5QMUTrUB
ngIhAJR5BHz+3xj4HAfJyPf21p0WQ2aeXnM7HuMP4zrVl++U
-----END CERTIFICATE-----
```

The backend's `createPublicKey()` call accepts a full cert PEM — it extracts the public key from it automatically, so you don't need to convert it to a bare public key.
