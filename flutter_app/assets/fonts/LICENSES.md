# Bundled font licenses

All fonts shipped under [`assets/fonts/`](.) are distributed under the **SIL Open Font License 1.1** (OFL 1.1). Bundling inside a closed-source app is explicitly permitted by the license, provided the OFL.txt for each typeface is included.

Every bundled `.ttf` is a **variable font** — one file per family carries the full weight axis. Flutter's text engine maps `TextStyle(fontWeight: …)` onto the axis automatically.

| Family | Bundled filename | License | Upstream | Used in groups |
|--------|------------------|---------|----------|----------------|
| Inter | `Inter.ttf` | OFL 1.1 | https://github.com/rsms/inter (mirrored via google/fonts) | editorial, modern |
| Lora | `Lora.ttf` | OFL 1.1 | https://github.com/cyrealtype/Lora-Cyrillic (mirrored via google/fonts) | editorial |
| Quicksand | `Quicksand.ttf` | OFL 1.1 | https://github.com/andrew-paglinawan/QuicksandFamily (mirrored via google/fonts) | friendly |
| Nunito | `Nunito.ttf` | OFL 1.1 | https://github.com/googlefonts/nunito (mirrored via google/fonts) | friendly |
| Playfair Display | `PlayfairDisplay.ttf` | OFL 1.1 | https://github.com/clauseggers/Playfair (mirrored via google/fonts) | classic |
| Source Serif 4 | `SourceSerif4.ttf` | OFL 1.1 | https://github.com/adobe-fonts/source-serif (mirrored via google/fonts) | classic |
| JetBrains Mono | `JetBrainsMono.ttf` | OFL 1.1 | https://github.com/JetBrains/JetBrainsMono (mirrored via google/fonts) | all groups (mono role) |

The bundled .ttf binaries are mirrored from [google/fonts](https://github.com/google/fonts) under their `ofl/<family>/` paths, all distributed under OFL 1.1. Each upstream repo's `OFL.txt` is the authoritative license text; the in-app About → Licenses screen (Flutter's `showLicensePage`) surfaces bundled fonts automatically.

## OFL 1.1 summary (not a substitute for the full text)

You may:
- Use, study, copy, merge, embed, modify, redistribute, and sell modified and unmodified copies of the fonts.
- Bundle the fonts with your software.

You must:
- Preserve the copyright notice and the OFL.txt in any redistribution.
- Not use the **Reserved Font Names** of an upstream typeface to name a derivative font without permission.

The full OFL text: https://openfontlicense.org
