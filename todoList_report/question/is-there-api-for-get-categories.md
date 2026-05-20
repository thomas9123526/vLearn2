# is there api for get categories?

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-20T12:40:42.440Z

## User

is there api for get categories?

## Assistant

**Short answer: no — there's no `GET /categories` endpoint.**

The categories aren't stored in their own table or exposed as an API. They're a hard-coded TypeScript union in [scenario.entity.ts:10-14](backend/src/database/entities/scenario.entity.ts#L10-L14):

```ts
export type ScenarioCategory = 'travel' | 'business' | 'social' | 'daily';
```

Where the value is used:

- **Scenarios** carry a `category` column ([scenarios.module.ts:15-19](backend/src/scenarios/scenarios.module.ts#L15-L19)) — you can *filter by* category via `GET /api/scenarios?category=travel`, but you can't *list* categories.
- **Admin scenario edit** also imports the same TS union ([admin-scenarios.controller.ts](backend/src/admin/admin-scenarios.controller.ts)).

Want me to add a `GET /api/scenarios/categories` endpoint? Two reasonable implementations:

1. **Static** — return the four hard-coded values from the union. Cheap, no DB hit, but stale if the enum grows.
2. **Dynamic** — `SELECT DISTINCT category FROM vl_scenarios WHERE status='published'`. Reflects what's actually live.

Tell me which (or both, e.g. `?source=db` flag) and I'll wire it up.
