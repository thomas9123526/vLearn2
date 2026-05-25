# DataManage — pack-complete dialog shows compression rate + MB

## What changed

The GUI's "pack complete" MessageBox (`Pack → Run Pack…`) now shows,
per bundle:

- file count
- **source** size — raw bytes + MB
- **packed** size — raw bytes + MB
- **reduction** — bytes + MB saved, plus the percentage smaller

…and a grand-total block across all bundles when more than one was
packed.

### Before

```
Packed 2 bundle(s):

C:\…\fonts_sets.dat
  16 files, 4631678 → 2271977 bytes

C:\…\sherpa_models.dat
  363 files, 174137278 → 152766149 bytes
```

### After

```
Packed 2 bundle(s):

C:\…\fonts_sets.dat
  16 files
  source : 4,631,678 bytes (4.42 MB)
  packed : 2,271,977 bytes (2.17 MB)
  reduced: 2,359,701 bytes (2.25 MB)  —  50.9% smaller

C:\…\sherpa_models.dat
  363 files
  source : 174,137,278 bytes (166.07 MB)
  packed : 152,766,149 bytes (145.69 MB)
  reduced: 21,371,129 bytes (20.38 MB)  —  12.3% smaller

───────────────────────────
Total source : 178,768,956 bytes (170.49 MB)
Total packed : 155,038,126 bytes (147.85 MB)
Total reduced: 23,730,830 bytes (22.63 MB)  —  13.3% smaller
```

## Implementation — `datamanage/src/app.cpp`

Three new helpers in the anonymous namespace:

- `groupDigits(uint64_t)` — inserts thousands separators
  (`4631678` → `4,631,678`) so big byte counts are readable.
- `formatSize(uint64_t)` — `"<grouped> bytes (<N.NN> MB)"`. MB is
  binary (÷ 1024 × 1024), matching what Windows Explorer reports.
- `reductionLine(in, out)` — the size-delta line. Normal case
  `"reduced: … — NN.N% smaller"`. If a bundle ends up *bigger* than
  its source (incompressible data + encryption/header overhead can
  do this), it instead reports `"grew: +… (+NN.N%)"` so the number
  is never misleading.

`onRunPack`'s message builder rewritten to use them, accumulating
`grandIn` / `grandOut` for the total block (shown only when
`results.size() > 1`).

Added `#include <cstdint>` + `#include <cwchar>` (for `std::swprintf`,
used to format the `%.2f` MB and `%.1f` percent values).

## Scope

GUI dialog only — that's the "this dialog" the admin pointed at. The
CLI `pack` output (`cli.cpp::runPack`) still prints its own terser
`in → out bytes` summary; left as-is since the request was scoped to
the GUI MessageBox. Easy to mirror there later if wanted.

## Verification

- `cmake --build build-x64 / build-x86 --config Release` → both
  clean.
- Math check against the screenshot's real numbers
  (fonts_sets 4,631,678 → 2,271,977):
  saved 2,359,701 B = 2.25 MB; 2,359,701 / 4,631,678 = 50.9 %. ✓

## User prompt (verbatim)

> on this dialog, I want show file compression rate, how many size
> reduced.  also show me both bytes size and mb size
