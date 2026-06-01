# Conversation - Fix crypto not defined Node 18 polyfill

| Field | Value |
|---|---|
| Saved | 2026-06-02 08:01:00 |
| Commit | fix: polyfill globalThis.crypto for Node 18 to fix @nestjs/typeorm crash |
| Project | C:\project\vLearn2 |

---

## User

```
ReferenceError: crypto is not defined
    at generateString (typeorm.utils.js:136)
    at TypeOrmCoreModule.forRootAsync
```
How can i fix it?

## Assistant

Root cause: Node.js 18 CJS context does not expose the Web Crypto API as a bare `crypto` global
(that was only guaranteed in Node.js 19+). `@nestjs/typeorm` calls `crypto.randomUUID()` at
module-load time — before `main.ts` body code runs — so the crash happens immediately on startup.

Fix: created `src/polyfill.ts` which imports `webcrypto` from `node:crypto` and assigns it to
`globalThis.crypto` if not already set. Made it the very first import in `main.ts` so it is
evaluated (as a CJS `require()`) before any NestJS/TypeORM module is loaded.

---

## Prompt

ReferenceError: crypto is not defined at generateString typeorm.utils.js Node 18 crash
