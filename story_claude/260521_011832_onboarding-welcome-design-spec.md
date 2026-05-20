# Onboarding welcome screen redesigned to match design handoff

## What this task did

Rebuilt `flutter_app/lib/features/onboarding/onboarding_screen.dart` to match the design handoff (`vLearn2Spec/design_handoff_freetalk/reference/screens.jsx` — `OnboardScreen` step 0). The previous implementation laid out a `Column` inside `SafeArea + Padding(24)` with no horizontal centering — the Column shrink-wrapped its widest child, so on Windows (where the window is ~1264 dp wide) everything stuck to the top-left corner. The screenshot the user shared made that very plain. New layout:

- 720 dp breakpoint switch for desktop vs. mobile (shared with splash + AppShell).
- `Stack` with a radial-glow background behind the centered content.
- Content column is wrapped in `Center → ConstrainedBox(maxWidth: 520)` so it actually centers and never overflows readable line length.
- Soft-accent circular badge (140 dp desktop / 110 dp mobile) holding the waving-hand icon, with a long accent drop shadow.
- "WELCOME ABOARD" eyebrow in EditorialMono with 2.4 letter-spacing.
- Serif title (`EditorialHeading`, 48 dp desktop / 34 dp mobile, weight 400, `-1.0` letter-spacing, line-height 1.05). The username renders inline as italic accent — same visual treatment as the design's `Sign in to <em>FreeTalk</em>`.
- Subtitle constrained to 380 dp wide, body font, soft ink colour.
- "Let's go" CTA matches the splash's Tap-to-begin pill — accent pill, white circular arrow chip, hover lift, drop shadow. Re-uses the visual language so the primary action looks the same everywhere.
- Desktop padding is `40 × 80 dp` per the design; mobile keeps `24 dp` all round.

`flutter analyze` clean.

## Conversation summary

- User attached a Windows screenshot showing the welcome screen left-aligned and asked me to fix it to match the design spec.
- Read the current `onboarding_screen.dart` and traced why it was left-aligned: `Column` inside `SafeArea + Padding` has no horizontal centering, so the column shrinks to its widest child and pins to the top-left of the available space.
- Pulled the design's `OnboardScreen` step 0 layout (`screens.jsx:39-167`) for typography and spacing rules; pulled `auth.jsx:185-194` for the title-with-italic-accent pattern; pulled `theme.jsx` for the colour ladder.
- Rebuilt the screen with `Center → ConstrainedBox(520) → Column`, a soft-accent circular badge, serif heading with italic accent name, capped subtitle, and a splash-style CTA pill.
- Fixed two IDE diagnostics during the rebuild: dartdoc `<name>` → backticked; removed redundant default `crossAxisAlignment: CrossAxisAlignment.center` on the Column.

## Decisions / call-outs

- **Kept this a one-step welcome, not the full 4-step design** — the design's `OnboardScreen` is a 4-step flow (intro / goal / voice check / placement). Our `OnboardingScreen` is a single gate that flips `onboardingDone = true` and sends the user to `/home`. The user asked me to fix the existing screen, not rebuild the multi-step flow, so I matched the **styling** of step 0 (title / subtitle / CTA) rather than the full state machine. Building out goal / voice check / placement is a much larger task — leave it as a follow-up.
- **CTA visual matches the splash** — same pill shape, same arrow chip, same hover lift. Two routes for the same primary action that look identical = less to learn.
- **Italic accent on the username** — the design uses italic accent on emphasized words ("Sign in to *FreeTalk*"). Reused that for the username, which keeps the personalization visible without making the whole title accent-coloured.
- **Glow centred on the column, not the window** — `Positioned.fill` with `RadialGradient(radius: 0.7)` defaults to centred, which is where the column also sits, so the brightest part of the glow aligns with the heading. No extra centring math needed.
- **Did not touch the route or the API call** — `_completeOnboarding` is unchanged, so the auth/profile contract is identical.

## User prompt (verbatim)

> but this windows screen doen't feet design spec. fix it
