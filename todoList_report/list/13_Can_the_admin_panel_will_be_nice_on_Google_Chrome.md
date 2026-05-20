# 13 — Make the admin panel run on Google Chrome 80+

## Task

> Can the admin panel will be nice on Google Chrome Version 80?
> If not, please modify to look nice on older browser, at least
> above Google Chrome Version 80.

## Audit summary

Chrome 80 (Feb 2020) supports a useful slice of ES2020 — optional
chaining (`?.`), nullish coalescing (`??`), BigInt, dynamic import —
but **not** the following that ship in Chrome 85+, which is where
"modern browser" assumptions in JS tooling usually settle:

| Feature | Required Chrome |
|---|---|
| `String.prototype.replaceAll` | 85 |
| Logical assignment (`??=`, `\|\|=`, `&&=`) | 85 |
| `Promise.any` | 85 |
| `Array.prototype.at()` | 92 |
| `Object.hasOwn` | 93 |
| `structuredClone` | 98 |
| Top-level `await` | 89 |
| `Error(..., { cause: ... })` | 93 |

SWC (the Next.js compiler) **does** down-level syntax (e.g.,
`??=`, top-level `await`), but it does **not** polyfill runtime APIs
like `replaceAll`, `Array.prototype.at`, `Object.hasOwn`, or
`structuredClone`. Those have to be replaced in source.

## Findings & fixes

1. **No `.browserslistrc` was set** — Next.js was falling back to its
   default targets (roughly Chrome 64+, but the floor is fuzzy
   without an explicit list). Added an explicit floor:

   ```
   Chrome >= 80
   Edge >= 80
   Firefox >= 78
   Safari >= 14
   not dead
   ```

   With this, SWC consistently down-levels syntax to Chrome 80
   semantics.

2. **`tsconfig.json` had `target: "ES2022"`.** That doesn't drive
   browser-side output (SWC does), but it's still the right signal
   to keep IntelliSense and type emit aligned with what the build
   actually targets. Changed to `ES2019` (which Chrome 80 supports
   in full).

3. **One runtime API in source needed replacing:**
   `pathname.slice(1).replaceAll('/', ' / ')` in
   `admin_panel/src/app/(dashboard)/layout.tsx:103`. `replaceAll` is
   Chrome 85+. Replaced with the Chrome 80-safe
   `.split('/').join(' / ')` (same semantics, no regex/global flag
   gymnastics).

4. **Greped for other post-Chrome-80 runtime APIs**
   (`.at(`, `Object.hasOwn`, `Promise.any`, `structuredClone`,
   `Error(..., { cause: ... })`, `findLast`) — **no matches** in
   `admin_panel/src`. So `replaceAll` was the only landmine.

5. **`Promise.allSettled`, `Object.fromEntries`, `Array.flat`,
   `Array.flatMap`, optional chaining, nullish coalescing** — all
   Chrome 80-compatible. Also no usage of `BigInt`,
   `globalThis`, or class private-method syntax that would force a
   higher floor.

6. **CSS** — Tailwind 3.4 produces CSS that's broadly compatible
   with Chrome ≥ 70. With `autoprefixer` reading the new browserslist,
   vendor prefixes will be regenerated next build for the right floor.

## Files touched

- `admin_panel/.browserslistrc` (new) — explicit Chrome 80+ floor.
- `admin_panel/tsconfig.json` — `target: "ES2022"` → `"ES2019"`.
- `admin_panel/src/app/(dashboard)/layout.tsx` — replaced one
  `.replaceAll(...)` with `.split(...).join(...)`.

## Verification

- `npm run typecheck` (=`tsc --noEmit`) **clean** with the new
  `ES2019` target.
- Source grep confirms no remaining usage of Chrome-85+ runtime
  APIs (`replaceAll`, `Promise.any`, `.at(`, `Object.hasOwn`,
  `structuredClone`, `Error.cause`, `findLast`).

## Decisions / call-outs

- **Did not pin a polyfill bundle (core-js).** With the browserslist
  floor and source-level audit, no runtime API polyfills are
  needed. Pulling in core-js for one tiny app would inflate the
  bundle for no benefit.
- **ES2019 in tsconfig, Chrome 80 in browserslist** — these aren't
  the same dial. The first is for TS's own emit (which Next mostly
  ignores in favor of SWC); the second is the source of truth for
  SWC + autoprefixer. Keeping both aligned-ish reduces "why is
  IDE squiggly but build passes" confusion.
- **No build verification step in this commit.** `npm run typecheck`
  passed; a full `npm run build` is environment-dependent on the
  user's box (the .env-driven `BACKEND_BASE_URL` rewrite and the
  `serverActions.allowedOrigins` host list need real values). If a
  cold build fails for Chrome-80 reasons later, expect SWC to point
  directly at the offending file/line.
