import { Inject, Injectable, Logger } from '@nestjs/common';
import {
  AI_PROVIDER,
  AiProvider,
  ChatMessage,
  AiProviderError,
} from './ai-provider.interface';
import { PromptBuilderService } from './prompt-builder.service';
import type { PersonaEntity } from '../database/entities/persona.entity';
import type { ScenarioEntity } from '../database/entities/scenario.entity';

const CEFR_LABELS = ['', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'] as const;

export interface EvaluationScores {
  fluency: number;        // 1-5  pacing, hesitation, naturalness of phrasing
  accuracy: number;       // 1-5  grammar correctness, tense, articles, agreement
  vocabulary: number;     // 1-5  range, appropriateness, collocation
  interaction: number;    // 1-5  turn-taking, follow-up questions, engagement
  topic_adherence: number;// 1-5  engagement with assigned topic vs avoidance
}

export interface SpecificFeedbackItem {
  turn_index: number;
  user_text: string;
  issue: string;
  correction: string;
  severity: 'minor' | 'moderate' | 'major';
}

export interface EvaluationResult {
  overall_cefr_estimate: string;
  scores: EvaluationScores;
  specific_feedback: SpecificFeedbackItem[];
  strengths: string[];
  suggested_practice: string;
}

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
    this.logger.log(`\n${'─'.repeat(60)}\nSYSTEM PROMPT\n${'─'.repeat(60)}\n${systemPrompt}\n${'─'.repeat(60)}`);
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
      this.logger.warn(
        `AI chat failed (${(e as AiProviderError).kind}): falling back to canned reply`,
      );
      return this.fallbackReply(args.history);
    }
  }

  /**
   * Generates a grammar analysis. Returns null when AI is unavailable so the
   * scoring pipeline can use algorithmic-only scores.
   */
  async scoreGrammar(
    userMessages: string[],
    level: number,
  ): Promise<{
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
        this.logger.warn(
          'AI suggestion returned empty text; using canned suggestion',
        );
        return this.fallbackSuggestion(args.history);
      }
      return text;
    } catch (e) {
      this.logger.warn(
        `AI suggestion failed (${(e as AiProviderError).kind}): using canned suggestion`,
      );
      return this.fallbackSuggestion(args.history);
    }
  }

  /**
   * End-of-session CEFR evaluation. Sends the full transcript to the AI
   * examiner and returns structured scores. Returns null when the AI is
   * unavailable so callers can skip silently.
   */
  async evaluateSession(args: {
    messages: Array<{ role: string; content: string }>;
    cefrLevel: number;
    scenarioTopic: string | null;
  }): Promise<EvaluationResult | null> {
    const cefrLabel = CEFR_LABELS[args.cefrLevel] ?? 'B1';

    // Build transcript in [USER turn N] / [TUTOR] format
    let userTurnIdx = 0;
    const lines: string[] = [];
    for (const msg of args.messages) {
      if (msg.role === 'user') {
        lines.push(`[USER turn ${userTurnIdx}] ${msg.content}`);
        userTurnIdx++;
      } else {
        lines.push(`[TUTOR] ${msg.content}`);
      }
    }
    if (userTurnIdx < 2) return null; // too short to evaluate meaningfully

    const transcript = lines.join('\n');
    const topicLine = args.scenarioTopic ? `\nTopic: ${args.scenarioTopic}` : '';

    const systemPrompt = `You are an English examiner assessing the CEFR level of a learner from a short conversation transcript.
Given the transcript and a target CEFR level, produce a <think>...</think> block in which you reason carefully about the learner's USER turns (citing turn indices and short quotations), followed immediately by a single JSON object.

JSON schema (no markdown fences, no prose outside the JSON after </think>):
{
  "overall_cefr_estimate": "A1|A2|B1|B2|C1|C2",
  "scores": {
    "fluency": <1-5>,
    "accuracy": <1-5>,
    "vocabulary": <1-5>,
    "interaction": <1-5>,
    "topic_adherence": <1-5>
  },
  "specific_feedback": [
    {"turn_index": <int>, "user_text": "...", "issue": "...", "correction": "...", "severity": "minor|moderate|major"}
  ],
  "strengths": ["...", "..."],
  "suggested_practice": "..."
}

Score definitions:
- fluency: pacing, hesitation, naturalness of phrasing
- accuracy: grammar correctness, tense, articles, agreement
- vocabulary: range, appropriateness, collocation
- interaction: turn-taking, follow-up questions, engagement relative to learner role
- topic_adherence: genuine engagement with the assigned topic vs steering to easier ground (avoidance scores LOW)`;

    const userPrompt = `Target CEFR: ${cefrLabel}${topicLine}

Transcript:
${transcript}

Score the LEARNER's USER turns.`;

    try {
      const res = await this.ai.chat({
        systemPrompt,
        messages: [{ role: 'user', content: userPrompt }],
        maxTokens: 1500,
        temperature: 0.3,
        enablePromptCache: false,
      });

      const text = res.content;
      // Strip <think>...</think> chain-of-thought, then extract the JSON object
      const afterThink = text.includes('</think>')
        ? text.slice(text.indexOf('</think>') + 8).trim()
        : text.trim();
      const jsonStart = afterThink.indexOf('{');
      const jsonEnd = afterThink.lastIndexOf('}');
      if (jsonStart === -1 || jsonEnd === -1) {
        this.logger.warn('evaluateSession: no JSON found in AI response');
        return null;
      }
      return JSON.parse(afterThink.slice(jsonStart, jsonEnd + 1)) as EvaluationResult;
    } catch (e) {
      this.logger.warn(`evaluateSession failed: ${(e as Error).message}`);
      return null;
    }
  }

  private fallbackSuggestion(history: ChatMessage[]): string {
    // If the assistant just asked a question, suggest a friendly opener.
    // Otherwise nudge the user to ask the tutor a question.
    const lastAssistant = [...history]
      .reverse()
      .find((m) => m.role === 'assistant');
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
