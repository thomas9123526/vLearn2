# populate mock conversation with this data but ai mock server must follow llama r

Session: `34d1d679-ee92-4cba-804e-889584bec133`
Saved: 2026-06-04T14:34:21.296Z

## User

populate mock conversation with this data but ai mock server must follow llama rule for input and response format.

## Assistant

Let me explore the mock server and understand its current structure.

## Assistant

Now I understand the structure. The server currently calls Claude API for every request. The task is to embed the provided conversation examples and serve them as pre-canned responses (matching by system prompt + conversation depth), following the llama.cpp OpenAI-compatible format. Let me implement this.

## Assistant

Now update `index.js` to use the dataset before falling back to Claude:

## Assistant

Now add the pre-canned lookup in the POST handler, before calling Claude:

## Assistant

Let me verify the final state of `index.js` looks correct:

## Assistant

Good. Now let me do a quick sanity check that node can load the new data file without errors:

## Assistant

Works perfectly. Now commit with the story file:

## Assistant

Done. Here's what was implemented:

**`ai_model_mock/data/conversations.js`** — 6 pre-canned examples from the 4 JSON files:
- A1: Mom / calling a parent
- A2: doctor / health; Sales Assistant / shopping
- B2 ×2: Cousin Liu / sibling responsibilities (speaks_l1 + requests_l1 variants)
- C1: Uncle Wei / intergenerational bonds

**Matching logic** (`findPreCannedResponse`): indexes examples by exact system prompt. On each request, it counts user-turn depth in the incoming messages and returns the corresponding pre-canned assistant turn.

**[`index.js`](ai_model_mock/index.js) changes** — for conversation requests (non-eval):
1. Tries the dataset first → returns pre-canned reply immediately, zero API cost
2. Logs `CHAT → dataset hit` or `CHAT → no dataset match, falling back to Claude`
3. Eval requests always go to Claude (JSON schema evaluation logic isn't in the dataset)

The response envelope is unchanged — llama.cpp-compatible `chat.completion` format with `choices[0].message.content`, `finish_reason: 'stop'`, and `usage` tokens.
