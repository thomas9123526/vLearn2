# when i move backend to node20 environment, is it no matter for crypto?

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-01T23:02:15.001Z

## User

when i move backend to node20 environment, is it no matter for crypto?

## Assistant

No issue on Node 20. The `globalThis.crypto` global was stabilized and made available automatically starting in **Node 19**. On Node 20 LTS, `crypto.randomUUID()` works as a bare global with no polyfill needed.

The polyfill in [src/polyfill.ts](backend/src/polyfill.ts) is safe on Node 20 too — it checks `if (!globalThis.crypto)` before assigning, so it's a no-op when the global already exists. No need to remove it when you upgrade.
