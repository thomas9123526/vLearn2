# ok , I want know each field description for Metadata and Database Row, for examp

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-26T08:00:56.307Z

## User

ok , I want know each field description for Metadata and Database Row, for example inside todoList_report/scenario/business/business-metting-intro.md.
save result to todoList_report/scenario/field_description.md

## Assistant

Saved to [todoList_report/scenario/field_description.md](todoList_report/scenario/field_description.md).

The document covers two groups:

**Metadata fields** (5 fields) — Slug, Category, CEFR Level, XP Reward, Estimated Minutes. These are the summary display fields shown at the top of each scenario file.

**Database Row fields** (14 fields) — every column in `vl_scenarios`, including what JSON sub-key is read (e.g. `title->>'en'`), what type it is, and what it's for in both the app UI and the AI prompt.

At the bottom there's a quick mapping table showing exactly which DB fields get injected into which `{{placeholder}}` in the system prompt — and which fields are **not** sent to the AI at all (slug, category, difficulty, estimated_minutes, xp_reward, title_ko/zh, description, status — these are UI-only).
