# but this windows screen doen't feet design spec. fix it

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-20T16:19:26.805Z

## User

but this windows screen doen't feet design spec. fix it

## Assistant

Let me find the current onboarding/welcome screen and the design reference.

## Assistant

Let me check the design handoff for the welcome screen.

## Assistant

Let me check the design tokens and existing styling so the rebuild matches the spec.

## Assistant

Now I'll rebuild the onboarding screen to match the design — centered column, serif title, soft-accent badge for the wave icon, and a proper accent CTA pill.

## Assistant

Clean. Commit and log.

## Assistant

Done — committed as `4428886`.

**Root cause of the off-spec layout** ([onboarding_screen.dart, old line 24](flutter_app/lib/features/onboarding/onboarding_screen.dart#L24)): the `Column` inside `SafeArea + Padding(24)` had no horizontal centering. Columns shrink to their widest child for the cross-axis and don't centre themselves in their parent — on Windows that pinned everything to the top-left.

**Fixes applied:**
- `Center → ConstrainedBox(maxWidth: 520) → Column` so the content actually centres.
- 720 dp breakpoint matching the splash + AppShell; desktop padding `40 × 80 dp`, mobile `24 dp`.
- Soft-accent circular badge (140/110 dp) for the waving-hand icon with a long accent drop shadow.
- `EditorialMono` "WELCOME ABOARD" eyebrow.
- Serif title (`EditorialHeading` 48/34 dp, weight 400) with the username rendered inline as italic accent — same treatment as the design's `Sign in to <em>FreeTalk</em>`.
- Subtitle capped to 380 dp.
- "Let's go" CTA matches the splash's pill so the primary action looks identical across the auth flow.
- Radial glow behind the column.

Multi-step content (goal / voice check / placement) from the design's full `OnboardScreen` is **not** included — this just fixes the existing single-step welcome gate. Tell me if you want the full 4-step flow built out as a follow-up.
