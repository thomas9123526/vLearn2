# ok. how can i modify placeholders?

Session: `0c373469-dea6-47f9-ba6b-d5f7b4449689`
Saved: 2026-06-01T06:29:48.718Z

## User

ok. how can i modify placeholders?

## Assistant

All placeholders come from one place — the `tutorContext()` method at [prompt-builder.service.ts:94](backend/src/ai/prompt-builder.service.ts#L94). It builds the flat key→value map that gets substituted into the template.

```typescript
// prompt-builder.service.ts:112-127
return {
  'persona.name': persona.name,
  'persona.style': persona.style,
  'persona.specialties': specialties,
  'persona.gender': persona.gender ?? 'neutral',
  'persona.accent': persona.accent ?? '',
  'scenario.title': sc ? en(sc.title) : 'Free conversation practice',
  ...
  'user.level': String(userLevel),
  'user.level_label': levelLabelFor(userLevel),
  'user.native_language': userNativeLanguage,
};
```

**To add a new placeholder** — e.g. `{{session.turn_count}}`:

1. The value must be available as a parameter to `buildSystemPrompt()`. If it's not passed in yet, you add it to the signature and thread it through from `conversation.orchestrator.ts`.
2. Add the key to the return object:

```typescript
'session.turn_count': String(turnCount),
```

3. Use `{{session.turn_count}}` in your DB template.

---

**To remove a placeholder** — just delete the key from the map. The template will render it as `''` (empty string) — it won't crash.

**To rename a placeholder** — change the key string in the map, then update your template to use the new name.

---

**Where the data comes from** — `buildSystemPrompt()` receives:

```typescript
buildSystemPrompt(
  persona: PersonaEntity,      // DB: name, style, specialties, gender, accent
  scenario: ScenarioEntity | null,  // DB: title, setting, roles, objectives, key_phrases
  userLevel: number,           // user profile
  userNativeLanguage: string,  // user profile
)
```

If you need something that isn't here (e.g. user's name, session turn count, time of day), you add it as a parameter to this method and pass the value from [conversation.orchestrator.ts:26-59](backend/src/ai/conversation.orchestrator.ts#L26).
