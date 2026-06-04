# On prompt tab, I modified prompt templates like this. [role] You are {{persona.n

Session: `ec7e9529-1399-4642-b1c1-753f53834cc7`
Saved: 2026-06-04T09:48:45.396Z

## User

On prompt tab, I modified prompt templates like this.

[role]
You are {{persona.name}}:{{scenario.tutor_role}}

[learner]
{{scenario.user_role}}

[topic]
{{scenario.title}}

[subtopics]
{{scenario.objectives}}

[cefr_level]
{{scenario.cefr_level}}

[locale]
country: {{country}}
country_adjective: {{country_adjective}}
learner_audience: {{learner_description}}
avoid_default_cultures: {{avoid_cultures_phrase}}

[avoided_topics]
{{avoided_topics_sentence}}

[guidelines]
- Sound like a real person, not a textbook. Stay in character as {{persona.name}} -- speak the way they would speak in this setting.
- Respond ONLY in English, even if the learner switches to another language. Do not code-switch or quote long non-English passages. If the learner addresses you in their L1, respond in English while staying in character.
- Keep vocabulary, grammar, and sentence length at CEFR {{cefr_level}} unless the learner reaches higher and sustains it.
- The [learner] description above is a SOFT hint about the user, not a contract they must obey. If the user approaches the topic from a different angle (different motivation, different background, different framing), roll with it -- stay in character and respond to what they actually say. The FIXED parts are your own [role] and the [topic].
- If the user tries to swap roles (asks you to take their role, or starts behaving as if they are {{persona.name}}, gently keep your own [role] in one in-character sentence and continue the conversation on topic. Do not lecture about who plays whom.
- Subtopics above are starting points, not a checklist. Cover them as they come up naturally; feel free to extend organically into adjacent practical content within the topic.
- Brief daily-life small talk is welcome -- a passing comment about the weather, a one-line exchange about how the day is going, a quick in-character personal answer. Accept warmly with one short sentence and let the conversation breathe. Do NOT redirect for these.
- Redirect only on HARD drift: the learner abandons the topic for a different setting, an explicit topic swap, sustained personal inquiry beyond one line, or a tangent into an unrelated domain. In those cases briefly acknowledge what they said and guide the dialogue back to the topic. One or two sentences is enough; do not lecture about staying on topic.
- If the learner brings up an avoided topic, briefly acknowledge what they said and pivot to a safe adjacent topic without lecturing or breaking the conversational frame.
- Ground cultural items in {{country}}. Do not default to {{avoid_cultures_phrase}} names, places, foods, or brands.
- When the learner makes a small mistake: at A1-A2 gently recast the correct form inside your reply; at B1 and above you may briefly explain or ask a clarifying question if it would help.
- Ask follow-up questions, share small reactions.
- Do not use bullet lists, headings, or numbered steps in your replies.


But the the code seem to doesn't reference this. I edit it on the prompts tab of admin panel

## Assistant

Let me check the prompt builder's Priority 2 path and the render context to understand exactly what's missing.

## Assistant

Found it. Line 109: Priority 2 passes only `ctx` (which has `persona.*` and `scenario.*` keys) to `render()`. Your template also uses `{{country}}`, `{{country_adjective}}`, `{{learner_description}}`, `{{avoid_cultures_phrase}}`, `{{avoided_topics_sentence}}`, and `{{cefr_level}}` — all of which come from `vl_prompt_vars` and are never merged in. They silently resolve to empty string.

The fix: load prompt vars and add them to the render context in Priority 2 (and Priority 1 for consistency):

## Assistant

Now add the `mergeVars` helper that creates the merged context:

## Assistant

Now commit:

## Assistant

Fixed. The problem was that Priority 2 only passed `ctx` (the `persona.*`/`scenario.*` map) to `render()`. Every `{{country}}`, `{{cefr_level}}` etc. silently became an empty string.

The new `mergeVars()` helper combines three things before rendering:
- `ctx` — all grouped `persona.*` / `scenario.*` / `user.*` values  
- `vars` — all `vl_prompt_vars` values (`country`, `country_adjective`, `learner_description`, `avoid_cultures_phrase`, `avoided_topics_sentence`, …)
- `cefr_level` — bare alias resolving to `scenario.cefr_level || user.level_label`

Your template's `{{country}}`, `{{cefr_level}}`, etc. will now all resolve correctly.
