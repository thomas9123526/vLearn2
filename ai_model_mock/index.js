/**
 * AI Model Mock Server
 *
 * Exposes an OpenAI-compatible `POST /v1/chat/completions` endpoint that
 * internally calls the Anthropic Claude API and returns responses formatted
 * exactly as a llama.cpp / llama-server would. Lets the vLearn2 backend run
 * with AI_PROVIDER=openai-compatible and OPENAI_BASE_URL pointing here
 * while the real Qwen model is not yet available.
 *
 * Set OPENAI_BASE_URL=http://127.0.0.1:8081/v1 in backend/.env to activate.
 */

require('dotenv').config();

const express  = require('express');
const Anthropic = require('@anthropic-ai/sdk');
const { v4: uuidv4 } = require('uuid');
const { findPreCannedResponse } = require('./data/conversations');

// ── Config ──────────────────────────────────────────────────────────────────

const PORT          = parseInt(process.env.PORT ?? '8081', 10);
const MOCK_MODEL    = process.env.MOCK_MODEL_NAME ?? 'Qwen3.5-9B-mock';
const CHAT_MODEL    = process.env.CHAT_MODEL    ?? 'claude-haiku-4-5-20251001';
const ANALYSIS_MODEL= process.env.ANALYSIS_MODEL ?? 'claude-haiku-4-5-20251001';
const LOG_BODIES    = process.env.LOG_BODIES === 'true';

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

// ── Helpers ─────────────────────────────────────────────────────────────────

function isEvaluationRequest(body) {
  // The backend sends response_format.type === 'json_schema' only for eval calls.
  if (body.response_format?.type === 'json_schema') return true;
  // Fallback: peek at the system prompt content.
  const sys = body.messages?.find(m => m.role === 'system')?.content ?? '';
  return sys.includes('EvaluationOutput') || sys.includes('English examiner');
}

/** Strip <think>…</think> blocks and any leading/trailing markdown fences. */
function cleanContent(text) {
  return text
    .replace(/<think>[\s\S]*?<\/think>/gi, '')
    .replace(/^```(?:json)?\s*/i, '')
    .replace(/\s*```$/i, '')
    .trim();
}

/** Parse JSON from the model output, return null on failure. */
function tryParseJson(text) {
  const cleaned = cleanContent(text);
  // Find the first '{' and last '}' to tolerate extra prose.
  const start = cleaned.indexOf('{');
  const end   = cleaned.lastIndexOf('}');
  if (start === -1 || end === -1) return null;
  try {
    return JSON.parse(cleaned.slice(start, end + 1));
  } catch {
    return null;
  }
}

/** Build the Anthropic system + messages for a conversation call. */
function buildConversationPayload(messages) {
  const systemMsg = messages.find(m => m.role === 'system');
  const chatMsgs  = messages.filter(m => m.role !== 'system');
  return {
    system: systemMsg?.content ?? '',
    messages: chatMsgs.map(m => ({ role: m.role, content: m.content })),
  };
}

/**
 * Build the Anthropic system + messages for an evaluation call.
 * Appends a hard instruction to output pure JSON — Claude doesn't support
 * response_format natively so we achieve it via prompt engineering.
 */
function buildEvaluationPayload(messages, jsonSchema) {
  const systemMsg = messages.find(m => m.role === 'system');
  const chatMsgs  = messages.filter(m => m.role !== 'system');

  let system = systemMsg?.content ?? '';

  // Replace the <think>...</think> instruction (meant for Qwen thinking mode)
  // with a cleaner instruction that works with Claude.
  system = system.replace(
    /produce a <think>[\s\S]*?<\/think>[^\n]*/gi,
    'Reason carefully about the learner\'s USER turns internally, then output',
  );

  const schemaHint = jsonSchema
    ? `\n\nOUTPUT RULES:\n- Respond with ONLY a valid JSON object matching this schema:\n${JSON.stringify(jsonSchema, null, 2)}\n- No prose, no markdown fences, no <think> blocks.`
    : '\n\nOUTPUT RULES:\n- Respond with ONLY a valid JSON object (EvaluationOutput schema).\n- No prose, no markdown fences.';

  system += schemaHint;

  return {
    system,
    messages: chatMsgs.map(m => ({ role: m.role, content: m.content })),
  };
}

