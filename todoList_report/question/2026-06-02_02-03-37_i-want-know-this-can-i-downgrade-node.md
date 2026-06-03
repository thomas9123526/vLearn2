# I want know this. Can i downgrade node js version to 18?

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-01T17:03:37.229Z

## User

I want know this. Can i downgrade node js version to 18?

## Assistant

**Yes, but with one caveat.**

- **NestJS 11** requires Node.js **≥ 18.13** — so Node 18 LTS works fine.
- **Next.js 14.2** requires Node.js **≥ 18.17** — also fine on Node 18 LTS.
- **TypeScript 5.7** has no Node version restriction beyond what NestJS/Next need.

Neither `backend/package.json` nor `admin_panel/package.json` declares an `engines` field, so there's no hard lock.

**Minimum safe version: Node 18.17.0** (the LTS release that satisfies both NestJS 11 and Next.js 14's lower bounds).

The only thing to watch: `crypto.hkdf` / `crypto.webcrypto` APIs used in some NestJS internals require Node 18+, which you already satisfy. The `DB_FIELD_ENCRYPTION_KEY` AES logic in `field-encryption.ts` uses `node:crypto` which is stable on Node 18.

So: **Node 18 LTS (18.20.x) is safe to use.**
