import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import type { PersonaEntity } from '../database/entities/persona.entity';
import type { ScenarioEntity, I18nText } from '../database/entities/scenario.entity';
import {
  PromptKind,
  PromptTemplateEntity,
} from '../database/entities/prompt-template.entity';

/**
 * Builds vendor-agnostic prompts. Templates are loaded from the
 * `vl_prompt_templates` table so admins can tune them at runtime; if the
 * DB row is missing (fresh install, broken migration) the service falls
 * back to a hard-coded default so the app stays functional.
 *
 * Placeholder syntax: `{{group.field}}` — resolved against a flat
 * key-value map built by [buildContext_*]. Unknown placeholders render
 * as empty strings (not the literal `{{key}}`) to prevent leaking
 * template internals to the user / model.
 */
@Injectable()
export class PromptBuilderService {
  private readonly logger = new Logger('PromptBuilderService');

  constructor(
    @InjectRepository(PromptTemplateEntity)
    private readonly templates: Repository<PromptTemplateEntity>,
  ) {}

  async buildSystemPrompt(
    persona: PersonaEntity,
    scenario: ScenarioEntity | null,
    userLevel: number,
    userNativeLanguage: string,
  ): Promise<string> {
    const ctx = this.tutorContext(persona, scenario, userLevel, userNativeLanguage);
    const tpl = await this.loadTemplate('tutor_system');
    return this.render(tpl ?? DEFAULT_TUTOR_SYSTEM, ctx);
  }

  async buildGrammarPrompt(userMessages: string[], level: number): Promise<string> {
    const ctx: Record<string, string> = {
      'user.level': String(level),
      'user.level_label': levelLabelFor(level),
      'user.messages': userMessages
        .map((m, i) => `${i + 1}. "${m.replace(/"/g, '\\"')}"`)
        .join('\n'),
    };
    const tpl = await this.loadTemplate('grammar');
    return this.render(tpl ?? DEFAULT_GRAMMAR, ctx);
  }

  async buildFeedbackPrompt(summary: {
    scenarioTitle?: string;
    overallScore: number;
    fluencyScore: number;
    vocabularyScore: number;
    grammarScore: number;
    engagementScore: number;
    levelLabel: string;
    strongestSkill: string;
    weakestSkill: string;
  }): Promise<string> {
    const ctx: Record<string, string> = {
      'session.scenario_title': summary.scenarioTitle ?? 'Free conversation',
      'session.overall_score': String(summary.overallScore),
      'session.fluency_score': String(summary.fluencyScore),
      'session.vocabulary_score': String(summary.vocabularyScore),
      'session.grammar_score': String(summary.grammarScore),
      'session.engagement_score': String(summary.engagementScore),
      'session.strongest_skill': summary.strongestSkill,
      'session.weakest_skill': summary.weakestSkill,
      'user.level_label': summary.levelLabel,
    };
    const tpl = await this.loadTemplate('feedback');
    return this.render(tpl ?? DEFAULT_FEEDBACK, ctx);
  }

  /// Build a flat key map of all placeholders supported in the tutor system
  /// prompt. Scenario fields fall back to friendly defaults when null so the
  /// template doesn't need conditional logic.
  private tutorContext(
    persona: PersonaEntity,
    scenario: ScenarioEntity | null,
    userLevel: number,
    userNativeLanguage: string,
  ): Record<string, string> {
    const en = (v: I18nText | unknown) =>
      (v as I18nText | undefined)?.en ?? '';
    const specialties = (persona.specialties ?? []).join(', ');
    const sc = scenario;
    const objectives = sc
      ? (sc.objectives ?? []).map((o) => en(o)).filter(Boolean).join(', ')
      : '';
    const keyPhrases = sc
      ? (sc.key_phrases ?? []).map((p) => p.phrase).join(', ')
      : '';
    return {
      'persona.name': persona.name,
      'persona.style': persona.style,
      'persona.specialties': specialties,
      'persona.gender': persona.gender ?? 'neutral',
      'persona.accent': persona.accent ?? '',
      'scenario.title': sc ? en(sc.title) : 'Free conversation practice',
      'scenario.setting': sc ? en(sc.scene_description) : '—',
      'scenario.tutor_role': sc ? en(sc.tutor_role) : '—',
      'scenario.user_role': sc ? en(sc.user_role) : '—',
      'scenario.objectives': objectives,
      'scenario.key_phrases': keyPhrases,
      'user.level': String(userLevel),
      'user.level_label': levelLabelFor(userLevel),
      'user.native_language': userNativeLanguage,
    };
  }

