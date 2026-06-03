# Error: Couldn't find next-intl config file. Please follow the instructions at ht

Session: `a02819f6-c563-4d87-a349-0daa998cc204`
Saved: 2026-06-02T09:58:02.744Z

## User

Error: Couldn't find next-intl config file. Please follow the instructions at https://next-intl.dev/docs/getting-started/app-router
    at b (C:\project\vLearn2\admin_panel\.next\server\chunks\41.js:5:68127)
    at C:\project\vLearn2\admin_panel\.next\server\chunks\41.js:5:68388
    at C:\project\vLearn2\admin_panel\node_modules\next\dist\compiled\next-server\app-page.runtime.prod.js:12:186465
    at C:\project\vLearn2\admin_panel\.next\server\chunks\41.js:5:69133
    at C:\project\vLearn2\admin_panel\node_modules\next\dist\compiled\next-server\app-page.runtime.prod.js:12:186465
    at C:\project\vLearn2\admin_panel\.next\server\chunks\41.js:5:69458
    at C:\project\vLearn2\admin_panel\node_modules\next\dist\compiled\next-server\app-page.runtime.prod.js:12:186465
    at k (C:\project\vLearn2\admin_panel\.next\server\chunks\41.js:5:70192)
    at em (C:\project\vLearn2\admin_panel\node_modules\next\dist\compiled\next-server\app-page.runtime.prod.js:12:134808)
    at e (C:\project\vLearn2\admin_panel\node_modules\next\dist\compiled\next-server\app-page.runtime.prod.js:12:137693) {
  digest: '2282838122'
}

## Assistant

The error means next-intl can't find its config file. Let me check the installed version and current setup.

## Assistant

next-intl v4 requires a request config file and the plugin wired into `next.config.mjs`. The layout's manual cookie-reading approach worked for older versions but v4 now enforces its own setup. I'll fix this properly.

## Assistant

Now update `next.config.mjs` to use the plugin:

## Assistant

Now simplify `layout.tsx` to use next-intl's own `getLocale()` / `getMessages()` instead of manually reading the cookie (the request config handles that now):

## Assistant

Now let me verify the messages path is correct from `src/i18n/request.ts` — that file is at `admin_panel/src/i18n/request.ts`, so `../../../messages/` goes up three levels to `admin_panel/messages/`. Let me confirm:

## Assistant

The path has one too many `../` levels. From `src/i18n/request.ts`, going up two levels reaches the project root (`admin_panel/`), not three:

## Assistant

Let me verify the plugin export exists and do a quick build check:

## Assistant

Clean build — all routes compiled successfully. Now commit:

## Assistant

Fixed. The problem was that next-intl 4.x enforces its own server-side config pipeline — the v3 pattern of manually reading the cookie in the layout and calling `NextIntlClientProvider` directly is no longer recognized.

Three changes:
- **`src/i18n/request.ts`** (new) — `getRequestConfig` callback: reads `NEXT_LOCALE` cookie, validates it, imports the JSON, returns `{ locale, messages }`
- **`next.config.mjs`** — wrapped with `createNextIntlPlugin('./src/i18n/request.ts')` so next-intl can find its config
- **`layout.tsx`** — simplified to `getLocale()` / `getMessages()` from `next-intl/server`; the cookie logic now lives entirely in the request config where it belongs
