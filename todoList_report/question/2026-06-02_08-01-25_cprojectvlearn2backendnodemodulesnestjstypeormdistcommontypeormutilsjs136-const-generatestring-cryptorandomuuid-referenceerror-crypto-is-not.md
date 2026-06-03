# C:\project\vLearn2\backend\node_modules\@nestjs\typeorm\dist\common\typeorm.util

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-01T23:01:25.257Z

## User

C:\project\vLearn2\backend\node_modules\@nestjs\typeorm\dist\common\typeorm.utils.js:136
const generateString = () => crypto.randomUUID();
                                    ^

ReferenceError: crypto is not defined
    at generateString (C:\project\vLearn2\backend\node_modules\@nestjs\typeorm\dist\common\typeorm.utils.js:136:37)
    at TypeOrmCoreModule.forRootAsync (C:\project\vLearn2\backend\node_modules\@nestjs\typeorm\dist\typeorm-core.module.js:85:62)
    at TypeOrmModule.forRootAsync (C:\project\vLearn2\backend\node_modules\@nestjs\typeorm\dist\typeorm.module.js:38:63)
    at Object.<anonymous> (C:\project\vLearn2\backend\src\app.module.ts:29:19)
    at Module._compile (node:internal/modules/cjs/loader:1364:14)
    at Module._extensions..js (node:internal/modules/cjs/loader:1422:10)
    at Module.load (node:internal/modules/cjs/loader:1203:32)
    at Module._load (node:internal/modules/cjs/loader:1019:12)
    at Module.require (node:internal/modules/cjs/loader:1231:19)
    at require (node:internal/modules/helpers:177:18)

How can i fix it?

## Assistant

The `crypto` global (Web Crypto API) isn't auto-populated in Node.js 18's CJS module context — it was only made a true global in Node.js 19. `@nestjs/typeorm` calls `crypto.randomUUID()` at module load time, before `main.ts` body runs, so it needs to be polyfilled before any imports are evaluated.

The fix is a side-effect import that runs first:

## Assistant

Now make it the first import in `main.ts`:

## Assistant

Now commit with story:

## Assistant

The crash is fixed. What happened:

- **Node 18** exposes `globalThis.crypto` (Web Crypto) but doesn't put `crypto` into the bare global scope of CJS modules — that only became automatic in Node 19.
- `@nestjs/typeorm` calls `crypto.randomUUID()` without importing `crypto`, so it crashes at module-load time, before any of your `main.ts` body code runs.
- **Fix:** [src/polyfill.ts](backend/src/polyfill.ts) assigns `webcrypto` to `globalThis.crypto`, and it's the very first `import` in [src/main.ts](backend/src/main.ts) so it runs (as a CJS `require`) before TypeORM is ever touched.
