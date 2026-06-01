# so what is the highest priority?  If i edit for option3, then the app use the op

Session: `0c373469-dea6-47f9-ba6b-d5f7b4449689`
Saved: 2026-06-01T06:27:52.119Z

## User

so what is the highest priority?  If i edit for option3, then the app use the option3 one or it uses the option1 prompt in database?

## Assistant

**DB template always wins.** Here's the exact priority from [prompt-builder.service.ts:46-47](backend/src/ai/prompt-builder.service.ts#L46):

```typescript
const tpl = await this.loadTemplate('tutor_system');   // tries DB first
return this.render(tpl ?? DEFAULT_TUTOR_SYSTEM, ctx);  // fallback if null
```

So the order is:

1. **DB template** (`vl_prompt_templates` where `kind='tutor_system'` and `is_active=true`) — **highest priority**
2. **`DEFAULT_TUTOR_SYSTEM`** in the source file — only used when no active DB row exists

Option 3 (admin UI) is just a convenient interface to write into the DB — it's Option 1 under the hood. If you build it and save a template through the UI, that DB row takes over. The hardcoded default becomes the safety net for fresh installs or when the DB row is deactivated.

**Recommendation:** Build Option 3. You get the DB-wins priority automatically, plus the ability to tweak the prompt without touching code or redeploying. Want me to build the admin UI page for it?
