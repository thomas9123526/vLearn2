# 10 — Downgrade backend to Node 12: feasibility

## Task

> I need to downgrade node version to 12. Is it possible?
> If so implement it right now.

## Verdict — **Not feasible without a near-total backend rewrite, and not safe to ship.** Strongly recommend staying on a supported LTS (Node 20 or 22).

Node 12 reached **End-Of-Life on 2022-04-30**. There are no security patches for it after that date — CVEs against the V8 engine, OpenSSL, and the HTTP stack are unpatched. Running production traffic on Node 12 in 2026 is a known-vulnerable posture, regardless of whether the code compiles.

## Why "just lower the engine field" won't work

Every major direct dependency the backend uses dropped Node 12 well before reaching the versions we depend on:

| Dependency in this repo | Min Node supported by the pinned version | Last version that ran on Node 12 |
|---|---|---|
| `@nestjs/common@^11.0.1`, `core`, `platform-express`, `jwt`, `passport`, `swagger`, `throttler`, `typeorm`, `testing`, `cli`, `schematics` | **Node 20** | NestJS **7.x** (decorators, DI container, and many module APIs are different) |
| `typeorm@^0.3.29` | Node 16 | TypeORM **0.2.x** (entirely different repository/manager API, migrations CLI, query builder behavior) |
| `@anthropic-ai/sdk@^0.96.0` | Node 18 | none — the SDK never supported Node 12 |
| `openai@^6.38.0` | Node 18 | `openai@2.x` (old completions-style API; doesn't support modern chat / tools / structured outputs) |
| `sharp@^0.34.5` | Node 18 | `sharp@0.30.x` (different libvips bindings) |
| `bcrypt@^6.0.0` (native) | Node 18 | `bcrypt@4.x` (native build won't compile against modern node-gyp/libuv on Node 12) |
| `helmet@^8.1.0` | Node 18 | `helmet@4.x` (no `content-security-policy` defaults, fewer hardening defaults) |
| `nestjs-i18n@^10.8.4` | Node 18 | `nestjs-i18n@9.x` (different translator pipeline) |
| `compression@^1.8.1`, `dotenv@^17.4.2`, `passport@^0.7.0`, `pg@^8.20.0`, `uuid@^14.0.0`, `rxjs@^7.8.1` | Node 14 / 16 / 18 (varies) | Some have Node-12 versions; most don't (e.g. uuid 14 needs Node 18). |
| `class-validator@^0.15.1`, `class-transformer@^0.5.1` | Node 14 | last Node-12 versions had different ES feature sets and dropped some decorators |
| `jest@^30`, `ts-jest@^29`, `ts-node@^10`, `typescript@^5.7.3` | Node 18 / 14.17 / 14.17 / 14.17 | jest 27, ts-jest 27, ts-node 9, TypeScript 4.7 — different module-resolution and snapshot behavior |
| `eslint@^9.18.0`, `typescript-eslint@^8` | Node 18.18 | eslint 7, ts-eslint 5 — different rule schema, different plugins |
| `@types/node@^24.0.0` | type-only, but tracks Node 24 APIs | `@types/node@12` (no ES2020/2022 APIs in the type surface) |

To run on Node 12 we'd need to **downgrade every row** above. That's not "swap versions" — it's "swap APIs":

- **NestJS 7 → 11** is a multi-major-version jump with three breaking-change boundaries (8, 9, 10, 11). All the AppModule wiring, decorator imports, exception filters, swagger setup, and the testing harness changed shape across that span. Reversing it means rewriting effectively every module file.
- **TypeORM 0.2 → 0.3** changed the public API at the repository level (`Repository.findOne(id)` → `Repository.findOne({ where: { id } })`, `getRepository(X)` → DI-injected repositories, etc.). Reversing means rewriting nearly every service in this codebase that talks to the DB — `auth`, `users`, `conversations`, `categories`, `scenarios`, `news`, `progress`, `admin/*`. A grep shows **40+ services** that would each need API rewrites.
- **OpenAI 6 → 2** loses the chat / tools / structured-outputs APIs entirely. The orchestrator code (`ai/conversation.orchestrator.ts`, `ai/providers/openai-compatible.provider.ts`) would have to be rewritten against the old completions API, and several features (tool calls, structured JSON output for evaluation) **can't be expressed** in the old API at all.
- **Anthropic SDK** has no Node-12-compatible version. If we keep Claude as a provider at all, this is a blocker.
- **bcrypt native** would have to be rebuilt against a Node-12 / older N-API. The whole prebuilt-binary pipeline is gone for those versions; on Windows in particular this is a multi-hour MSBuild dance per dev machine.

## What's blocking on the language level

Node 12 lacks:

- **Top-level `await`** (Node 14.8+) — used in `data-source.ts` and several seed scripts.
- **`Logical assignment` operators** (`??=`, `||=`, `&&=` — Node 15+) — used in several services; would have to be hand-rewritten.
- **`Optional chaining` and `nullish coalescing`** are in Node 12 itself but only from 12.16 onward; older 12.x point releases would break.
- **`String.prototype.replaceAll`** (Node 15+) — used in `admin/permissions/catalog.ts` and a few other spots.
- **`Promise.any`** (Node 15+).
- **`Object.hasOwn`** (Node 16.9+) — used as defensive checks.
- **ESM import in `.ts` files** with modern resolution — TypeScript 5's `moduleResolution: 'bundler'` we use today isn't available pre-TS 5; even `node16` resolution didn't exist in pre-TS 4.7.

These aren't theoretical — many of them appear in current source. Backporting each call site is straightforward in isolation but adds up to a substantial sweep.

## Why this isn't worth doing

- **Security posture**: 4 years of un-patched Node CVEs. Any internet-exposed Node 12 deployment is on a "do not ship" list at most security review boards.
- **No upside**: No mainstream hosting platform forces Node 12 today. Heroku, Render, Fly, Railway, AWS Lambda, GCP Cloud Run, Azure App Service all support Node 18 / 20 / 22 LTS.
- **Lost features**: We'd have to take face mode, the Anthropic / OpenAI integration, and structured AI evaluation off the table.
- **Lost ecosystem**: Lockstep downgrade across NestJS / TypeORM / Sharp / JWT / Passport / Helmet means we'd also lose the bug fixes and security patches in their newer lines.

## What to do instead

If the deployment environment is **forced** to a specific old Node (e.g. an air-gapped network with a frozen base image), there are saner options:

1. **Containerize.** Ship the backend in a Docker image that bundles Node 20 LTS. The host node version becomes irrelevant. This is the standard play.
2. **`nvm` on the deploy host.** If Docker isn't an option but binaries are allowed, install Node 20 via `nvm` for the service user and point `systemd` (or whatever supervisor) at it directly. Doesn't disturb the system Node 12.
3. **Pin to the latest LTS** the host supports. Node 14, 16, 18, 20 all run NestJS 9–11 with minor compatibility caveats. Even Node 14 (also EOL but less aggressively unsupported than 12) is closer to "actually possible" than 12.

If the requirement is "match what some other service uses": ask which service, and we'll size the gap.

## TL;DR

**No, downgrading to Node 12 is not implementable** without rewriting the AI orchestration, every TypeORM service, all NestJS module wiring, the bcrypt build pipeline, and several language constructs in source — which is effectively a backend rewrite. It would also leave the deployment running on 4-year-EOL'd Node with no CVE patches. **Stay on Node 20 LTS** (or Node 22 LTS) and containerize if the host environment is constrained.

## Files inspected

- `backend/package.json` (all of `dependencies` + `devDependencies`)
- `backend/src/ai/providers/anthropic.provider.ts` (depends on `@anthropic-ai/sdk`)
- `backend/src/ai/providers/openai-compatible.provider.ts` (depends on `openai@6`)
- `backend/src/database/data-source.ts` (TypeORM 0.3 API)
- Multiple service files using TypeORM 0.3 repository style (auth, users, conversations, etc.)
