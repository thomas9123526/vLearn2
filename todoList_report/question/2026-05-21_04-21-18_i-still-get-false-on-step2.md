# I still get false on step2

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-20T19:21:18.766Z

## User

I still get false on step2

## Assistant

Found it — **PowerShell is eating the `$` characters in your hash**, so node never sees the real string. Inside a double-quoted PowerShell command, `$2b`, `$10`, `$dmBR...` are interpreted as variables (all empty), so the hash gets mangled to garbage before node receives it. That's why `compareSync` returns `false` — it's comparing `aaAA11!!` against a corrupted string, not the real hash.

**Fix — use single quotes around the whole `-e` argument** so PowerShell passes it verbatim:

```powershell
node -e 'console.log(require("bcrypt").compareSync("aaAA11!!", "$2b$10$dmBRMJGS4gBIvqFUHQ0Mo.gzJkBWFA3dJgRC50VwE9zGaRum7QAA6"))'
```

In PowerShell, single-quoted strings don't expand `$`, so node gets the literal hash. The JS inside uses double quotes around its own strings.

That should print `true`. After that, you should be able to sign in with `sym1991123` / `aaAA11!!` (assuming the UPDATE from step 1 actually landed, which the `RETURNING` clause will have confirmed).

**Want me to add a tiny script to make this easier in the future?** Something like `backend/scripts/reset-password.mjs` that takes a username + new password and does the whole thing (generate hash, UPDATE, verify) so you never have to worry about shell escaping again. Just say the word.