  /// `{{group.field}}` → ctx['group.field']. Unknown keys collapse to ''.
  /// Whitespace inside the braces is tolerated.
  private render(template: string, ctx: Record<string, string>): string {
    return template.replace(/\{\{\s*([\w.]+)\s*\}\}/g, (_m, key: string) =>
      ctx[key] ?? '',
    );
  }

  private async loadTemplate(kind: PromptKind): Promise<string | null> {
    try {
      const row = await this.templates.findOne({
        where: { kind, is_active: true },
      });
      return row?.template ?? null;
    } catch (e) {
      // Don't let a DB hiccup take down the conversation pipeline.
      this.logger.warn(
        `Could not load prompt template '${kind}', using built-in default: ${(e as Error).message}`,
      );
      return null;
    }
  }
}

function levelLabelFor(level: number): string {
  const labels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  return level >= 1 && level <= 6 ? labels[level - 1] : 'A1';
}

const DEFAULT_TUTOR_SYSTEM = `You are {{persona.name}}, an English language tutor with a {{persona.style}} teaching style.
Your specialties include: {{persona.specialties}}.

CURRENT SCENARIO:
Title: {{scenario.title}}
Setting: {{scenario.setting}}
Your role: {{scenario.tutor_role}}
User's role: {{scenario.user_role}}
Objectives: {{scenario.objectives}}
Key phrases to encourage: {{scenario.key_phrases}}

USER PROFILE:
- English level: {{user.level_label}} ({{user.level}}/6)
- Native language: {{user.native_language}}

INSTRUCTIONS:
1. Stay in character as {{persona.name}} throughout.
2. Adjust vocabulary and sentence complexity to level {{user.level}}/6.
3. Respond naturally and conversationally (2-4 sentences usually).
4. Correct grammar errors GENTLY and IMPLICITLY by modeling correct usage in your reply.
5. Celebrate good English with encouragement appropriate to your personality.
6. If objectives exist, naturally guide conversation toward them.
7. Encourage use of the key phrases when appropriate.
8. Do NOT explicitly state you are an AI unless directly asked.
9. Do NOT break character.
10. If the user writes in their native language, gently encourage English with a translation hint.`;

const DEFAULT_GRAMMAR = `Analyze the grammar quality of these English messages from a level {{user.level}}/6 English learner.

Messages:
{{user.messages}}

Grammar score guidelines:
- 0-30: Many basic errors (wrong tense, subject-verb, articles)
- 31-60: Some errors, mostly understandable
- 61-80: Few errors, good grammatical control
- 81-100: Very few/no errors, sophisticated usage`;

const DEFAULT_FEEDBACK = `Write a 2-3 sentence encouraging feedback paragraph for an English learner.

Session data:
- Scenario: {{session.scenario_title}}
- Overall score: {{session.overall_score}}/100
- Fluency: {{session.fluency_score}}/100
- Vocabulary: {{session.vocabulary_score}}/100
- Grammar: {{session.grammar_score}}/100
- Engagement: {{session.engagement_score}}/100
- User level: {{user.level_label}}
- Strongest area: {{session.strongest_skill}}
- Area to improve: {{session.weakest_skill}}

Write in a warm, motivating tone. Mention 1 specific thing they did well. Keep it concise — max 60 words.`;
