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
    const systemPrompt = await this.prompts.buildSystemPrompt(
      args.persona,
      args.scenario,
      args.userLevel,
      args.userNativeLanguage,
    );
    try {
      const res = await this.ai.chat({
        systemPrompt,
        messages: args.history,
        maxTokens: 1024,
        temperature: 0.8,
        enablePromptCache: this.ai.capabilities.supportsPromptCache,
      });
      const text = res.content.trim();
      if (!text) {
        this.logger.warn('AI chat returned empty text; using canned reply');
        return this.fallbackReply(args.history);
      }
      return text;
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
        userPrompt: await this.prompts.buildGrammarPrompt(userMessages, level),
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

  /**
   * Idle-prompt suggestion: the user has been silent in tutor mode for a
   * while; we ask the LLM for a short, conversational sentence the user can
   * read aloud (or tap to send) to keep things moving.
   *
   * Falls back to a canned suggestion when the AI is offline so the UI
   * always has something to show.
   */
  async suggestNextLine(args: {
    persona: PersonaEntity;
    scenario: ScenarioEntity | null;
    userLevel: number;
    userNativeLanguage: string;
    history: ChatMessage[];
  }): Promise<string> {
    const baseSystem = await this.prompts.buildSystemPrompt(
      args.persona,
      args.scenario,
      args.userLevel,
      args.userNativeLanguage,
    );
    const systemPrompt =
      baseSystem +
      '\n\nThe student has gone quiet. Reply ONLY with a single short English sentence (8–15 words) ' +
      'the student could say next to continue the conversation. ' +
      'Do not introduce yourself, do not explain, do not use quotation marks.';
    try {
      const res = await this.ai.chat({
        systemPrompt,
        messages: args.history,
        maxTokens: 256,
        temperature: 0.7,
        enablePromptCache: this.ai.capabilities.supportsPromptCache,
      });
      const text = res.content
          .replace(/^["'`\s]+|["'`\s]+$/g, '')
          .replace(/\s+/g, ' ')
          .trim();
      if (!text) {
        this.logger.warn('AI suggestion returned empty text; using canned suggestion');
        return this.fallbackSuggestion(args.history);
      }
      return text;
    } catch (e) {
      this.logger.warn(`AI suggestion failed (${(e as AiProviderError).kind}): using canned suggestion`);
      return this.fallbackSuggestion(args.history);
    }
  }

  private fallbackSuggestion(history: ChatMessage[]): string {
    // If the assistant just asked a question, suggest a friendly opener.
    // Otherwise nudge the user to ask the tutor a question.
    const lastAssistant = [...history].reverse().find((m) => m.role === 'assistant');
    const content = lastAssistant?.content.trim() ?? '';
    if (content.endsWith('?')) {
      return "I'm not sure — could you give me an example?";
    }
    return 'That sounds interesting — could you tell me more?';
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
