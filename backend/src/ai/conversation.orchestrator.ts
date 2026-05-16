import { Inject, Injectable, Logger } from '@nestjs/common';
import { AI_PROVIDER, AiProvider, ChatMessage, AiProviderError } from './ai-provider.interface';
import { PromptBuilderService } from './prompt-builder.service';
import type { PersonaEntity } from '../database/entities/persona.entity';
import type { ScenarioEntity } from '../database/entities/scenario.entity';

/**
 * Provider-agnostic orchestration. ConversationsService should call this
 * instead of the raw provider so prompt-building + caching hints stay in
 * one place.
 */
@Injectable()
export class ConversationOrchestrator {
  private readonly logger = new Logger('ConversationOrchestrator');

  constructor(
    @Inject(AI_PROVIDER) private readonly ai: AiProvider,
    private readonly prompts: PromptBuilderService,
  ) {}

  async generateTutorReply(args: {
    persona: PersonaEntity;
    scenario: ScenarioEntity | null;
    userLevel: number;
    userNativeLanguage: string;
    history: ChatMessage[];
  }): Promise<string> {
    const systemPrompt = this.prompts.buildSystemPrompt(
      args.persona,
      args.scenario,
      args.userLevel,
      args.userNativeLanguage,
    );
    try {
      const res = await this.ai.chat({
        systemPrompt,
        messages: args.history,
        maxTokens: 300,
        temperature: 0.8,
        enablePromptCache: this.ai.capabilities.supportsPromptCache,
      });
      return res.content;
    } catch (e) {
      this.logger.warn(`AI chat failed (${(e as AiProviderError).kind}): falling back to canned reply`);
      return this.fallbackReply(args.history);
    }
  }

  /**
   * Generates a grammar analysis. Returns null when AI is unavailable so the
   * scoring pipeline can use algorithmic-only scores.
   */
  async scoreGrammar(userMessages: string[], level: number): Promise<{
    grammar_score: number;
    errors_found: string[];
    strengths: string[];
  } | null> {
    try {
      const res = await this.ai.structured<{
        grammar_score: number;
        errors_found: string[];
        strengths: string[];
      }>({
        systemPrompt: 'You are an expert English grammar evaluator.',
        userPrompt: this.prompts.buildGrammarPrompt(userMessages, level),
        jsonSchema: {
          type: 'object',
          properties: {
            grammar_score: { type: 'integer', minimum: 0, maximum: 100 },
            errors_found: { type: 'array', items: { type: 'string' } },
            strengths: { type: 'array', items: { type: 'string' } },
          },
          required: ['grammar_score', 'errors_found', 'strengths'],
          additionalProperties: false,
        },
        maxTokens: 500,
      });
      return res.data;
    } catch (e) {
      this.logger.warn(`Grammar scoring unavailable: ${(e as Error).message}`);
      return null;
    }
  }

  private fallbackReply(history: ChatMessage[]): string {
    const lastUser = [...history].reverse().find((m) => m.role === 'user');
    const content = lastUser?.content.trim().toLowerCase() ?? '';
    if (content.length < 8) {
      return 'Could you tell me a bit more? I want to hear what you have to say.';
    }
    if (content.endsWith('?')) {
      return "That's a great question! What do you think the answer might be?";
    }
    return 'Nice! Can you tell me more about your experience with this?';
  }
}
