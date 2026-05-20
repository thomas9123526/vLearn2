# Task 70 — Backend API: find and fix errors

## Scope
Audit `backend/` (NestJS) for compile errors, lint errors, and obvious code
defects. Fix everything found.

## Audit performed
1. `npx tsc --noEmit` → exit 0 (no TypeScript compile errors)
2. `npx nest build` → exit 0 (build succeeded)
3. `npx eslint "src/**/*.ts"` → many prettier formatting differences plus
   `49 real errors`
4. After fixes: `npx eslint "src/**/*.ts" --rule "prettier/prettier: off"` →
   `0 errors, 10 warnings` (warnings are stale `eslint-disable no-console`
   directives in `database/seeds/*` and `main.ts`, kept for clarity)
5. Final `npx nest build` → exit 0

## Root causes & fixes

### 1. Missing `@types/*` packages caused 22 "unsafe any" errors
`bcrypt`, `passport-jwt`, `passport-local`, `passport`, `compression` were
imported but their type packages were not installed. ESLint's
`no-unsafe-*` rules treated every call/member access as untyped.

**Fix:**
```bash
npm i -D @types/bcrypt @types/passport-jwt @types/passport-local \
        @types/passport @types/compression
```
Files newly satisfied: `auth/auth.service.ts`, `auth/strategies/jwt.strategy.ts`,
`users/users.service.ts`, `admin/admins/admin-auth.service.ts`,
`admin/admins/admin-admins.controller.ts`, `main.ts`.

### 2. `permission.guard.ts` – unsafe `any` on request user
Changed `ctx.switchToHttp().getRequest()` to a typed generic so the cast
is no longer required.

### 3. `current-user.decorator.ts` – unsafe `any` on request
Same fix: typed `getRequest<{ user: JwtPayload }>()` so the body of the
decorator no longer casts.

### 4. `admin-scenarios.controller.ts` – unused `ApiOperation` import
Removed.

### 5. `news/news.module.ts`
* Removed unused `I18nText` import.
* `unreadCount()` typed the raw query result as
  `Array<{ count: number }>` so the index access is no longer unsafe.

### 6. `ai/prompt-builder.service.ts`
The closure took `I18nText | unknown` (redundant — `unknown` swallows the
other constituent). Narrowed to `unknown`.

### 7. `ai/providers/openai-compatible.provider.ts`
Three unnecessary `as` casts removed:
* `m.role as 'user' | 'assistant'` (the union already matches the field).
* `as OpenAI.ChatCompletionCreateParams['response_format']`.
* `lines[lines.length - 1]!` non-null assertion.

### 8. `conversations/conversations.service.ts`
Same redundant `m.role as 'user' | 'assistant'` casts in two places.

### 9. `progress/progress.module.ts`
Redundant `existing[key]!` assertion — the `if (existing && existing[key] != null)`
guard already narrows.

### 10. `guard/content-guard.service.ts`
`let warnMatches: string[] = []` was never reassigned. Changed to `const`.

## Files modified
| File | Change |
| --- | --- |
| `backend/package.json` | Added five `@types/*` devDependencies |
| `src/admin/admin-scenarios.controller.ts` | Drop unused `ApiOperation` |
| `src/admin/permissions/permission.guard.ts` | Typed `getRequest<>()` |
| `src/auth/decorators/current-user.decorator.ts` | Typed `getRequest<>()` |
| `src/ai/prompt-builder.service.ts` | Narrow `en()` param to `unknown` |
| `src/ai/providers/openai-compatible.provider.ts` | Removed 3 unnecessary casts |
| `src/conversations/conversations.service.ts` | Removed 2 unnecessary casts |
| `src/progress/progress.module.ts` | Dropped `!` non-null assertion |
| `src/guard/content-guard.service.ts` | `let` → `const` |
| `src/news/news.module.ts` | Dropped unused import; typed raw SQL row |

## Final verification

```text
> npx tsc --noEmit
exit 0

> npx nest build
exit 0

> npx eslint "src/**/*.ts" --rule "prettier/prettier: off"
0 errors, 10 warnings (stale eslint-disable directives only)
```

No runtime / behavioural changes — every fix is type-level or cosmetic.
