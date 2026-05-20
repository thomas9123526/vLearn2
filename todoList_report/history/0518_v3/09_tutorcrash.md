# 09_tutorcrash — Two bugs introduced by task 08

## Ask

> When I tap edit for tutors in admin panel, I get message like this:
> `Error: An unsupported type was passed to use(): [object Object]`
>
> In console:
> `Type '{ status?: string | undefined; scenario_id?: string | undefined; user_id: string; }' is not assignable to type 'FindOptionsWhere<ConversationSessionEntity> | ...'.`

---

## Bug 1 — Admin panel: `use(params)` crashes on persona edit page

### Root cause

The persona edit page was written with Next.js 15 semantics where dynamic route params are Promises and must be unwrapped with `use()`. But this project runs **Next.js 14.2.5**, where params are passed as a plain `{ id: string }` object directly.

Calling `use({ id: 'uuid' })` (a plain object, not a Promise) throws:
```
Error: An unsupported type was passed to use(): [object Object]
```

### Fix

**`admin_panel/src/app/(dashboard)/personas/[id]/page.tsx`**

```tsx
// Before
import { use, useEffect, useState } from 'react';
type RouteParams = Promise<{ id: string }>;
export default function EditPersonaPage({ params }: { params: RouteParams }) {
  const { id } = use(params);

// After
import { useEffect, useState } from 'react';
export default function EditPersonaPage({ params }: { params: { id: string } }) {
  const { id } = params;
```

Removed `use` from the import, removed the `RouteParams` type alias, and destructured `id` directly.

---

## Bug 2 — Backend: TypeORM `FindOptionsWhere` type error

### Root cause

Task 08 added optional `scenarioId` and `status` filters to `listForUser` using a conditional spread:

```ts
where: {
  user_id: userId,
  ...(scenarioId ? { scenario_id: scenarioId } : {}),
  ...(status ? { status } : {}),
},
```

TypeScript infers the type of this object as:
```ts
{ user_id: string; scenario_id?: string | undefined; status?: string | undefined }
```

The `status?: string | undefined` is not assignable to `FindOptionsWhere<ConversationSessionEntity>` because:
- `status` is typed as `SessionStatus = 'active' | 'completed' | 'abandoned'` on the entity, not `string`
- The spread infers optional (`?`) keys whose value could be `undefined`, which TypeORM's where type doesn't permit

### Fix

**`backend/src/conversations/conversations.service.ts`**

Built the where object explicitly using `FindOptionsWhere<ConversationSessionEntity>` and cast `status` to `SessionStatus`:

```ts
import { FindOptionsWhere, Repository } from 'typeorm';
import { ConversationSessionEntity, SessionStatus } from '...';

const where: FindOptionsWhere<ConversationSessionEntity> = { user_id: userId };
if (scenarioId) where.scenario_id = scenarioId;
if (status) where.status = status as SessionStatus;

const rows = await this.sessions.find({
  where,
  order: { started_at: 'DESC' },
  take: limit,
});
```

The `as SessionStatus` cast is safe because the query param comes from a typed client that only sends valid values (`'active'`, `'completed'`, `'abandoned'`).

---

## Files changed

| File | Change |
|------|--------|
| [admin_panel/src/app/(dashboard)/personas/[id]/page.tsx](../../admin_panel/src/app/(dashboard)/personas/[id]/page.tsx) | Removed `use` import and `RouteParams` type; destructure `id` directly from `params` |
| [backend/src/conversations/conversations.service.ts](../../backend/src/conversations/conversations.service.ts) | Added `FindOptionsWhere` + `SessionStatus` imports; replaced conditional spread with explicit where builder |
