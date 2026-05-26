# Failed to compile. ./src/app/(dashboard)/license/page.tsx 64:30  Error: `'` can 

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-26T09:57:54.645Z

## User

Failed to compile.

./src/app/(dashboard)/license/page.tsx
64:30  Error: `'` can be escaped with `&apos;`, `&lsquo;`, `&#39;`, `&rsquo;`.  react/no-unescaped-entities

info  - Need to disable some ESLint rules? Learn more here: https://nextjs.org/docs/basic-features/eslint#disabling-rules

## Assistant

Fixed — `app's` → `app&apos;s` on line 64. `react/no-unescaped-entities` requires `'` `"` `<` `>` `{` `}` inside JSX text to be HTML-escaped (or wrapped in an expression like `{"'"}`). The build should compile now. Re-run `npm run build` / `next build`.

If you'd rather not have to remember this for every apostrophe in copy, you can disable the rule once in `.eslintrc.json`:

```json
{
  "rules": { "react/no-unescaped-entities": "off" }
}
```

…but the per-character escape is the conventional Next.js fix.
