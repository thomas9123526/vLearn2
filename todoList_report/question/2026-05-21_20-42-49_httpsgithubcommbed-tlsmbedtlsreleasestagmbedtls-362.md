# https://github.com/Mbed-TLS/mbedtls/releases/tag/mbedtls-3.6.2

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-21T11:42:49.591Z

## User

https://github.com/Mbed-TLS/mbedtls/releases/tag/mbedtls-3.6.2

## Assistant

That release page has source archives and signature files. Here are the direct download commands:

## Source tarball (most common)
```powershell
# .tar.bz2 (smallest)
curl -L -o mbedtls-3.6.2.tar.bz2 https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-3.6.2/mbedtls-3.6.2.tar.bz2

# .zip (Windows-friendly)
curl -L -o mbedtls-3.6.2.zip https://github.com/Mbed-TLS/mbedtls/archive/refs/tags/mbedtls-3.6.2.zip
```

## Via `gh` CLI (downloads all assets)
```powershell
gh release download mbedtls-3.6.2 --repo Mbed-TLS/mbedtls
```

## Via PowerShell native
```powershell
Invoke-WebRequest `
  -Uri "https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-3.6.2/mbedtls-3.6.2.tar.bz2" `
  -OutFile mbedtls-3.6.2.tar.bz2
```

## Verify signature (optional)
The release also publishes a `.asc` GPG signature:
```powershell
curl -L -o mbedtls-3.6.2.tar.bz2.asc https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-3.6.2/mbedtls-3.6.2.tar.bz2.asc
gpg --verify mbedtls-3.6.2.tar.bz2.asc mbedtls-3.6.2.tar.bz2
```

Want me to run one of these for you?
