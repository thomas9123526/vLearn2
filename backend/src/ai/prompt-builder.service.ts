import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
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

// ---------------------------------------------------------------------------
// Locale table — mirrors ConversationModel config/locale.yaml
// ---------------------------------------------------------------------------

interface LocaleData {
  country: string;
  countryAdj: string;
  learnerDesc: string;
  avoidCulturesPhrase: string;
  avoidedTopicsSentence: string;
}

const LOCALE_TABLE: Record<string, LocaleData> = {
  china: {
    country: 'China',
    countryAdj: 'Chinese',
    learnerDesc: 'adult learners of English',
    avoidCulturesPhrase: 'American and European',
    avoidedTopicsSentence:
      'Stay clear of politics, religion, alcohol dating, partisan history, violence harm, distress self harm, yankee culture, western culture, and law and national economy.',
  },
  japan: {
    country: 'Japan',
    countryAdj: 'Japanese',
    learnerDesc: 'adult learners of English',
    avoidCulturesPhrase: 'American, European, Chinese, or Singaporean',
    avoidedTopicsSentence:
      'Stay clear of politics, religion, alcohol dating, partisan history, violence harm, distress self harm, yankee culture, western culture, and law and national economy.',
  },
  italy: {
    country: 'Italy',
    countryAdj: 'Italian',
    learnerDesc: 'adult learners of English',
    avoidCulturesPhrase: 'American or British',
    avoidedTopicsSentence:
      'Stay clear of politics, religion, alcohol dating, partisan history, violence harm, distress self harm, yankee culture, western culture, and law and national economy.',
  },
};

// Fallback used when locale is unknown
const GENERIC_LOCALE: LocaleData = {
  country: '',
  countryAdj: '',
  learnerDesc: 'adult learners of English',
  avoidCulturesPhrase: '',
  avoidedTopicsSentence:
    'Stay clear of politics, religion, violence, and other sensitive topics.',
};

// Maps user native-language code/name (lowercase) → locale key
const LANG_TO_LOCALE: Record<string, string> = {
  zh: 'china', 'zh-cn': 'china', 'zh-tw': 'china',
  chinese: 'china', mandarin: 'china', cantonese: 'china',
  ja: 'japan', japanese: 'japan',
  it: 'italy', italian: 'italy',
};

// DB config keys we read for admin-panel locale overrides
const LOCALE_CONFIG_KEYS = [
  'prompt.locale.country',
  'prompt.locale.country_adjective',
  'prompt.locale.learner_audience',
  'prompt.locale.avoid_cultures',
  'prompt.avoided_topics',
] as const;

// ---------------------------------------------------------------------------
// Deployment guidelines — verbatim from ConversationModel prompts.py
// Placeholders: {modelRoleName}, {cefrLevel}, {country}, {avoidCultures}
// ---------------------------------------------------------------------------
const DEPLOYMENT_GUIDELINES = `- Sound like a real person, not a textbook. Stay in character as {modelRoleName} -- speak the way they would speak in this setting.
- Respond ONLY in English, even if the learner switches to another language. Do not code-switch or quote long non-English passages. If the learner addresses you in their L1, respond in English while staying in character.
- Keep vocabulary, grammar, and sentence length at CEFR {cefrLevel} unless the learner reaches higher and sustains it.
- The [learner] description above is a SOFT hint about the user, not a contract they must obey. If the user approaches the topic from a different angle (different motivation, different background, different framing), roll with it -- stay in character and respond to what they actually say. The FIXED parts are your own [role] and the [topic].
- If the user tries to swap roles (asks you to take their role, or starts behaving as if they are {modelRoleName}), gently keep your own [role] in one in-character sentence and continue the conversation on topic. Do not lecture about who plays whom.
- Subtopics above are starting points, not a checklist. Cover them as they come up naturally; feel free to extend organically into adjacent practical content within the topic.
- Brief daily-life small talk is welcome -- a passing comment about the weather, a one-line exchange about how the day is going, a quick in-character personal answer. Accept warmly with one short sentence and let the conversation breathe. Do NOT redirect for these.
- Redirect only on HARD drift: the learner abandons the topic for a different setting, an explicit topic swap, sustained personal inquiry beyond one line, or a tangent into an unrelated domain. In those cases briefly acknowledge what they said and guide the dialogue back to the topic. One or two sentences is enough; do not lecture about staying on topic.
- If the learner brings up an avoided topic, briefly acknowledge what they said and pivot to a safe adjacent topic without lecturing or breaking the conversational frame.{localeGrounding}
- When the learner makes a small mistake: at A1-A2 gently recast the correct form inside your reply; at B1 and above you may briefly explain or ask a clarifying question if it would help.
- Ask follow-up questions, share small reactions.
- Do not use bullet lists, headings, or numbered steps in your replies.`;

