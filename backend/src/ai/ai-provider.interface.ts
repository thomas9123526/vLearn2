export interface ChatMessage {
  role: 'user' | 'assistant';
  content: string;
}

export interface ChatRequest {
  systemPrompt: string;
  messages: ChatMessage[];
  maxTokens?: number;
  temperature?: number;
  enablePromptCache?: boolean;
}

export interface ChatResponse {
  content: string;
  inputTokens: number;
  outputTokens: number;
  cachedTokens?: number;
  modelUsed: string;
  latencyMs: number;
}

export interface StructuredRequest {
  systemPrompt: string;
  userPrompt: string;
  jsonSchema: object;
  maxTokens?: number;
}

export interface StructuredResponse<T> {
  data: T;
  inputTokens: number;
  outputTokens: number;
  modelUsed: string;
}

export interface ProviderCapabilities {
  supportsPromptCache: boolean;
  supportsStructuredOutput: boolean;
  supportsStreaming: boolean;
  contextWindowTokens: number;
}

export class AiProviderError extends Error {
  constructor(
    public readonly kind:
      | 'rate_limit'
      | 'overloaded'
      | 'timeout'
      | 'invalid_response'
      | 'unauthorized'
      | 'unknown',
    public readonly retryable: boolean,
    message: string,
    public readonly cause?: unknown,
  ) {
    super(message);
    this.name = 'AiProviderError';
  }
}

/**
 * Provider-agnostic AI interface. Spec'd in todoList/09 §9.2.
 *
 * Implementations live under src/ai/providers/. Business code (e.g.
 * ConversationOrchestrator) depends only on this interface, never on the
 * concrete @anthropic-ai/sdk or openai SDK.
 */
export abstract class AiProvider {
  abstract readonly name: string;
  abstract readonly capabilities: ProviderCapabilities;

  abstract chat(req: ChatRequest): Promise<ChatResponse>;
  abstract structured<T>(req: StructuredRequest): Promise<StructuredResponse<T>>;
}

export const AI_PROVIDER = 'AI_PROVIDER';
