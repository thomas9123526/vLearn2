# Conversation - Fix next-intl v4 config file not found

| Field | Value |
|---|---|
| Saved | 2026-06-02 18:57:29 |
| Commit | fix: add next-intl v4 request config and plugin to resolve startup crash |
| Project | C:\project\vLearn2 |

---

## User

(runtime error shown in terminal)

```
Error: Couldn't find next-intl config file. Please follow the instructions at https://next-intl.dev/docs/getting-started/app-router
```

## Assistant

next-intl 4.x (installed: 4.13.0) requires two things the previous setup was missing:

1. A `src/i18n/request.ts` file that exports a `getRequestConfig` callback — this is where locale resolution and message loading now live.
2. The `createNextIntlPlugin` wrapper in `next.config.mjs` — without it next-intl can't find its config.

**Files changed:**

- `admin_panel/src/i18n/request.ts` *(new)* — reads `NEXT_LOCALE` cookie, validates against supported locales, dynamically imports the matching JSON file, returns `{ locale, messages }` for next-intl's server pipeline.
- `admin_panel/next.config.mjs` — added `import createNextIntlPlugin from 'next-intl/plugin'` and wrapped `nextConfig` with `withNextIntl(nextConfig)`.
- `admin_panel/src/app/layout.tsx` — simplified: replaced manual cookie-reading + `import` with `getLocale()` / `getMessages()` from `next-intl/server` (those delegate to the request config automatically).

Build passes clean with all 22 routes compiled.

---

## Prompt

(runtime error shown in terminal)

```
Error: Couldn't find next-intl config file. Please follow the instructions at https://next-intl.dev/docs/getting-started/app-router
```
