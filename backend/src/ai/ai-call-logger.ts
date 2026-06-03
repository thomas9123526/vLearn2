/**
 * AiCallLogger — prints structured, box-bordered AI call logs to stdout.
 *
 * Box width: 80 chars. Sections use thick (═) and thin (─) dividers.
 * Long lines and multi-line values are wrapped inside the box.
 *
 * Four entry-points:
 *   AiCallLogger.request()          – orchestrator: before sending to AI
 *   AiCallLogger.response()         – orchestrator: after receiving from AI
 *   AiCallLogger.providerRequest()  – provider:    raw HTTP send details
 *   AiCallLogger.providerResponse() – provider:    raw HTTP receive details
 */

const W = 80;       // total outer width  ║ ... ║
const IW = W - 4;  // inner content width (after "║  " and before "  ║")

function top():     string { return `╔${'═'.repeat(W - 2)}╗`; }
function bottom():  string { return `╚${'═'.repeat(W - 2)}╝`; }
function thick():   string { return `╠${'═'.repeat(W - 2)}╣`; }
function thin():    string { return `╟${'─'.repeat(W - 2)}╢`; }

/** Wrap `text` into ║  …  ║ rows, breaking at IW chars. */
function rows(text: string, indent = ''): string[] {
  const out: string[] = [];
  for (const rawLine of (text ?? '').split('\n')) {
    let s = indent + rawLine;
    if (!s.length) { out.push(`║  ${''.padEnd(IW)}  ║`); continue; }
    while (s.length > IW) {
      out.push(`║  ${s.slice(0, IW)}  ║`);
      s = indent + s.slice(IW);
    }
    out.push(`║  ${s.padEnd(IW)}  ║`);
  }
  return out;
}

// ── Public API ─────────────────────────────────────────────────────────────

export interface PromptVariable {
  value: string;
  from: string; // e.g. "persona DB row", "scenario DB row", "user_progress", "user_info"
}

export class AiCallLogger {

  /**
   * Printed by the orchestrator BEFORE submitting the prompt to the AI provider.
   * Shows: call type, timestamp, prompt assembly source, all variables + origins,
   * the final system prompt, and the full conversation history.
   */
  static request(opts: {
    callType: string;
    timestamp: string;
    promptSource: string;   // e.g. "custom_prompt (scenario override)" | "DB template: tutor_system" | "section-builder"
    variables: Record<string, PromptVariable>;
    systemPrompt: string;
    history: Array<{ role: string; content: string }>;
  }): void {
    const userCount  = opts.history.filter(m => m.role === 'user').length;
    const asstCount  = opts.history.filter(m => m.role === 'assistant').length;

    const lines: string[] = [
      top(),
      ...rows(`► AI REQUEST  ·  ${opts.callType}  ·  ${opts.timestamp}`),
      thick(),
      ...rows('PROMPT ASSEMBLY'),
      ...rows(`  source : ${opts.promptSource}`),
    ];

    // Group variables by their origin
    const groups = new Map<string, Array<[string, string]>>();
    for (const [k, v] of Object.entries(opts.variables)) {
      const src = v.from;
      if (!groups.has(src)) groups.set(src, []);
      groups.get(src)!.push([k, v.value]);
    }
    for (const [src, pairs] of groups) {
      lines.push(...rows(`  ── from: ${src}`));
      for (const [k, v] of pairs) {
        const display = v.length > 55 ? v.slice(0, 52) + '...' : v;
        lines.push(...rows(`    ${k.padEnd(30)} = ${display}`));
      }
    }

    // System prompt block
    lines.push(
      thick(),
      ...rows(`SYSTEM PROMPT  (${opts.systemPrompt.length} chars)`),
      thin(),
      ...rows(opts.systemPrompt),
    );

    // History block
    lines.push(
      thick(),
      ...rows(`CONVERSATION HISTORY  (${opts.history.length} messages · ${userCount} user / ${asstCount} assistant)`),
      thin(),
    );
    for (const m of opts.history) {
      const tag     = m.role === 'user' ? '[user     ]' : '[assistant]';
      const preview = m.content.length > 100 ? m.content.slice(0, 97) + '...' : m.content;
      lines.push(...rows(`${tag}  ${preview}`));
    }

    lines.push(bottom());
    console.log('\n' + lines.join('\n'));
  }

  /**
   * Printed by the orchestrator AFTER receiving the reply from the AI provider.
   */
  static response(opts: {
    callType: string;
    latencyMs: number;
    modelUsed: string;
    inputTokens: number;
    outputTokens: number;
    cachedTokens?: number;
    content: string;
  }): void {
    const cached = opts.cachedTokens != null ? ` / cached=${opts.cachedTokens}` : '';
    const lines: string[] = [
      top(),
      ...rows(`◄ AI RESPONSE  ·  ${opts.callType}  ·  ${opts.latencyMs}ms`),
      thick(),
      ...rows(`  model   : ${opts.modelUsed}`),
      ...rows(`  tokens  : in=${opts.inputTokens} / out=${opts.outputTokens}${cached}`),
      thick(),
      ...rows('CONTENT'),
      thin(),
      ...rows(opts.content),
      bottom(),
    ];
    console.log('\n' + lines.join('\n'));
  }

  /**
   * Printed by the AI provider class BEFORE the HTTP call leaves the process.
   * Shows the actual endpoint URL, model, and request parameters.
   */
  static providerRequest(opts: {
    provider: string;
    endpoint: string;          // full URL, e.g. https://api.anthropic.com/v1/messages
    model: string;
    callType: 'chat' | 'structured';
    maxTokens: number;
    temperature?: number;
    systemLength: number;
    messageCount: number;
    cacheEnabled?: boolean;
  }): void {
    const lines: string[] = [
      top(),
      ...rows(`  [${opts.provider}]  ►  ${opts.callType.toUpperCase()} REQUEST`),
      thick(),
      ...rows(`  endpoint   :  POST ${opts.endpoint}`),
      ...rows(`  model      :  ${opts.model}`),
      ...rows(`  max_tokens :  ${opts.maxTokens}    temperature: ${opts.temperature ?? 'default'}`),
      ...rows(`  system     :  ${opts.systemLength} chars`),
      ...rows(`  messages   :  ${opts.messageCount}`),
      ...(opts.cacheEnabled ? rows(`  cache      :  ephemeral (prompt-cache ON)`) : []),
      bottom(),
    ];
    console.log('\n' + lines.join('\n'));
  }

  /**
   * Printed by the AI provider class AFTER receiving the HTTP response.
   */
  static providerResponse(opts: {
    provider: string;
    callType: 'chat' | 'structured';
    latencyMs: number;
    modelUsed: string;
    inputTokens: number;
    outputTokens: number;
    cachedTokens?: number;
    content: string;
  }): void {
    const cached = opts.cachedTokens != null ? ` / cached=${opts.cachedTokens}` : '';
    const lines: string[] = [
      top(),
      ...rows(`  [${opts.provider}]  ◄  ${opts.callType.toUpperCase()} RESPONSE  ·  ${opts.latencyMs}ms`),
      thick(),
      ...rows(`  model   :  ${opts.modelUsed}`),
      ...rows(`  tokens  :  in=${opts.inputTokens} / out=${opts.outputTokens}${cached}`),
      thick(),
      ...rows('CONTENT'),
      thin(),
      ...rows(opts.content),
      bottom(),
    ];
    console.log('\n' + lines.join('\n'));
  }
}
