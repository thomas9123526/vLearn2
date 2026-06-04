# reply = await this.orchestrator.generateTutorReply({         persona,         sc

Session: `ec7e9529-1399-4642-b1c1-753f53834cc7`
Saved: 2026-06-04T09:54:32.911Z

## User

reply = await this.orchestrator.generateTutorReply({
        persona,
        scenario,
        userLevel: session.cefr_level ,
        userNativeLanguage: user.info.native_language,
        history,
      });

on conversations.service.ts,  userLevel must be session.cefr_level and session.cefr_level must have value.

## Assistant

Let me check how `session.cefr_level` is set at session start.

## Assistant

The session entity declares `cefr_level` as `number | null` (nullable in DB), but `start()` always sets it (`dto.cefrLevel ?? user.current_level ?? 1`). The fallback to `user.info.current_level` in `sendMessage` is unnecessary — `session.cefr_level` is the authoritative value. One-line fix:

## Assistant

The user already removed `?? user.info.current_level`. The remaining problem is a TypeScript type error: `session.cefr_level` is `number | null` (entity is nullable) but `userLevel` expects `number`. Fix with a minimal guard:

## Assistant

The same guard is needed in `suggestNextLine` if it also reads `userLevel` from the session. Let me check:

## Assistant

Now commit:

## Assistant

Done. Both `sendMessage` and `suggestNextLine` now use `session.cefr_level ?? 1`. The `?? 1` is just a TypeScript null-guard — the value is always set by `start()` so it will never actually hit 1 in practice.
