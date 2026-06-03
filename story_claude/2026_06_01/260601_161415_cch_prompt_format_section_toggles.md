# Conversation - cch_prompt format with section toggles and per-scenario custom prompt

| Field | Value |
|---|---|
| Saved | 2026-06-01 16:14:15 |
| Commit | Adopt cch_prompt format with section toggles, per-scenario custom_prompt, and Prompts admin tab |
| Project | C:\project\vLearn2 |

---

## User

ok. we use our ai model for ai provider, it is not good as the other ones. So some fields is unnecessary on the system prompt. cch_prompt is the prompt that our model accepts. Can you modify backend api and flutter app scenario details along with the cch_prompt. I don't want delete fields permanently, because if our model grows better then I would like to set tick or append fields. What can you offer?

(After discussion: locale and avoided_topics are global, no Flutter changes needed, also want option to put scenario-specific prompt in the admin panel)

## Assistant

Implemented cch_prompt section format with per-section toggles and per-scenario custom prompt override across 10 files:

**Backend entity/migration:** Added `custom_prompt: text | null` column to `vl_scenarios` (migration 1781400000000). Added `'prompts'` to `AppConfigCategory` union type.

**Backend seed:** Added 13 new `prompt.*` config entries — 8 boolean section toggles (`prompt.section.role/learner/topic/subtopics/cefr_level/locale/avoided_topics/guidelines`), 4 locale string fields, and `prompt.avoided_topics` text.

**PromptBuilderService rewrite:** Priority order: (1) `scenario.custom_prompt` if set → renders {{placeholders}} and returns; (2) active `vl_prompt_templates` row → full global override; (3) section-by-section cch_prompt builder reading `prompt.section.*` flags from DB. Added `AppConfigEntity` repository injection. Kept `buildGrammarPrompt` and `buildFeedbackPrompt` unchanged.

**AI module:** Added `AppConfigEntity` to `TypeOrmModule.forFeature([...])`.

**Admin scenarios controller:** Added `custom_prompt?: string | null` to `UpdateScenarioDto`.

**Admin flag catalog:** Added `'prompts'` AppTab with a new tab entry and 13 catalog entries (8 boolean big-tier section toggles + 5 text/textarea fine-tier locale+avoided_topics fields). Extended `FlagDescriptor` with `type: 'text' | 'textarea'`.

**Config page:** `FlagRow` now renders inline `<input type="text">` or `<textarea>` for text-type flags, saving on blur. Used local draft state to avoid saving on every keystroke.

**Scenario editor page:** Added "Custom prompt" textarea section at the bottom of the form (before images). Empty string saved as null.

---

## Prompt

ok. we use our ai model for ai provider, it is not good as the other ones. So some fields is unnecessary on the system prompt. cch_prompt is the prompt that our model accepts. Can you modify backend api and flutter app scenario details along with the cch_prompt. I don't want delete fields permanently, because if our model grows better then I would like to set tick or append fields. What can you offer?
