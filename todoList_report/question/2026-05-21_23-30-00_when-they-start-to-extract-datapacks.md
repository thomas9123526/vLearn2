# when they start to extract datapacks?

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-21T14:30:00.304Z

## User

when they start to extract datapacks?

## Assistant

**Honest answer: right now, never.** The installer is built and tested, but I deliberately didn't wire it into the app's startup flow — that was the "Stage 9 final step" I called out as a UX decision and left for you. The provider exists and is ready to consume; nothing currently consumes it.

## What you have today

- `DataPackInstaller.installPending()` works (verified by `installer_test.dart`).
- `installPendingDataPacksProvider` exists and is consumable.
- **No call site in `lib/main.dart`, `splash_screen.dart`, or anywhere else** invokes it.

So if you `flutter run` right now: `.ddp` files dropped into `/sdcard/룡마/가상외국어회화/datapacks/` would just sit there.

## Where it should fire

Three natural trigger points, from earliest to latest:

| Trigger | When it runs | Pros | Cons |
| --- | --- | --- | --- |
| **`main()` before `runApp`** | Before any Flutter UI mounts | App can't show stale state | Blank window during unpack (no spinner) |
| **Splash screen `initState`** | During the 900 ms splash entrance | Branded loading, current splash already does async work (`_resolveReturning`) | If unpack takes > splash duration, you need to extend the splash |
| **A dedicated "preparing assets" screen** between splash and home | Right after splash, before HomeScreen | Clean progress UI, can show per-pack progress | One extra screen in the boot flow |

## My recommendation

Given that:
- The splash already runs async work (reading SharedPreferences for `_returning`).
- The unpack is **idempotent + cached** — second-launch cost is essentially "read state.json + hash a few files" — fast.
- First-launch unpack of model bundles (potentially tens of MB) could take a few seconds.

…the cleanest pattern is **splash + skip-when-cached**:

1. Splash mounts, starts its 900 ms entrance choreography.
2. In parallel, `ref.watch(installPendingDataPacksProvider)` runs.
3. On normal launches (everything cached): finishes in milliseconds, splash plays unmodified.
4. On first launch (or after admin dropped new packs): splash entrance ends, but the "Tap to begin" / auto-nav is held until the install completes. Show a small `LinearProgressIndicator` or "Preparing your data..." text where the CTA would be.
5. On failure: show an error with the failed pack name(s) — the user knows they need to re-transfer.

## Want me to wire it now?

Concretely, that's:

1. Edit [splash_screen.dart](flutter_app/lib/features/splash/splash_screen.dart) to also `ref.watch(installPendingDataPacksProvider)` alongside the existing `_resolveReturning` call.
2. Gate the navigation (`context.go(AppRoute.signIn)` for returning users / "Tap to begin" CTA for new users) on **both** "splash entrance done" AND "install pending complete".
3. Replace the CTA / status area with a progress indicator during the (usually-instant, sometimes-slow) install pass.
4. On install failure, route to a new `DataPacksFailedScreen` that lists which `.ddp` failed and why.

Maybe 60–80 lines of changes in `splash_screen.dart`, plus the new failure screen. Tell me to go and I'll do it.
