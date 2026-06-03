# I want output log for all data sent to ai provider and all data received from ai

Session: `10e65b1d-4afb-4146-8130-782b3c1583d6`
Saved: 2026-06-03T23:45:19.848Z

## User

I want output log for all data sent to ai provider and all data received from ai provider with pretty format.
So please output log on backend console so i can study and control them via application.
Also Plz log to console for  prompt sent to ai provider and for data received from ai provider.
When log to console, plz print first the sender, time , how this prompt was organized by the varaibles used , where variables come from. and api endpoint to ai provider.

## Assistant

Let me find the AI module code on the backend first.

## Assistant

Now let me read the actual files before writing the logging code.

## Assistant

Now I have everything I need. I'll create a pretty `AiCallLogger` utility, then wire it into the prompt builder (variable sources), orchestrator (call context + history), and both providers (API endpoint + response).

## Assistant

I have a typo (`asst Count`) — let me fix that now.

## Assistant

Now update `PromptBuilderService` to return variable+source info and log which prompt path was used:

## Assistant

Now add a public method to expose the context + sources, and update `buildSystemPrompt` to return the source label:

## Assistant

Now update `ConversationOrchestrator` to use the new logger and the new `buildSystemPrompt` signature:

## Assistant

Now replace the `generateTutorReply` body with the new logging:

## Assistant

Now update `suggestNextLine` and `scoreGrammar` / `evaluateSession` to use the logger too:

## Assistant

Now add logging to `scoreGrammar` and `evaluateSession`:

## Assistant

Also log the evaluation response. Let me find that spot:

## Assistant

Now add provider-level logging to both providers. First Anthropic:

## Assistant

Now the OpenAI-compatible provider — remove the old inline log and add the structured ones:

## Assistant

Now verify the TypeScript compiles cleanly:

## Assistant

Clean. Let me quickly check there are no other callers of `buildSystemPrompt` I missed:

## Assistant

The spec tests `result` as a string. Now that `buildSystemPrompt` returns `{prompt, source}`, this test needs updating:

## Assistant

All clean. Commit and story:

## Assistant

Done. Here's what you'll now see in the backend console for every AI interaction:

**Two orchestrator-level blocks** (before and after):
```
╔══════════════════════════════════════════════════════════════════════════════╗
║  ► AI REQUEST  ·  generateTutorReply  ·  2026-06-04T08:43:00.000Z          ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  PROMPT ASSEMBLY                                                             ║
║    source : section-builder ([role]/[learner]/[topic]/…)                    ║
║    ── from: persona DB row (vl_personas)                                    ║
║      persona.name                           = Lily                          ║
║      persona.style                          = warm and encouraging          ║
║    ── from: scenario DB row (vl_scenarios)                                  ║
║      scenario.title                         = Airport Check-in              ║
║    ── from: user_progress.current_level                                     ║
║      user.level                             = 3                             ║
║      user.level_label                       = B1                            ║
║    ── from: user_info.native_language                                       ║
║      user.native_language                   = ko                            ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  SYSTEM PROMPT  (847 chars)                                                  ║
╟──────────────────────────────────────────────────────────────────────────────╢
║  [role]  You are Lily: a warm and encouraging English tutor…                ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  CONVERSATION HISTORY  (4 messages · 2 user / 2 assistant)                  ║
╟──────────────────────────────────────────────────────────────────────────────╢
║  [assistant]  Hi! Welcome to the airport. May I see your passport?          ║
║  [user     ]  Here it is.                                                   ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

**Two provider-level blocks** (showing the actual HTTP call):
```
╔══════════════════════════════════════════════════════════════════════════════╗
║    [Anthropic]  ►  CHAT REQUEST                                             ║
╠══════════════════════════════════════════════════════════════════════════════╣
║    endpoint   :  POST https://api.anthropic.com/v1/messages                 ║
║    model      :  claude-sonnet-4-6                                          ║
║    max_tokens :  1024    temperature: 0.8                                   ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

All four call types are covered: `generateTutorReply`, `suggestNextLine`, `scoreGrammar`, and `evaluateSession`.
