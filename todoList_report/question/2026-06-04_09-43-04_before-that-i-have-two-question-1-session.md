# before that, I have two question. 1. Session feedback prompt is the evaluation p

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-04T00:43:04.021Z

## User

before that, I have two question.
1. Session feedback prompt is the evaluation prompt that is sent to our model at the end of the conversation?
2. where does it 'Grammar analysis prompt' used in our project? what are this prompt's role?

## Assistant

**1. Session feedback prompt ≠ evaluation prompt — they're two separate AI calls:**

| | Evaluation (`evaluateSession`) | Session feedback (`buildFeedbackPrompt`) |
|---|---|---|
| **When** | End of session | End of session (after evaluation) |
| **Input** | Full conversation transcript | Already-computed numeric scores |
| **AI output** | Structured JSON (`scores`, `specific_feedback`, `strengths`, CEFR estimate) | 2–3 sentence human-readable encouragement paragraph |
| **Role** | Scores the learner's performance | Turns those scores into a friendly message shown to the user |

The evaluation prompt is what actually interacts with your ConversationModel. The feedback prompt is a secondary call that wraps the scores in warm language for the UI.

---

**2. Grammar analysis prompt — role and location:**

It runs **per-session** (after the session ends) as part of the scoring pipeline in [`conversations.service.ts`](backend/src/conversations/conversations.service.ts). Flow:

```
session ends
  → scoreGrammar(userMessages, level)          ← sends all user messages to AI
      → AI returns { grammar_score: 0-100, errors_found[], strengths[] }
  → this grammar_score feeds into the overall session score
  → evaluateSession(transcript)                ← separate CEFR evaluation
  → buildFeedbackPrompt(scores)                ← generates friendly text
```

Its role is purely **grammar quality scoring** — it's separate from the CEFR evaluation and gives a 0–100 numeric grammar grade that goes into the session score breakdown (alongside fluency, vocabulary, engagement). The CEFR evaluation (`evaluateSession`) does its own independent scoring of the full transcript.

**Implication for your model:** Both `scoreGrammar` and `evaluateSession` are sent to the same AI provider (your custom model). The grammar prompt is a `structured()` call that expects JSON output. The evaluation is a `chat()` call that expects `<think>…</think>` + JSON. If your model doesn't handle the grammar structured-output format well, you can disable it — `scoreGrammar` already returns `null` on failure and the pipeline handles that gracefully.
