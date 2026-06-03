import { webcrypto } from 'node:crypto';

// Node.js 18 CJS context does not expose the Web Crypto API as a bare `crypto`
// global. @nestjs/typeorm calls crypto.randomUUID() at module-load time, which
// crashes on Node 18 before the global is populated. Node 19+ fixed this.
// This file must be the very first import in main.ts so the global exists
// before any NestJS module (and therefore TypeORM) is required.
if (!globalThis.crypto) {
  (globalThis as any).crypto = webcrypto;
}
