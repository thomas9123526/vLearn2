# vLearn2 — 0517_v2 Plans

Five focused tasks that build on the 0516 planning + implementation. Each is a self-contained playbook in this folder.

| # | File | Scope |
|---|------|-------|
| 01 | [STT/TTS via sherpa-onnx](01_stt_tts_sherpa_onnx.md) | Real implementation of the placeholder speech services from 0516/09 §9.14; admin-pre-placed models per §9.15.6 |
| 02 | [Next.js Admin Panel](02_admin_panel_nextjs.md) | New sibling project `admin_panel/`; consumes the `/admin/*` API from 0516/12-14; visibility / scenarios / users / leaderboards / config / admins |
| 03 | [News feature with bell-icon notifications](03_news_feature.md) | New domain: subadmin uploads news → home-screen list + bell-icon unread badge → mark-as-read API |
| 04 | [Conversation bubble styles (5 variants)](04_conversation_bubble_styles.md) | 5 distinct chat-bubble layouts + picker in Settings (placed below font area) |
| 05 | [Font groups (4 bundled, offline-only)](05_font_groups.md) | 4 curated font groups; all .ttf files bundled in `assets/fonts/`; drop runtime `google_fonts` fetching |

## Cross-references to existing plans

- The **STT/TTS playbook (01)** is the implementation layer for the abstractions already in [0516/09 §9.14](../0516/09_ai_integration.md), with model deployment per [0516/09 §9.15.6](../0516/09_ai_integration.md). The Flutter interfaces in `lib/core/speech/speech_service.dart` get real implementations.
- The **Admin Panel (02)** consumes the API spec'd in [0516/12](../0516/12_admin_visibility.md), [0516/13](../0516/13_admin_content_and_users.md), [0516/14](../0516/14_admin_permissions.md). Backend modules from the 0516 implementation are already in place.
- The **News feature (03)** is an additive domain — adds `news.*` permissions to the catalog, a new module + DB tables. The home-screen bell-icon flag `home.notification_bell` is already in the §12 catalog; this plan wires it.
- The **Bubble styles (04)** add a new `conversation.bubble_style` setting key + a new `appearance.bubble_style` UI section in settings.
- The **Font groups (05)** add a new `appearance.font_group` setting key + a new "Font" section in settings (the new Bubble section sits **below** this one, per the user's request).

## Implementation order (suggested)

1. **05 font groups** — touches the theme system; easier to do before screens reference theme-derived font tokens
2. **04 bubble styles** — depends on the Settings UI being editable post-font work, but otherwise self-contained
3. **03 news** — additive backend + Flutter; no dependency on STT/TTS or admin panel
4. **01 STT/TTS** — depends on sherpa-onnx model files being available; can be developed against placeholder models first
5. **02 admin panel** — fully separate project; no Flutter dependency; can start anytime after 0516 backend was running

Or work in parallel where independent. Tasks 03 and 02 are mutually reinforcing (admin panel surfaces a news manager UI).
