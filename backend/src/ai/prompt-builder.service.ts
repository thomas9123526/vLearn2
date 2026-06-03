import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import type { PersonaEntity } from '../database/entities/persona.entity';
import type {
  ScenarioEntity,
  I18nText,
} from '../database/entities/scenario.entity';
import {
  PromptKind,
  PromptTemplateEntity,
} from '../database/entities/prompt-template.entity';
import { AppConfigEntity } from '../database/entities/app-config.entity';
import type { PromptVariable } from './ai-call-logger';

/**
 * Builds vendor-agnostic prompts in the cch_prompt section format
 * ([role] / [learner] / [topic] / [subtopics] / [cefr_level] / [locale] /
 * [avoided_topics] / [guidelines]).
 *
 * Priority order for the tutor system prompt:
 *   1. scenario.custom_prompt  — per-scenario full override (highest)
 *   2. vl_prompt_templates row — global full-template override from DB
 *   3. Section-by-section builder — toggleable via prompt.section.* flags
 *
 * Placeholder syntax: `{{group.field}}` — resolved against a flat key-value
 * map. Unknown placeholders collapse to '' so template internals never leak.
 */
@Injectable()
export class PromptBuilderService {
  private readonly logger = new Logger('PromptBuilderService');

  private static readonly SECTION_KEYS = [
    'prompt.section.role',
    'prompt.section.learner',
    'prompt.section.topic',
    'prompt.section.subtopics',
    'prompt.section.cefr_level',
    'prompt.section.locale',
    'prompt.section.avoided_topics',
    'prompt.section.guidelines',
    'prompt.locale.country',
    'prompt.locale.country_adjective',
    'prompt.locale.learner_audience',
    'prompt.locale.avoid_cultures',
    'prompt.avoided_topics',
  ] as const;

  constructor(
    @InjectRepository(PromptTemplateEntity)
    private readonly templates: Repository<PromptTemplateEntity>,
    @InjectRepository(AppConfigEntity)
    private readonly configRepo: Repository<AppConfigEntity>,
  ) {}

  /**
   * Returns the flat context map used to render placeholders, annotated with
   * the origin of each variable. Used by the orchestrator for debug logging.
   */
  getTutorContextWithSources(
    persona: PersonaEntity,
    scenario: ScenarioEntity | null,
    userLevel: number,
    userNativeLanguage: string,
  ): Record<string, PromptVariable> {
    const ctx = this.tutorContext(persona, scenario, userLevel, userNativeLanguage);
    const annotated: Record<string, PromptVariable> = {};
    for (const [k, v] of Object.entries(ctx)) {
      let from: string;
      if (k.startsWith('persona.'))          from = 'persona DB row (vl_personas)';
      else if (k.startsWith('scenario.'))    from = scenario ? 'scenario DB row (vl_scenarios)' : 'default (no scenario)';
      else if (k === 'user.level' || k === 'user.level_label')
                                             from = 'user_progress.current_level';
      else if (k === 'user.native_language') from = 'user_info.native_language';
      else                                   from = 'computed';
      annotated[k] = { value: v || '(empty)', from };
    }
    return annotated;
  }

  async buildSystemPrompt(
    persona: PersonaEntity,
    scenario: ScenarioEntity | null,
    userLevel: number,
    userNativeLanguage: string,
  ): Promise<{ prompt: string; source: string }> {
    const ctx = this.tutorContext(persona, scenario, userLevel, userNativeLanguage);

    // Priority 1: per-scenario custom prompt
    if (scenario?.custom_prompt?.trim()) {
      return { prompt: this.render(scenario.custom_prompt, ctx), source: 'custom_prompt (per-scenario override)' };
    }

    // Priority 2: global full-template override
    const tpl = await this.loadTemplate('tutor_system');
    if (tpl) {
      return { prompt: this.render(tpl, ctx), source: 'DB template: tutor_system (vl_prompt_templates)' };
    }

    // Priority 3: section-by-section cch_prompt builder
    return { prompt: await this.buildCchPrompt(ctx), source: 'section-builder ([role]/[learner]/[topic]/…)' };
  }

