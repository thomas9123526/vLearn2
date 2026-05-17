# Editorial font group

Magazine-style: serif headings + clean sans body.

## Bundled files (variable fonts)

| File | Family in pubspec | Role |
|------|-------------------|------|
| `Lora.ttf` | `EditorialHeading` | Serif heading |
| `Inter.ttf` | `EditorialBody` | Sans body |
| `JetBrainsMono.ttf` | `EditorialMono` | Mono / code |

These are **variable** TTFs — one file per family carries the full weight axis. Flutter selects the right axis position from `TextStyle(fontWeight: …)` automatically.

## Sources (all OFL 1.1)

| Family | Upstream |
|--------|----------|
| Lora | https://github.com/cyrealtype/Lora-Cyrillic (mirrored via google/fonts) |
| Inter | https://github.com/rsms/inter (mirrored via google/fonts) |
| JetBrains Mono | https://github.com/JetBrains/JetBrainsMono (mirrored via google/fonts) |

Attribution lives in [`../LICENSES.md`](../LICENSES.md).
