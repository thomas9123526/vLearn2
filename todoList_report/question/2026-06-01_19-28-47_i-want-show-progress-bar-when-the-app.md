# I want show progress bar when the app is fetching via network on homescreen. Als

Session: `90c5c6ba-f941-45bb-8889-37114ea77f9f`
Saved: 2026-06-01T10:28:47.516Z

## User

I want show progress bar when the app is fetching via network on homescreen.
Also when the app get data from assets/seed

## Assistant

Let me explore the home screen and its data loading logic first.

## Assistant

Now let me read the actual home screen code:

## Assistant

I have a clear picture now. The `Cached` state already exposes:
- `refreshing: true` during any network fetch (covers both network refresh and the network fetch that follows seed load)
- `fromCache: true` while showing SQLite/seed data

I'll add a `LinearProgressIndicator` at the top of the body (3 px, no layout shift) that shows whenever either provider is still loading. I'll also remove the now-redundant `RefreshingDot` next to the section header since the top bar is more prominent.

## Assistant

Now remove the `RefreshingDot` inline spinner that's now redundant:

## Assistant

Check if `RefreshingDot` import is still used elsewhere in this file:

## Assistant

`RefreshingDot` is still used at line 240 (`_QuickStats`), so the import stays. Let me commit:

## Assistant

Done — a 3 px `LinearProgressIndicator` now lives in `AppBar.bottom`. It fades in/out via `AnimatedSwitcher` whenever `scenarios.refreshing || progress.refreshing` is true, which covers:
- **Seed load**: the notifier emits `fromCache: true, refreshing: true` while showing seed data and fetching from the network
- **Network fetch**: any `refreshing: true` state (initial load or pull-to-refresh)

---

Now addressing your new message — let me look at the scenario detail screen and the system prompt to understand the `[cefr_level]` substitution.

## Assistant

Let me read the prompt builder and the conversations service to see exactly how `[cefr_level]` is substituted:

## Assistant

Now let me check where `buildSystemPrompt` is called to see what `userLevel` is passed:

## Assistant

Let me look at the cch_prompt doc and how the custom_prompt template uses `[cefr_level]`:

## Assistant

Let me read the actual `_startSession` method and the level selection logic:

## Assistant

Now I see the full picture. The backend pipeline is correct — `session.cefr_level` is saved from the Flutter selection and used when building the prompt. But when a **custom prompt** (Priority 1) or **global template** (Priority 2) contains `[cefr_level]` literally, the `render()` method skips it because it only matches `{{key}}` syntax. The `[cefr_level]` placeholder stays as a literal string in the final prompt instead of being replaced with the actual level label.

The fix: extend `render()` to also substitute `[cefr_level]` → `ctx['user.level_label']`, and update the admin panel hint to document it.

## Assistant

Now update the admin panel hint to document both variable styles:

## Assistant

Now commit:

## Assistant

Done. Two changes:

**[prompt-builder.service.ts](backend/src/ai/prompt-builder.service.ts)** — `render()` now does two substitution passes:
1. `{{group.field}}` patterns (existing)
2. `[cefr_level]` → actual level label (e.g. `B2`) — sourced from `session.cefr_level` which was saved from the user's selection on the scenario detail screen

This means custom prompts and global templates can now write either `{{user.level_label}}` or `[cefr_level]` and both will resolve to the correct level. The section-builder (Priority 3, no custom prompt) was already correct and is unchanged.

**Admin panel** — the custom prompt hint now documents both `[cefr_level]` and `{{user.level_label}}` as supported variables.
