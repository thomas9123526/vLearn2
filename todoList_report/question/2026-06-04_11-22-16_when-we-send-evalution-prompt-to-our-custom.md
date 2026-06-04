# When we send evalution prompt to our custom model, we create a new session for e

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-04T02:22:16.108Z

## User

When we send evalution prompt to our custom model, we create a new session for evalution. So don't send to existing conversation session.
So backend should know about the conversation content and when we evaluate that conversation session, we create a new session for evalution and compose the evalution prompt.
Look  inside eval_template.txt for '"messages":[{"role":"user","content":' part.
When you make evalution prompt , you need to put content about the scenario and Transcript for user and tutor in turns. You can find the examples below '"messages":[{"role":"user","content":' part.

That's it.

## Assistant

Good news — this is already exactly how it works after the last change. Let me confirm each point:

**The `evaluateSession()` call:**
```typescript
const res = await this.ai.chat({
  systemPrompt,                                         // evaluation system prompt
  messages: [{ role: 'user', content: userPrompt }],   // single fresh message
  maxTokens: 1500,
  temperature: 0.3,
  enablePromptCache: false,
});
```

- `args.messages` (the full conversation history) is used only to **build the transcript text** — it is never sent to the API
- The API receives exactly **one user message**, matching the template's `"messages":[{"role":"user","content":...}]`
- It's a completely fresh call with no link to the existing session

**The `userPrompt` content matches the template exactly:**
```
Target CEFR level: B1
Tutor role: cousin -- his younger cousin who is currently living in Shanghai...
Learner role: a twenty-eight-year-old professional...

Assigned topic: Navigating generational gaps...

Assigned subtopics:
- the pressure of early marriage in Chengdu
- the reality of third-child policies in urban settings
...

Transcript:
[USER turn 0] Hello. Today I want to cook some food...
[TUTOR] Hello, Wei Wei. That is nice...
[USER turn 1] Yes. My mother likes dumplings from Suzhou.
...
```

No changes needed — the implementation already does exactly what you described.