/** Wrap a content string into an OpenAI-compatible chat.completion response. */
function openAiResponse(content, promptTokens, completionTokens) {
  return {
    id: `chatcmpl-${uuidv4()}`,
    object: 'chat.completion',
    created: Math.floor(Date.now() / 1000),
    model: MOCK_MODEL,
    choices: [
      {
        index: 0,
        message: { role: 'assistant', content },
        finish_reason: 'stop',
      },
    ],
    usage: {
      prompt_tokens: promptTokens,
      completion_tokens: completionTokens,
      total_tokens: promptTokens + completionTokens,
    },
  };
}

// ── Routes ───────────────────────────────────────────────────────────────────

const app = express();
app.use(express.json({ limit: '20mb' }));

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', model: MOCK_MODEL, uptime: process.uptime() });
});

app.get('/v1/models', (_req, res) => {
  res.json({
    object: 'list',
    data: [
      {
        id: MOCK_MODEL,
        object: 'model',
        created: Math.floor(Date.now() / 1000),
        owned_by: 'mock',
      },
    ],
  });
});

app.post('/v1/chat/completions', async (req, res) => {
  const body = req.body;

  if (LOG_BODIES) {
    console.log('\n── REQUEST ─────────────────────────────');
    console.log(JSON.stringify(body, null, 2));
  }

  const isEval   = isEvaluationRequest(body);
  const model    = isEval ? ANALYSIS_MODEL : CHAT_MODEL;
  const maxTok   = body.max_tokens ?? (isEval ? 1500 : 1024);
  const temp     = body.temperature ?? (isEval ? 0.3 : 0.7);
  const messages = body.messages ?? [];

  console.log(`[${new Date().toISOString()}] ${isEval ? 'EVAL' : 'CHAT'} → ${model}  max_tokens=${maxTok}`);

  // ── Pre-canned dataset lookup (conversation turns only) ───────────────────
  if (!isEval) {
    const canned = findPreCannedResponse(messages);
    if (canned !== null) {
      console.log(`[${new Date().toISOString()}] CHAT → dataset hit  (${canned.length} chars)`);
      if (LOG_BODIES) {
        console.log('\n── RESPONSE (pre-canned) ───────────────');
        console.log(canned.slice(0, 500));
      }
      // Estimate tokens: ~1 token per 4 chars (rough llama.cpp parity)
      const promptTokens     = Math.ceil(JSON.stringify(messages).length / 4);
      const completionTokens = Math.ceil(canned.length / 4);
      return res.json(openAiResponse(canned, promptTokens, completionTokens));
    }
    console.log(`[${new Date().toISOString()}] CHAT → no dataset match, falling back to Claude`);
  }

  // ── Claude API fallback ────────────────────────────────────────────────────
  const { system, messages: anthropicMessages } = isEval
    ? buildEvaluationPayload(messages, body.response_format?.json_schema?.schema)
    : buildConversationPayload(messages);

  try {
    const response = await anthropic.messages.create({
      model,
      system: system || undefined,
      messages: anthropicMessages,
      max_tokens: maxTok,
      temperature: temp,
    });

    let content = response.content[0]?.text ?? '';

    if (isEval) {
      // Ensure the backend receives clean JSON (it will JSON.parse the content).
      const parsed = tryParseJson(content);
      if (parsed) {
        content = JSON.stringify(parsed);
      } else {
        console.warn('⚠️  Evaluation response could not be parsed as JSON — returning raw');
      }
    }

    if (LOG_BODIES) {
      console.log('\n── RESPONSE ────────────────────────────');
      console.log(content.slice(0, 500));
    }

    const result = openAiResponse(
      content,
      response.usage.input_tokens,
      response.usage.output_tokens,
    );

    res.json(result);
  } catch (err) {
    console.error('Anthropic call failed:', err.message ?? err);
    res.status(500).json({
      error: {
        message: err.message ?? 'Internal error',
        type: 'api_error',
        code: 'mock_server_error',
      },
    });
  }
});

// ── Start ─────────────────────────────────────────────────────────────────────

app.listen(PORT, () => {
  console.log('');
  console.log('╔══════════════════════════════════════════════════╗');
  console.log('║          vLearn2 — AI Model Mock Server           ║');
  console.log('╚══════════════════════════════════════════════════╝');
  console.log(`  URL       : http://localhost:${PORT}/v1`);
  console.log(`  Model     : ${MOCK_MODEL}`);
  console.log(`  Chat via  : ${CHAT_MODEL}`);
  console.log(`  Eval via  : ${ANALYSIS_MODEL}`);
  console.log(`  Log bodies: ${LOG_BODIES}`);
  console.log('');
  console.log('  → In backend/.env set:');
  console.log(`  OPENAI_BASE_URL=http://127.0.0.1:${PORT}/v1`);
  console.log('');
});
