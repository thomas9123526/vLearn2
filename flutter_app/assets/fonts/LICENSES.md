# Bundled font licenses

All fonts shipped under [`assets/fonts/`](.) are distributed under the **SIL Open Font License 1.1** (OFL 1.1). Bundling inside a closed-source app is explicitly permitted by the license, provided the OFL.txt for each typeface is included.

| Family | License | Upstream | Used in groups |
|--------|---------|----------|----------------|
| Inter | OFL 1.1 | https://github.com/rsms/inter | editorial, modern |
| Lora | OFL 1.1 | https://github.com/cyrealtype/Lora-Cyrillic | editorial |
| Quicksand | OFL 1.1 | https://github.com/andrew-paglinawan/QuicksandFamily | friendly |
| Nunito | OFL 1.1 | https://github.com/googlefonts/nunito | friendly |
| Playfair Display | OFL 1.1 | https://github.com/clauseggers/Playfair | classic |
| Source Serif Pro | OFL 1.1 | https://github.com/adobe-fonts/source-serif | classic |
| JetBrains Mono | OFL 1.1 | https://github.com/JetBrains/JetBrainsMono | all groups (mono role) |

When the `.ttf` files are placed in their group folders, also drop each upstream `OFL.txt` next to them (or aggregate verbatim into this file). The in-app About → Licenses screen (Flutter's `showLicensePage`) surfaces bundled fonts automatically.

## OFL 1.1 summary (not a substitute for the full text)

You may:
- Use, study, copy, merge, embed, modify, redistribute, and sell modified and unmodified copies of the fonts.
- Bundle the fonts with your software.

You must:
- Preserve the copyright notice and the OFL.txt in any redistribution.
- Not use the **Reserved Font Names** of an upstream typeface to name a derivative font without permission.

The full OFL text: https://openfontlicense.org
