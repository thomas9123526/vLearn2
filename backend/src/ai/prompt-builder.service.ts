import { Injectable } from '@nestjs/common';
import type { PersonaEntity } from '../database/entities/persona.entity';
import type { ScenarioEntity, I18nText } from '../database/entities/scenario.entity';

/**
 * Builds vendor-agnostic system prompts. Per todoList/09 §9.7 the output is
 * plain text — no Anthropic-specific markers or OpenAI-specific tokens.
 */
@Injectable()
export class PromptBuilderService {
  buildSystemPrompt(
    persona: PersonaEntity,
    scenario: ScenarioEntity | null,
    userLevel: number,
    userNativeLanguage: string,
  ): string {
    const levelLabels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    const levelLabel =
      userLevel >= 1 && userLevel <= 6 ? levelLabels[userLevel - 1] : 'A1';

    const specialties = (persona.specialties ?? []).join(', ');
    const scenarioBlock = scenario
      ? this.scenarioBlock(scenario)
      : 'Free conversation practice - no specific scenario.';

    return `You are ${persona.name}, an English language tutor with a ${persona.style} teaching style.
Your specialties include: ${specialties}.

CURRENT SCENARIO:
${scenarioBlock}

USER PROFILE:
- English level: ${levelLabel} (${userLevel}/6)
- Native language: ${userNativeLanguage}

INSTRUCTIONS:
1. Stay in character as ${persona.name} throughout.
2. Adjust vocabulary and sentence complexity to level ${userLevel}/6.
3. Respond naturally and conversationally (2-4 sentences usually).
4. Correct grammar errors GENTLY and IMPLICITLY by modeling correct usage in your reply.
5. Celebrate good English with encouragement appropriate to your personality.
6. If objectives exist, naturally guide conversation toward them.
7. Encourage use of the key phrases when appropriate.
8. Do NOT explicitly state you are an AI unless directly asked.
9. Do NOT break character.
10. If the user writes in their native language, gently encourage English with a translation hint.`;
  }

  buildGrammarPrompt(userMessages: string[], level: number): string {
    const messageList = userMessages
      .map((m, i) => `${i + 1}. "${m.replace(/"/g, '\\"')}"`)
      .join('\n');
    return `Analyze the grammar quality of these English messages from a level ${level}/6 English learner.

Messages:
${messageList}

Grammar score guidelines:
- 0-30: Many basic errors (wrong tense, subject-verb, articles)
- 31-60: Some errors, mostly understandable
- 61-80: Few errors, good grammatical control
- 81-100: Very few/no errors, sophisticated usage`;
  }

  buildFeedbackPrompt(summary: {
    scenarioTitle?: string;
    overallScore: number;
    fluencyScore: number;
    vocabularyScore: number;
    grammarScore: number;
    engagementScore: number;
    levelLabel: string;
    strongestSkill: string;
    weakestSkill: string;
  }): string {
    return `Write a 2-3 sentence encouraging feedback paragraph for an English learner.

Session data:
- Scenario: ${summary.scenarioTitle ?? 'Free conversation'}
- Overall score: ${summary.overallScore}/100
- Fluency: ${summary.fluencyScore}/100
- Vocabulary: ${summary.vocabularyScore}/100
- Grammar: ${summary.grammarScore}/100
- Engagement: ${summary.engagementScore}/100
- User level: ${summary.levelLabel}
- Strongest area: ${summary.strongestSkill}
- Area to improve: ${summary.weakestSkill}

Write in a warm, motivating tone. Mention 1 specific thing they did well. Keep it concise — max 60 words.`;
  }

  private scenarioBlock(scenario: ScenarioEntity): string {
    const en = (v: I18nText | unknown) =>
      (v as I18nText | undefined)?.en ?? '';
    const objectives = (scenario.objectives ?? [])
      .map((o) => en(o))
      .filter(Boolean)
      .join(', ');
    const keyPhrases = (scenario.key_phrases ?? [])
      .map((p) => p.phrase)
      .join(', ');
    return `Title: ${en(scenario.title)}
Setting: ${en(scenario.scene_description)}
Your role: ${en(scenario.tutor_role)}
User's role: ${en(scenario.user_role)}
Objectives: ${objectives}
Key phrases to encourage: ${keyPhrases}`;
  }
}
