# Add 0517_v2 plans: STT/TTS, admin panel, news, bubble styles, font groups

## What this task did

Created `todoList/0517_v2/` with an overview index + 5 focused planning docs for the next wave of work:

- [`00_overview.md`](../todoList/0517_v2/00_overview.md) — index + cross-refs to existing 0516 plans + suggested implementation order
- [`01_stt_tts_sherpa_onnx.md`](../todoList/0517_v2/01_stt_tts_sherpa_onnx.md) — concrete implementation playbook to replace the placeholder STT/TTS services with sherpa-onnx, honoring Mode-B (admin-pre-placed models). 10 sections, ~30 numbered todos
- [`02_admin_panel_nextjs.md`](../todoList/0517_v2/02_admin_panel_nextjs.md) — new sibling project `admin_panel/`; tech stack (Next.js 14 + shadcn/ui + TanStack Query); folder structure; auth flow reusing the same JWT pair as Flutter; permission-aware UI; page-by-page feature parity with existing `/admin/*` API
- [`03_news_feature.md`](../todoList/0517_v2/03_news_feature.md) — new domain: subadmin uploads news (with `news.*` permissions) → app users see home-screen list + bell-icon unread badge → mark-as-read API. Includes DB schema (`news_posts` + `news_read_status`), permission catalog additions, backend module, Flutter home/detail/list screens
- [`04_conversation_bubble_styles.md`](../todoList/0517_v2/04_conversation_bubble_styles.md) — 5 named bubble styles (classic / modern / tail / soft / notebook) + picker in Settings with visual previews, positioned below the new Font section
- [`05_font_groups.md`](../todoList/0517_v2/05_font_groups.md) — 4 curated font groups (Editorial / Modern / Friendly / Classic); all .ttf bundled in `assets/fonts/<group>/`; **`google_fonts` package removed** to satisfy the no-internet-fetch requirement; licenses (OFL 1.1) aggregated; ~5 MB APK growth

## Conversation summary

Recent turns (faithful):

- **User** asked how the Flutter app gets the list of topics (scenarios) — backend API or bundled in APK?
- **Assistant** confirmed: through the backend `GET /api/scenarios`; NO scenarios bundled in `assets/`. Showed evidence (api client + screens). Noted that `ScenariosCache` Drift table exists but isn't wired (deferred work documented in 04/05 reports).
- **User** asked for a v2 todoList in `todoList/0517_v2/` covering five concrete tasks:
  1. STT/TTS with sherpa-onnx
  2. Admin panel in Next.js
  3. News feature with bell-icon notifications on home screen
  4. 5+ chat bubble styles + selector in Settings (below font section)
  5. 4 font groups, each with multiple font types, all bundled in the app — no internet fetching

## Decisions / call-outs

- **05 (fonts) is the most architecturally invasive.** Removing `google_fonts` is a hard cut — anywhere in the app that calls `GoogleFonts.X(...)` needs the new bundled-font builder. Today only `AppTheme.build` uses it.
- **Decided not to bundle CJK companion fonts** in v1. None of the 7 chosen Latin-script fonts have full CJK coverage; Flutter will fall back to system fonts for missing glyphs. Honest call-out documented in §5.9. If Korean/Chinese readability becomes a real complaint, Noto Sans CJK is the obvious add (+~30 MB).
- **04 (bubble styles) sequencing**: bubble picker goes BELOW the font picker, per the user's literal request. So Settings → Appearance → Font section (Task 05) → Bubble section (Task 04).
- **03 (news) is pull-based, not push.** No FCM/WNS notification infrastructure. Bell shows unread count from a periodic poll (60s). Real push is a much bigger separate effort.
- **02 (admin panel) calls out** that several backend endpoints needed for it aren't built yet (per the §13 honest call-outs). Recommended building the panel + the corresponding endpoints in parallel — each panel page motivates the next backend endpoint.
- **01 (STT/TTS) builds on Mode B** from 0516/09 §9.15.6. Admin pre-places models, app never downloads. Storage paths and verification flow already spec'd; this task implements them.
- **Permission catalog grows by 4** in Task 03 (news.view / news.edit / news.delete / news.upload_image) — additive change, no schema migration needed beyond the news tables themselves.

## User prompt (verbatim)

> give me todoList as md inside todoList\\0517_v2 to implement following task.
>
>
> 1. stt,tts implement with sherpa_onnx
> 2. admin panel with next.js
> 3. I want put news inside the application. So subadmin upload news and then application user can see news on the homescreen. User can notice with bell icon on homescreen.
> 4. I want various bubble layout for the conversation screen. I want at least 5 types. And put the bubble type setting on the settings screen and below font setting area.
> 5. In the setting screen I want add font group part.
> So there can be 4 font group.
> Each font group consists of multiple font type and they are used across the applications to represent various font styles and feels.
> Can u give me solution about this?
> And I want put all font files inside the application code part and donn't want fetch font from the internet.
> I don't want big trafic through the network.
