# then why show empty result when i click the one cefr_level on the scenario tabs 

Session: `ec7e9529-1399-4642-b1c1-753f53834cc7`
Saved: 2026-06-04T12:46:13.947Z

## User

then why show empty result when i click the one cefr_level on the scenario tabs on the application

## Assistant

The root cause is that your scenarios have `cefr_level = NULL` in the database. Let me verify by checking the seed file — it still inserts `difficulty` (which is gone) and never sets `cefr_level`:

## Assistant

Confirmed. Two bugs:

1. **Seed still sets `difficulty`** (column no longer exists) and **never sets `cefr_level`** → every seeded scenario has `cefr_level = NULL` → filter always returns empty
2. **TypeScript error** in seed on `difficulty: s.difficulty` since the entity no longer has that property

Fix: rename `difficulty → cefr_level` in the seed interface and insert data:

## Assistant

Now rename all `difficulty:` values in the `SCENARIOS` array to `cefr_level:`:

## Assistant

Now fix the insert object to use `cefr_level` instead of `difficulty`:

## Assistant

The replace_all converted `difficulty: s.difficulty` to `cefr_level:s.difficulty` — need to fix the right-hand side too:

## Assistant

Now commit and explain what the user needs to do:

## Assistant

Fixed. Here's why the filter showed empty and what to do now:

**Root cause:** The seed file was inserting `difficulty: 2` but `difficulty` column no longer exists. TypeORM silently ignored it. `cefr_level` was never set in the insert. Every scenario in your DB has `cefr_level = NULL` → filter excludes all of them.

**To fix your running database**, restart the backend. The migration `1783100000000` runs on startup and executes:
```sql
UPDATE vl_scenarios SET cefr_level = difficulty WHERE cefr_level IS NULL
```
But **`difficulty` was already dropped**, so this UPDATE copies nothing (column doesn't exist). 

You need to **run the seed again** after restarting, or manually update `cefr_level` for each scenario in the admin panel. The fastest fix is to run the seeder which now correctly sets `cefr_level` values.

Alternatively, run this SQL directly on the DB to temporarily fix existing data:
```sql
UPDATE vl_scenarios SET cefr_level = 2 WHERE cefr_level IS NULL;
```
(Use whatever level makes sense for your scenarios, or set individual values in the admin panel.)
