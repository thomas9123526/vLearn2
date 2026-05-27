# if i run license\01_make_root_ca.ps1, where the ca output?

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-26T08:27:58.884Z

## User

if i run license\01_make_root_ca.ps1, where the ca output?

## Assistant

Output lands at:

```
datamanage\ca\issued\license\root\
  license_root_ca.key   ← private key (never commit)
  license_root_ca.crt   ← self-signed root cert
  license_root_ca.srl   ← serial counter (created by step 02)
```

That folder resolves relative to the script's own location (`$here = Split-Path -Parent $MyInvocation.MyCommand.Path`), then goes `../issued/license/root`. So the full path from the repo root is:

```
c:\project\vLearn2\datamanage\ca\issued\license\root\
```

The `ca/issued/` subtree is gitignored, so the key won't accidentally be committed.