/**
 * Builds vendor-agnostic prompts matching the ConversationModel's
 * _SCENARIO_DEPLOYMENT_SYSTEM_PROMPT_TEMPLATE ([role]/[learner]/[topic]/
 * [subtopics]/[cefr_level]/[locale]/[avoided_topics]/[guidelines]).
 *
 * Priority order for the tutor system prompt:
 *   1. scenario.custom_prompt  — per-scenario full override (highest)
 *   2. vl_prompt_templates row — global full-template override from DB
 *   3. Section-by-section builder — ConversationModel format
 *
 * Placeholder syntax in custom prompts / DB templates: `{{group.field}}`
 */
@Injectable()
export class PromptBuilderService {
  private readonly logger = new Logger('PromptBuilderService');

  /** When true, appends /no_think at the end of conversation system prompts. */
  readonly disableThinking: boolean;

  constructor(
    config: ConfigService,
    @InjectRepository(PromptTemplateEntity)
    private readonly templates: Repository<PromptTemplateEntity>,
    @InjectRepository(AppConfigEntity)
    private readonly configRepo: Repository<AppConfigEntity>,
  ) {
    this.disableThinking = config.get<string>('AI_DISABLE_THINKING') === 'true';
  }

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
      return {
        prompt: this.render(scenario.custom_prompt, ctx),
        source: 'custom_prompt (per-scenario override)',
      };
    }

    // Priority 2: global full-template override from DB
    const tpl = await this.loadTemplate('tutor_system');
    if (tpl) {
      return {
        prompt: this.render(tpl, ctx),
        source: 'DB template: tutor_system (vl_prompt_templates)',
      };
    }

    // Priority 3: ConversationModel section builder
    return {
      prompt: await this.buildCchPrompt(ctx),
      source: 'section-builder ([role]/[learner]/[topic]/…)',
    };
  }

  /**
   * Loads the evaluation system prompt from DB (evaluation_system template) or
   * falls back to the built-in default. Always appends /think so the model
   * produces a <think>…</think> reasoning block before the JSON output.
   * The per-call transcript and target CEFR label are injected as the user
   * message by the orchestrator — they do not go into this system prompt.
   */
  async buildEvaluationSystemPrompt(): Promise<string> {
    const tpl = await this.loadTemplate('evaluation_system');
    const base = tpl ?? DEFAULT_EVALUATION_SYSTEM;
    return `${base}\n/think`;
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

  /**
   * Builds the system prompt in ConversationModel's structured section format,
   * matching the _SCENARIO_DEPLOYMENT_SYSTEM_PROMPT_TEMPLATE used at training
   * time so the model stays inside its trained distribution.
   */
  private async buildCchPrompt(ctx: Record<string, string>): Promise<string> {
    // Load DB locale overrides (admin panel can override per-instance)
    let cfg: Record<string, unknown> = {};
    try {
      const rows = await this.configRepo.find({
        where: { key: In([...LOCALE_CONFIG_KEYS]) },
      });
      cfg = Object.fromEntries(rows.map((r) => [r.key, r.value]));
    } catch (e) {
      this.logger.warn(
        `Could not load locale config, using built-in defaults: ${(e as Error).message}`,
      );
    }
    const dbStr = (key: string, def = ''): string => {
      const v = cfg[key];
      return typeof v === 'string' && v.trim() ? v.trim() : def;
    };

    // Resolve locale: scenario.locale > user native language > china default
    const scenarioLocale = ctx['scenario.locale'];
    const nativeLang = ctx['user.native_language']?.toLowerCase() ?? '';
    const localeName =
      scenarioLocale ||
      LANG_TO_LOCALE[nativeLang] ||
      'china';
    const loc = LOCALE_TABLE[localeName] ?? GENERIC_LOCALE;

    const country        = dbStr('prompt.locale.country',           loc.country);
    const countryAdj     = dbStr('prompt.locale.country_adjective', loc.countryAdj);
    const audience       = dbStr('prompt.locale.learner_audience',  loc.learnerDesc);
    const avoidCultures  = dbStr('prompt.locale.avoid_cultures',    loc.avoidCulturesPhrase);
    const avoidedTopics  = dbStr('prompt.avoided_topics',           loc.avoidedTopicsSentence);

    // [role] — model character name + description
    const modelRoleName = ctx['persona.name'];
    const tutorRole = ctx['scenario.tutor_role'];
    const hasTutorRole = tutorRole && tutorRole !== '—';
    const specialties = ctx['persona.specialties']
      ? `, specializing in ${ctx['persona.specialties']}`
      : '';
    const modelRoleDesc = hasTutorRole
      ? trimDesc(tutorRole)
      : `a ${ctx['persona.style']} English conversation tutor${specialties}`;

    // [learner] — user's role in the scenario
    const learnerRole = ctx['scenario.user_role'];
    const hasLearnerRole = learnerRole && learnerRole !== '—';
    const userRoleDesc = hasLearnerRole
      ? trimDesc(learnerRole)
      : 'an adult English learner having an everyday conversation';

    // [topic]
    const topic = ctx['scenario.title'] || 'open-ended everyday conversation';

    // [subtopics]
    const objectives = ctx['scenario.objectives'];
    const subtopicsBlock = objectives?.trim()
      ? objectives
          .split(', ')
          .filter(Boolean)
          .map((o) => `- ${o.trim()}`)
          .join('\n')
      : '- (no specific subtopics; follow the topic naturally)';

    // [cefr_level]
    const cefrLevel = ctx['user.level_label'];

    // [guidelines] — locale grounding bullet is only included when we have a country
    const localeGrounding = country
      ? `\n- Ground cultural items in ${country}. Do not default to ${avoidCultures} names, places, foods, or brands.`
      : '';

    const guidelines = DEPLOYMENT_GUIDELINES
      .replace(/{modelRoleName}/g, modelRoleName)
      .replace(/{cefrLevel}/g, cefrLevel)
      .replace(/{country}/g, country)
      .replace(/{avoidCultures}/g, avoidCultures)
      .replace(/{localeGrounding}/g, localeGrounding);

    const sections = [
      `[role]\nYou are ${modelRoleName}: ${modelRoleDesc}.`,
      `[learner]\n${userRoleDesc}.`,
      `[topic]\n${topic}`,
      [
        '[subtopics]',
        'The conversation may naturally start from any of these and can move freely',
        'between them or extend into adjacent practical content the learner might',
        'want to practice:',
        subtopicsBlock,
      ].join('\n'),
      `[cefr_level]\n${cefrLevel}`,
      ...(country
        ? [
            [
              '[locale]',
              `country: ${country}`,
              `country_adjective: ${countryAdj}`,
              `learner_audience: ${audience}`,
              `avoid_default_cultures: ${avoidCultures}`,
            ].join('\n'),
          ]
        : []),
      `[avoided_topics]\n${avoidedTopics}`,
      `[guidelines]\n${guidelines}`,
    ].join('\n\n');

    return this.disableThinking ? `${sections}\n/no_think` : sections;
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
      'scenario.locale': sc?.locale ?? '',
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
    // Pass 2: [cefr_level] inline variable in custom/DB prompts
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

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function levelLabelFor(level: number): string {
  const labels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  return level >= 1 && level <= 6 ? labels[level - 1] : 'A1';
}

/** Strip trailing period so the template's own period doesn't double up. */
function trimDesc(s: string): string {
  return s.trim().replace(/\.\s*$/, '').trimEnd();
}

const DEFAULT_EVALUATION_SYSTEM = `You are an English examiner assessing the CEFR level of a learner from a short conversation transcript.
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
- topic_adherence: genuine engagement with the assigned topic vs steering to easier ground (avoidance scores LOW)

Output no prose before <think>, no prose between </think> and the opening "{", and no markdown code fences.`;

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
