# Can you make AIModel project with nodejs that simulate the llama server. Because

Session: `ec7e9529-1399-4642-b1c1-753f53834cc7`
Saved: 2026-06-04T13:53:26.618Z

## User

Can you make AIModel project with nodejs that simulate the llama server.
Because our ai model doesn't trained yet, So I want test my application with the virtual AIModel.
So I can switch AIModel in .env in backend project. then AIModel behaves like the real llama server with qwen 3.5 9b. you can reference those txt for system prompt and evaluation prompt and evalution response.
Do you understand?

## Assistant

Let me first check how the backend currently calls the AI model to understand the exact API format needed:

## Assistant

The backend uses the **OpenAI-compatible provider** (`POST /v1/chat/completions`) with `response_format: json_schema` for evaluations and normal chat for conversations. I'll build a Node.js mock server that wraps Claude under the hood to give realistic responses.

## Assistant

The commented line `127.0.0.1:8081` is where the mock should run. Creating the project at `c:\project\vLearn2\ai_model_mock\`:

## Assistant

Now create the `.env` file with the Anthropic key (pre-filled from backend if it exists):

## Assistant

Also update the backend `.env` so switching is easy — uncomment the mock URL line and add a comment:

## Assistant

Now install dependencies and verify the server starts:

## Assistant

Server starts and responds. Now commit everything:

## Assistant

Done. Project is at [ai_model_mock/](ai_model_mock/).

**How to use:**

1. Set your Anthropic API key in [ai_model_mock/.env](ai_model_mock/.env)
2. `cd ai_model_mock && npm start`
3. In `backend/.env`, flip these three lines:
   ```
   OPENAI_BASE_URL=http://127.0.0.1:8081/v1
   AI_CHAT_MODEL=Qwen3.5-9B-mock
   AI_ANALYSIS_MODEL=Qwen3.5-9B-mock
   ```

**What it does:**
- **Conversation calls** → passes the tutor system prompt + messages straight to Claude Haiku, returns in OpenAI format
- **Evaluation calls** (detected by `response_format: json_schema`) → rewrites the `<think>` instruction for Claude, forces clean JSON output, strips any stray thinking blocks before returning
- Reports itself as `Qwen3.5-9B-mock` so the backend logging looks right
