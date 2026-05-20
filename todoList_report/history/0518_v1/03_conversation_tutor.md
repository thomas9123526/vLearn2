# Report — 03_conversation_tutor

## Source request

`todoList/0518_v1/03_conversation_tutor.txt`:

> there should be recommendataion or request when the user enter conversation screen and the user never answer or reply to ai tutor.
> Ai tutor can suggest some sentences to continue the conversation.
> Ai tutor can request some information to the user or ask about his feelings to do the conversation friendly.
> Is it possible?

**Short answer: yes.** Done end-to-end through the AI orchestrator that already powers tutor replies.

## What was implemented

### Backend — orchestrator + endpoint

[backend/src/ai/conversation.orchestrator.ts](../../backend/src/ai/conversation.orchestrator.ts):

```ts
async suggestNextLine(args: {
  persona, scenario, userLevel, userNativeLanguage, history
}): Promise<string>
```

- Reuses the existing system prompt builder (so the suggestion is in character for the active persona / scenario / user level).
- Appends a hard constraint to the system prompt: "*Reply ONLY with a single short English sentence (8–15 words) the student could say next. Do not introduce yourself, do not explain, do not use quotation marks.*"
- Token cap of 60, temperature 0.7 (slightly lower than chat replies to avoid drift).
- Strips surrounding quotes/whitespace the model might still emit.
- Falls back to a canned suggestion if the AI provider is offline so the UI always has something to show. Two canned variants depending on whether the assistant's last turn ended in a question.

[backend/src/conversations/conversations.service.ts](../../backend/src/conversations/conversations.service.ts):

```ts
async suggestNextLine(userId, sessionId): Promise<{ suggestion: string }>
```

- Standard auth checks (session exists, belongs to the user, is active).
- Loads persona + scenario + user + full history, delegates to the orchestrator.
- Returns `{ suggestion: string }` so the contract is greppable on the client.

[backend/src/conversations/conversations.module.ts](../../backend/src/conversations/conversations.module.ts):

```
POST /conversations/sessions/:id/suggest
```

Documented in Swagger with the `Tutor / idle prompt` summary.

### Flutter — silence timer + chip UI

[flutter_app/lib/core/api/app_apis.dart](../../flutter_app/lib/core/api/app_apis.dart) gets a new `ConversationsApi.suggestNextLine(sessionId)` method that swallows network errors and returns `null` (so the UI can fall back gracefully).

[flutter_app/lib/features/conversation/widgets/tutor_mode_view.dart](../../flutter_app/lib/features/conversation/widgets/tutor_mode_view.dart):

- Holds a `Timer? _idleTimer` that resets every time:
  - the widget first mounts,
  - `didUpdateWidget` fires with a new message list,
  - the user starts/stops recording.
- The timer only arms when the **most recent turn is from the assistant** (no point suggesting a reply when the user just said something).
- After **20 seconds** of silence:
  - The mood flips to `encouraging` (driving the 🌱 / 💪 emoji cluster around the avatar).
  - The new endpoint is called.
  - The suggestion shows up as a tappable **`_SuggestionChip`** ("Try: …") below the live caption.
- Tapping the chip clears it and submits the suggestion through the normal `onSendText` flow, so it lands in the session like any other user turn.

### Why 20 seconds?

Short enough to feel responsive, long enough that a normal pause to think doesn't trigger it. The constant is local to the widget — easy to tune later or move to `app_config` if user feedback says it's wrong.

## Decisions / call-outs

- **No client-side rate limiter.** The endpoint is cheap (one short LLM call) and the timer naturally caps frequency at one call per ~20 s.
- **Suggestion is text-only**, not spoken. The tutor's voice doesn't put words in the user's mouth — the user reads the chip silently and decides. Speaking it would feel pushy.
- **Suggestion vanishes when a new turn arrives**, so a stale chip doesn't sit on screen suggesting something that doesn't fit the new context.
- **Canned fallback** uses one of two variants based on whether the assistant's last turn ended in a question — gives the suggestion a logical hand-off even when the LLM is unavailable.
- **Did NOT** persist suggestions in the database. They're ephemeral hints, not history; analytics would be more valuable as "did the user accept the suggestion?" which can be derived from message text matching later.
