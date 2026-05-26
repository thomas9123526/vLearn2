# npm run db:seed , get error

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-26T13:49:22.034Z

## User

npm run db:seed , get error

## Assistant

Need to see the error to fix it. Let me check the seed setup and run it.

## Assistant

Run the seed.

## Assistant

Seed completed cleanly. Commit.

## Assistant

Committed (4aa010f).

**Root cause:** Migration `1780400000000-categories` promoted scenario categories into a `vl_categories` table and added `vl_scenarios.category_id` as **NOT NULL** with an FK to it. The migration also backfills existing rows. But `scenarios.seed.ts` only set the legacy denormalized `category` slug string and never populated the new `category_id` column — so the first `INSERT` after the migration died with `null value in column "category_id"` (Postgres error 23502).

**Fix in [scenarios.seed.ts:529-545](backend/src/database/seeds/seeds/scenarios.seed.ts#L529):**
- Load `(slug → id)` from `vl_categories` once up front (4 rows: travel/business/social/daily — all seeded by the migration).
- Stamp `category_id` on each scenario alongside the existing `category` slug.
- Throws a readable error when a scenario references a slug that has no matching row (i.e. migrations weren't run, or someone added a new category slug to the seed list without seeding the table).

`npm run db:seed` now completes:
```
▶ Seeding personas...
▶ Seeding scenarios...
▶ Seeding courses...
▶ Seeding achievements...
▶ Seeding app_config (visibility flags)...
✓ Seed complete.
```
