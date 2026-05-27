# 'EC_KEY_new_by_curve_name': Since OpenSSL 3.0

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-27T02:57:34.145Z

## User

'EC_KEY_new_by_curve_name': Since OpenSSL 3.0

## Assistant

OpenSSL 3.0 deprecated the `EC_KEY_*` API in favor of `EVP_PKEY` keygen. Two spots in [CertIssuer.cpp](thirdparty/KeyGenVS2022/src/CertIssuer.cpp) need to move forward, plus the related `X509_get_notBefore` / `X509_get_notAfter` (also deprecated in 3.0):

## Assistant

Fixed. [src/CertIssuer.cpp](thirdparty/KeyGenVS2022/src/CertIssuer.cpp) now uses the OpenSSL 3.0-clean APIs:

- `EC_KEY_new_by_curve_name` / `EC_KEY_generate_key` / `EVP_PKEY_assign_EC_KEY` → `EVP_PKEY_CTX_new_id(EVP_PKEY_EC, …)` + `EVP_PKEY_keygen_init` + `EVP_PKEY_CTX_set_ec_paramgen_curve_nid` + `EVP_PKEY_keygen`
- `X509_get_notBefore` / `X509_get_notAfter` → `X509_getm_notBefore` / `X509_getm_notAfter`

Same P-256 + SHA-256 leaf cert output, no deprecation warnings. Committed as `cbd3c93`. Rebuild and you should be clean.
