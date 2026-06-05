# I put AI_RAW_LOG=true , but it never log to console for the raw result for ai-pr

Session: `40c2c32e-4bcc-4826-8449-440738f22ef6`
Saved: 2026-06-05T02:23:17.107Z

## User

I put AI_RAW_LOG=true , but it never log to console for the raw result for ai-provider.

## Assistant

The issue is that `const RAW_LOG = process.env['AI_RAW_LOG']` is evaluated **at module import time**, before NestJS's `ConfigModule` has loaded the `.env` file. So the value is always `undefined` at that point.

The fix is to read `process.env` lazily inside the function instead of once at the top.

## Assistant

**Root cause:** `const RAW_LOG = process.env['AI_RAW_LOG']` runs when Node.js first `import`s the file — which happens before NestJS's `ConfigModule.forRoot()` calls `dotenv.config()` to parse `.env`. So `RAW_LOG` was always `undefined`.

**Fix:** read `process.env['AI_RAW_LOG']` inside `rawLog()` at call time, by which point dotenv has already populated `process.env`. No other change needed — restart the backend and the raw logs will appear.
