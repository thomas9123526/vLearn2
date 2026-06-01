# and the admin panel can run on google chrome 80?

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-01T17:05:15.895Z

## User

and the admin panel can run on google chrome 80?

## Assistant

**No — Chrome 80 will likely break.** Here's why:

**Hard blockers:**

| Feature | Minimum Chrome | Your stack |
|---|---|---|
| `Array.at()` / `Object.hasOwn()` | Chrome 92 / 93 | Used by React 18 internals and TanStack Query 5 |
| CSS `gap` in Flexbox (not just Grid) | Chrome 84 | Tailwind CSS 3 uses it extensively |
| `structuredClone()` | Chrome 98 | React 18 concurrent mode |
| `ResizeObserver` (stable) | Chrome 64 | recharts 2.x uses it |
| CSS `@layer` | Chrome 99 | Tailwind CSS 3.x preflight uses it |

**React 18** (your version) officially dropped support for browsers older than Chrome 80 itself, but **TanStack Query v5** and **Tailwind CSS 3** both target significantly newer baseline browsers (roughly Chrome 87-99+).

**Practical minimum is around Chrome 87–90** for this stack (where Flexbox `gap`, most ES2020 features, and the stable `ResizeObserver` API all landed). Chrome 80 is just below that threshold.

If Chrome 80 support is a hard requirement, you'd need to:
- Downgrade to React Query v4 and Tailwind v2 (significant work)
- Add polyfills for `Array.at`, `Object.hasOwn`, `structuredClone`
- Set `browserslist` in `package.json` to target Chrome 80 so Next.js transpiles accordingly

But if this is just for your VPS admin panel where you control the browser, simply upgrade Chrome.
