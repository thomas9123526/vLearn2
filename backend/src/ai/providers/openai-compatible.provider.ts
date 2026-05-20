import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import OpenAI from 'openai';
import {
  AiProvider,
  AiProviderError,
  ChatRequest,
  ChatResponse,
  ProviderCapabilities,
  StructuredRequest,
  StructuredResponse,
} from '../ai-provider.interface';

@Injectable()
export class OpenAICompatibleProvider extends AiProvider {
  private readonly logger = new Logger('OpenAICompatibleProvider');
  readonly name: string;
  readonly capabilities: ProviderCapabilities = {
    supportsPromptCache: false,
    supportsStructuredOutput: true, // via response_format json_schema; fallback to json_object
    supportsStreaming: true,
    contextWindowTokens: 128_000,
  };

  private readonly client: OpenAI;
  private readonly chatModel: string;
  private readonly analysisModel: string;

  constructor(config: ConfigService) {
    super();
    const baseURL = config.get<string>('OPENAI_BASE_URL');
    if (!baseURL) {
      this.logger.warn(
        'OPENAI_BASE_URL not set — OpenAICompatibleProvider will throw on use.',
      );
    }
    this.client = new OpenAI({
      baseURL: baseURL ?? 'http://localhost:11434/v1',
      apiKey: config.get<string>('OPENAI_API_KEY') ?? 'not-needed',
    });
    this.name = config.get<string>('AI_PROVIDER_LABEL') ?? 'openai-compatible';
    this.chatModel = config.get<string>('AI_CHAT_MODEL') ?? 'llama3.1:70b';
    this.analysisModel =
      config.get<string>('AI_ANALYSIS_MODEL') ?? 'llama3.1:8b';
  }

  async chat(req: ChatRequest): Promise<ChatResponse> {
    const start = Date.now();
    // Debug: prove the full system prompt leaves the backend. Look for this
    // line in the backend console; LM Studio's log UI truncates the display
    // but our outbound payload is intact.
    this.logger.log(
      `OUTBOUND system_prompt (${req.systemPrompt.length} chars): ${req.systemPrompt}`,
    );
    try {
      const res = await this.client.chat.completions.create({
        model: this.chatModel,
        messages: [
          { role: 'system', content: req.systemPrompt },
          ...req.messages.map((m) => ({ role: m.role, content: m.content })),
        ],
        max_tokens: req.maxTokens ?? 400,
        temperature: req.temperature ?? 0.8,
      });
      const content = this.extractAssistantText(res.choices[0]?.message);
      if (!content) {
        this.logger.warn(
          'Model returned empty assistant content (common with Qwen3 reasoning when max_tokens is too low). ' +
            'Raise max_tokens or disable reasoning in LM Studio.',
        );
      }
      return {
        content,
        inputTokens: res.usage?.prompt_tokens ?? 0,
        outputTokens: res.usage?.completion_tokens ?? 0,
        modelUsed: res.model,
        latencyMs: Date.now() - start,
      };
    } catch (e: unknown) {
      throw this.translateError(e);
    }
  }

  async structured<T>(req: StructuredRequest): Promise<StructuredResponse<T>> {
    try {
      // Try json_schema first (supported by Groq, OpenAI; ignored by older Ollama)
      const res = await this.client.chat.completions.create({
        model: this.analysisModel,
        messages: [
          { role: 'system', content: req.systemPrompt },
          { role: 'user', content: req.userPrompt },
        ],
        max_tokens: req.maxTokens ?? 600,
        response_format: {
          type: 'json_schema',
          json_schema: {
            name: 'return_result',
            schema: req.jsonSchema as Record<string, unknown>,
            strict: true,
          },
        },
      });
      const raw = this.extractAssistantText(res.choices[0]?.message) || '{}';
      let parsed: unknown;
      try {
        parsed = JSON.parse(raw);
      } catch {
        throw new AiProviderError(
          'invalid_response',
          true,
          'Could not parse model JSON',
        );
      }
      return {
        data: parsed as T,
        inputTokens: res.usage?.prompt_tokens ?? 0,
        outputTokens: res.usage?.completion_tokens ?? 0,
        modelUsed: res.model,
      };
    } catch (e: unknown) {
      // TODO: fallback to response_format: 'json_object' for Ollama compatibility
      throw this.translateError(e);
    }
  }

  /**
   * llama.cpp / Qwen3 "reasoning" models often fill `reasoning_content` first
   * and leave `content` empty when `max_tokens` is small. Prefer `content`,
   * then a trimmed tail of reasoning so the app is not silent.
   */
  private extractAssistantText(
    message: OpenAI.Chat.Completions.ChatCompletionMessage | undefined,
  ): string {
    if (!message) return '';
    const content = message.content?.trim() ?? '';
    if (content) return content;

    const reasoning = (
      message as OpenAI.Chat.Completions.ChatCompletionMessage & {
        reasoning_content?: string;
      }
    ).reasoning_content?.trim();
    if (!reasoning) return '';

    // Drop obvious chain-of-thought wrappers; keep the last substantive line.
    const stripped = reasoning
      .replace(/[\s\S]*?<\/think>/gi, '')
      .replace(/^thinking:\s*/i, '')
      .trim();
    const lines = stripped
      .split(/\r?\n/)
      .map((l) => l.trim())
      .filter(Boolean);
    return lines.length > 0 ? lines[lines.length - 1] : stripped;
  }

  private translateError(e: unknown): AiProviderError {
    if (e instanceof OpenAI.APIError) {
      switch (e.status) {
        case 401:
          return new AiProviderError(
            'unauthorized',
            false,
            'OpenAI-compatible auth failed',
            e,
          );
        case 429:
          return new AiProviderError(
            'rate_limit',
            true,
            'OpenAI-compatible rate limit',
            e,
          );
        case 503:
          return new AiProviderError(
            'overloaded',
            true,
            'Backend overloaded',
            e,
          );
      }
    }
    if (e instanceof Error) {
      return new AiProviderError('unknown', false, e.message, e);
    }
    return new AiProviderError('unknown', false, 'Unknown AI error', e);
  }
}
