# vendor/

Third-party source trees committed verbatim to the repo. Each gets
pulled into the build via `add_subdirectory(...)` in the root
`CMakeLists.txt`, so the project builds offline on any fresh Windows 10
machine with VS 2022 installed.

Empty in Stage 1 — Stage 1 builds with the standard library only.

Planned trees (each will arrive in its own stage's commit):

- `mbedtls/` — Apache 2.0. Picks AES-256-GCM, ECDSA P-256, ECDH P-256,
  SHA-256, X.509 chain validation. Released Stages 4 / 6 / 7.
- `zstd/` — BSD 3-clause. Block compression. Released Stage 4.
- `nlohmann_json/` — MIT. Single-header JSON serializer for the
  manifest. Released Stage 2.

When a tree lands here, it includes the upstream `LICENSE` file
unchanged and a short `VENDORED.md` noting the exact upstream tag and
the commit hash we vendored.
