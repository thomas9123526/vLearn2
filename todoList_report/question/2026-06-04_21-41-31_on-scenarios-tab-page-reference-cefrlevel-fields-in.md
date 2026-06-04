# on scenarios tab page, reference cefr_level fields in scenario when the user cli

Session: `ec7e9529-1399-4642-b1c1-753f53834cc7`
Saved: 2026-06-04T12:41:31.897Z

## User

on scenarios tab page, reference cefr_level fields in scenario when the user click the level like A1,A2,B1,B2,C1,C2

## Assistant

Let me check the current filter code in `scenarios_screen.dart` to see exactly what it does now:

## Assistant

The current filter at line 56 already does exactly this — `s.cefrLevel` IS the `cefr_level` field from the scenario:

```dart
if (_cefrLevel != null) {
  if (s.cefrLevel != _cefrLevel) return false;  // ← filters by scenario.cefr_level
}
```

When you tap **B1** → `_cefrLevel = 3` → only scenarios where `scenario.cefr_level == 3` pass.

This has been in place since the `difficulty` removal commit. The filter is already wired to `cefr_level`. If the chips appear to not filter anything, the most likely reason is that your scenarios don't have `cefr_level` populated in the database yet — the migration (`1783100000000`) copies `difficulty → cefr_level` for existing rows, but it only runs when the backend starts and applies pending migrations.

To verify: check a scenario in the admin panel — does it show a `cefr_level` value? If all scenarios show blank/null there, the migration hasn't run yet (or the backend needs a restart to pick it up).