  async buildGrammarPrompt(
    userMessages: string[],
    level: number,
  ): Promise<string> {
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

  // ── Private helpers ──────────────────────────────────────────────────────

  private async buildCchPrompt(ctx: Record<string, string>): Promise<string> {
    let cfg: Record<string, unknown> = {};
    try {
      const rows = await this.configRepo.find({
        where: { key: In([...PromptBuilderService.SECTION_KEYS]) },
      });
      cfg = Object.fromEntries(rows.map((r) => [r.key, r.value]));
    } catch (e) {
      this.logger.warn(
        `Could not load prompt config flags, using defaults: ${(e as Error).message}`,
      );
    }

    const on = (key: string, def = true): boolean => {
      const v = cfg[key];
      return typeof v === 'boolean' ? v : def;
    };
    const str = (key: string, def = ''): string => {
      const v = cfg[key];
      return typeof v === 'string' && v.trim() ? v.trim() : def;
    };

    const sections: string[] = [];

    if (on('prompt.section.role')) {
      const specialties = ctx['persona.specialties']
        ? ` specializing in ${ctx['persona.specialties']}`
        : '';
      const tutorRole = ctx['scenario.tutor_role'] && ctx['scenario.tutor_role'] !== '—'
        ? `\nYour role in this scenario: ${ctx['scenario.tutor_role']}.`
        : '';
      sections.push(
        `[role]\nYou are ${ctx['persona.name']}: a ${ctx['persona.style']} English tutor${specialties}.${tutorRole}`,
      );
    }

    if (on('prompt.section.learner')) {
      const learner = ctx['scenario.user_role'] && ctx['scenario.user_role'] !== '—'
        ? ctx['scenario.user_role']
        : 'a language learner';
      sections.push(`[learner]\n${learner}`);
    }

    if (on('prompt.section.topic')) {
      sections.push(`[topic]\n${ctx['scenario.title']}`);
    }

    if (on('prompt.section.subtopics')) {
      const lines: string[] = [
        'The conversation may naturally start from any of these and can move freely between them or extend into adjacent practical content:',
      ];
      const objectives = ctx['scenario.objectives'];
      if (objectives) {
        objectives.split(', ').filter(Boolean).forEach((o) => lines.push(`- ${o}`));
      }
      const keyPhrases = ctx['scenario.key_phrases'];
      if (keyPhrases) {
        lines.push(`\nKey phrases to encourage: ${keyPhrases}`);
      }
      sections.push(`[subtopics]\n${lines.join('\n')}`);
    }

    if (on('prompt.section.cefr_level')) {
      sections.push(`[cefr_level]\n${ctx['user.level_label']}`);
    }

    if (on('prompt.section.locale')) {
      const localeLines: string[] = [];
      const country = str('prompt.locale.country');
      if (country) localeLines.push(`country: ${country}`);
      const adj = str('prompt.locale.country_adjective');
      if (adj) localeLines.push(`country_adjective: ${adj}`);
      const audience = str('prompt.locale.learner_audience');
      if (audience) localeLines.push(`learner_audience: ${audience}`);
      const avoid = str('prompt.locale.avoid_cultures');
      if (avoid) localeLines.push(`avoid_default_cultures: ${avoid}`);
      if (localeLines.length) {
        sections.push(`[locale]\n${localeLines.join('\n')}`);
      }
    }

    if (on('prompt.section.avoided_topics')) {
      const avoided = str('prompt.avoided_topics', DEFAULT_AVOIDED_TOPICS);
      sections.push(`[avoided_topics]\n${avoided}`);
    }

    if (on('prompt.section.guidelines')) {
      sections.push(`[guidelines]\n${this.render(DEFAULT_GUIDELINES, ctx)}`);
    }

    return sections.join('\n\n');
  }

  private tutorContext(
    persona: PersonaEntity,
    scenario: ScenarioEntity | null,
    userLevel: number,
    userNativeLanguage: string,
  ): Record<string, string> {
    const en = (v: unknown) => (v as I18nText | undefined)?.en ?? '';
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

  private render(template: string, ctx: Record<string, string>): string {
    // Pass 1: {{group.field}} placeholders
    let out = template.replace(
      /\{\{\s*([\w.]+)\s*\}\}/g,
      (_m, key: string) => ctx[key] ?? '',
    );
    // Pass 2: [cefr_level] used as an inline variable in custom prompts and
    // global templates — replace with the actual level label so the selected
    // level from the scenario detail screen reaches the AI model.
    out = out.replace(/\[cefr_level\]/g, ctx['user.level_label'] ?? '');
    return out;
  }

  private async loadTemplate(kind: PromptKind): Promise<string | null> {
    try {
      const row = await this.templates.findOne({ where: { kind, is_active: true } });
      return row?.template ?? null;
    } catch (e) {
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

const DEFAULT_AVOIDED_TOPICS =
  'Stay clear of politics, religion, alcohol, dating, partisan history, violence, harm, and distress.';

const DEFAULT_GUIDELINES = `- Sound like a real person, not a textbook. Stay in character as {{persona.name}} throughout.
- Respond ONLY in English, even if the learner switches to another language. Do not code-switch or quote long non-English passages.
- If the learner addresses you in their native language, respond in English while staying in character.
- Keep vocabulary, grammar, and sentence length at {{user.level_label}} level unless the learner demonstrates a higher level and sustains it.
- The [learner] description is a soft hint, not a contract. If the user approaches from a different angle, roll with it — the fixed parts are your [role] and the [topic].
- If the user tries to swap roles, gently keep your own role in one in-character sentence and continue.
- Brief daily-life small talk is welcome — accept warmly with one short sentence and let the conversation breathe.
- Redirect only when the learner clearly abandons the topic for a different setting or domain. One or two sentences is enough; do not lecture.
- If the learner brings up an avoided topic, briefly acknowledge and pivot to a safe adjacent topic without lecturing.
- When the learner makes a small mistake: at A1–A2 gently recast the correct form inside your reply; at B1 and above you may briefly explain if it helps.
- Ask follow-up questions, share small reactions.
- Do not use bullet lists, headings, or numbered steps in your replies.
- Respond naturally and conversationally (2-4 sentences usually).`;

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
