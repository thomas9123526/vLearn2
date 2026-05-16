import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Anthropic from '@anthropic-ai/sdk';
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
export class AnthropicProvider extends AiProvider {
  private readonly logger = new Logger('AnthropicProvider');
  readonly name = 'anthropic';
  readonly capabilities: ProviderCapabilities = {
    supportsPromptCache: true,
    supportsStructuredOutput: true,
    supportsStreaming: true,
    contextWindowTokens: 200_000,
  };

  private readonly client: Anthropic;
  private readonly chatModel: string;
  private readonly analysisModel: string;

  constructor(config: ConfigService) {
    super();
    const apiKey = config.get<string>('ANTHROPIC_API_KEY');
    if (!apiKey) {
      this.logger.warn(
        'ANTHROPIC_API_KEY not set — AnthropicProvider will throw on use. Set the env var or AI_PROVIDER to a different value.',
      );
    }
    this.client = new Anthropic({ apiKey: apiKey ?? 'missing' });
    this.chatModel = config.get<string>('AI_CHAT_MODEL') ?? 'claude-sonnet-4-6';
    this.analysisModel =
      config.get<string>('AI_ANALYSIS_MODEL') ?? 'claude-haiku-4-5-20251001';
  }

  async chat(req: ChatRequest): Promise<ChatResponse> {
    const start = Date.now();
    try {
      const res = await this.client.messages.create({
        model: this.chatModel,
        system: req.enablePromptCache
          ? [
              {
                type: 'text',
                text: req.systemPrompt,
                cache_control: { type: 'ephemeral' },
              },
            ]
          : req.systemPrompt,
        messages: req.messages.map((m) => ({ role: m.role, content: m.content })),
        max_tokens: req.maxTokens ?? 400,
        temperature: req.temperature ?? 0.8,
      });
      const content =
        res.content
          .filter((b): b is Anthropic.TextBlock => b.type === 'text')
          .map((b) => b.text)
          .join('\n') ?? '';
      return {
        content,
        inputTokens: res.usage.input_tokens,
        outputTokens: res.usage.output_tokens,
        cachedTokens: res.usage.cache_read_input_tokens ?? undefined,
        modelUsed: res.model,
        latencyMs: Date.now() - start,
      };
    } catch (e: unknown) {
      throw this.translateError(e);
    }
  }

  async structured<T>(req: StructuredRequest): Promise<StructuredResponse<T>> {
    // Use Anthropic tool-use to enforce JSON schema. Caller passes a JSON
    // Schema; we synthesize a one-tool definition and force the model to call it.
    try {
      const res = await this.client.messages.create({
        model: this.analysisModel,
        system: req.systemPrompt,
        messages: [{ role: 'user', content: req.userPrompt }],
        max_tokens: req.maxTokens ?? 600,
        tools: [
          {
            name: 'return_result',
            description: 'Return the structured analysis result.',
            input_schema: req.jsonSchema as Anthropic.Tool.InputSchema,
          },
        ],
        tool_choice: { type: 'tool', name: 'return_result' },
      });
      const toolBlock = res.content.find(
        (b): b is Anthropic.ToolUseBlock => b.type === 'tool_use',
      );
      if (!toolBlock) {
        throw new AiProviderError(
          'invalid_response',
          true,
          'Model did not call the return_result tool',
        );
      }
      return {
        data: toolBlock.input as T,
        inputTokens: res.usage.input_tokens,
        outputTokens: res.usage.output_tokens,
        modelUsed: res.model,
      };
    } catch (e: unknown) {
      throw this.translateError(e);
    }
  }

  private translateError(e: unknown): AiProviderError {
    if (e instanceof Anthropic.APIError) {
      switch (e.status) {
        case 401:
          return new AiProviderError('unauthorized', false, 'Anthropic API key invalid', e);
        case 429:
          return new AiProviderError('rate_limit', true, 'Anthropic rate limit', e);
        case 529:
          return new AiProviderError('overloaded', true, 'Anthropic overloaded', e);
      }
    }
    if (e instanceof Error) {
      return new AiProviderError('unknown', false, e.message, e);
    }
    return new AiProviderError('unknown', false, 'Unknown AI error', e);
  }
}
