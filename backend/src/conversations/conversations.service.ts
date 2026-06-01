import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, FindOptionsWhere, Repository } from 'typeorm';
import {
  ConversationSessionEntity,
  ConversationMessageEntity,
  SessionScoreEntity,
  SessionStatus,
} from '../database/entities/conversation.entity';
import { GuardViolationEntity } from '../database/entities/guard-violation.entity';
import { ScenarioEntity } from '../database/entities/scenario.entity';
import { PersonaEntity } from '../database/entities/persona.entity';
import { UserEntity } from '../database/entities/user.entity';
import { ConversationOrchestrator } from '../ai/conversation.orchestrator';
import type {
  StartSessionDto,
  SendMessageDto,
  EndSessionDto,
  SessionDto,
  MessageDto,
  SendMessageResponseDto,
} from './dto/conversation.dto';

@Injectable()
export class ConversationsService {
  constructor(
    @InjectRepository(ConversationSessionEntity)
    private readonly sessions: Repository<ConversationSessionEntity>,
    @InjectRepository(ConversationMessageEntity)
    private readonly messages: Repository<ConversationMessageEntity>,
    @InjectRepository(ScenarioEntity)
    private readonly scenarios: Repository<ScenarioEntity>,
    @InjectRepository(PersonaEntity)
    private readonly personas: Repository<PersonaEntity>,
    @InjectRepository(UserEntity)
    private readonly users: Repository<UserEntity>,
    private readonly orchestrator: ConversationOrchestrator,
    private readonly dataSource: DataSource,
  ) {}

  async start(userId: string, dto: StartSessionDto): Promise<SessionDto> {
    const persona = await this.personas.findOne({
      where: { id: dto.personaId },
    });
    if (!persona) throw new NotFoundException({ i18nKey: 'persona.not_found' });

    let scenario: ScenarioEntity | null = null;
    if (dto.scenarioId) {
      scenario = await this.scenarios.findOne({
        where: { id: dto.scenarioId },
      });
      if (!scenario || scenario.status !== 'published') {
        throw new NotFoundException({ i18nKey: 'scenario.not_found' });
      }
    }

    // Resolve chosen CEFR level — use the value sent by the client, or fall
    // back to the user's own current level when omitted.
    let cefrLevel = dto.cefrLevel;
    if (!cefrLevel) {
      const user = await this.users.findOne({ where: { id: userId } });
      cefrLevel = user?.info?.current_level ?? 1;
    }

    const session = await this.sessions.save(
      this.sessions.create({
        user_id: userId,
        scenario_id: scenario?.id ?? null,
        persona_id: persona.id,
        mode: dto.mode,
        status: 'active',
        cefr_level: cefrLevel,
      }),
    );

    // Tutor's opening message — placeholder until §09 AI provider is wired
    const greetingEn = scenario
      ? `Hi! Let's practice "${(scenario.title as { en: string }).en}". ${(scenario.scene_description as { en: string }).en}`
      : `Hi! I'm ${persona.name}. What would you like to chat about today?`;
    await this.messages.save(
      this.messages.create({
        session_id: session.id,
        role: 'assistant',
        content: greetingEn,
        sequence: 0,
      }),
    );

    return this.toSessionDto(session);
  }

  async listForUser(
    userId: string,
    limit = 50,
    scenarioId?: string,
    status?: string,
  ): Promise<SessionDto[]> {
    const where: FindOptionsWhere<ConversationSessionEntity> = {
      user_id: userId,
    };
    if (scenarioId) where.scenario_id = scenarioId;
    if (status) where.status = status as SessionStatus;
    const rows = await this.sessions.find({
      where,
      order: { started_at: 'DESC' },
      take: limit,
    });
    return rows.map((s) => this.toSessionDto(s));
  }

  async getSession(
    userId: string,
    id: string,
  ): Promise<SessionDto & { messages: MessageDto[] }> {
    const session = await this.sessions.findOne({ where: { id } });
    if (!session) throw new NotFoundException({ i18nKey: 'session.not_found' });
    if (session.user_id !== userId) throw new ForbiddenException();

    const msgs = await this.messages.find({
      where: { session_id: id },
      order: { sequence: 'ASC' },
    });
    return {
      ...this.toSessionDto(session),
      messages: msgs.map((m) => this.toMessageDto(m)),
    };
  }

  async sendMessage(
    userId: string,
    sessionId: string,
    dto: SendMessageDto,
  ): Promise<SendMessageResponseDto> {
    const session = await this.sessions.findOne({ where: { id: sessionId } });
    if (!session) throw new NotFoundException({ i18nKey: 'session.not_found' });
    if (session.user_id !== userId) throw new ForbiddenException();
    if (session.status !== 'active') {
      throw new ForbiddenException({ i18nKey: 'session.not_active' });
    }

    // Load full history (ascending) so we can: (a) determine next sequence,
    // (b) hand the prior turns to the AI orchestrator as chat history.
    const priorMessages = await this.messages.find({
      where: { session_id: sessionId },
      order: { sequence: 'ASC' },
    });
    const nextSeq =
      priorMessages.length > 0
        ? priorMessages[priorMessages.length - 1].sequence + 1
        : 0;

    const userMsg = await this.messages.save(
      this.messages.create({
        session_id: sessionId,
        role: 'user',
        content: dto.content,
        sequence: nextSeq,
        audio_url: dto.audioUrl ?? null,
      }),
    );

    const persona = await this.personas.findOne({
      where: { id: session.persona_id },
    });
    const scenario = session.scenario_id
      ? await this.scenarios.findOne({ where: { id: session.scenario_id } })
      : null;
    const user = await this.users.findOne({ where: { id: userId } });

    let reply: string;
    if (persona && user) {
      const history = [
        ...priorMessages.map((m) => ({
          role: m.role,
          content: m.content,
        })),
        { role: 'user' as const, content: dto.content },
      ];
      reply = await this.orchestrator.generateTutorReply({
        persona,
        scenario,
        userLevel: session.cefr_level ?? user.info.current_level,
        userNativeLanguage: user.info.native_language,
        history,
      });
    } else {
      // Orchestrator can't run without persona+user. Use the canned fallback.
      reply = this.generatePlaceholderReply(dto.content);
    }
    const aiMsg = await this.messages.save(
      this.messages.create({
        session_id: sessionId,
        role: 'assistant',
        content: reply,
        sequence: nextSeq + 1,
      }),
    );

    // Update session counters
    session.turn_count += 1;
    session.word_count += this.countWords(dto.content);
    await this.sessions.save(session);

    return {
      userMessage: this.toMessageDto(userMsg),
      assistantMessage: this.toMessageDto(aiMsg),
      turnCount: session.turn_count,
    };
  }

  /**
   * Tutor-mode idle prompt. Looks at the current session history and asks
   * the orchestrator for a short line the user could say next. The mobile
   * UI shows this as a suggestion chip after ~20s of silence.
   */
  async suggestNextLine(
    userId: string,
    sessionId: string,
  ): Promise<{ suggestion: string }> {
    const session = await this.sessions.findOne({ where: { id: sessionId } });
    if (!session) throw new NotFoundException({ i18nKey: 'session.not_found' });
    if (session.user_id !== userId) throw new ForbiddenException();
    if (session.status !== 'active') {
      throw new ForbiddenException({ i18nKey: 'session.not_active' });
    }

    const persona = await this.personas.findOne({
      where: { id: session.persona_id },
    });
    if (!persona) throw new NotFoundException({ i18nKey: 'persona.not_found' });

    const scenario = session.scenario_id
      ? await this.scenarios.findOne({ where: { id: session.scenario_id } })
      : null;
    const user = await this.users.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException({ i18nKey: 'user.not_found' });

    const history = await this.messages.find({
      where: { session_id: sessionId },
      order: { sequence: 'ASC' },
    });

    const suggestion = await this.orchestrator.suggestNextLine({
      persona,
      scenario,
      userLevel: session.cefr_level ?? user.info.current_level,
      userNativeLanguage: user.info.native_language,
      history: history.map((m) => ({
        role: m.role,
        content: m.content,
      })),
    });
    return { suggestion };
  }

  /**
   * Hard-deletes a session along with its messages and computed scores.
   *
   * Guard-violation rows are KEPT — they're a moderation / compliance
   * artifact that shouldn't disappear when a user erases their history.
   * The `session_id` column on `vl_guard_violations` is nullable for
   * exactly this case, so we NULL it out instead of cascading.
   *
   * Owner-only. We don't write to the admin audit log because this is a
   * user-initiated action on user-owned data (and the admin log is keyed
   * on an admin actor). HTTP-level Nest logs capture the call.
   */
  async deleteSession(
    userId: string,
    sessionId: string,
  ): Promise<{ ok: true }> {
    const session = await this.sessions.findOne({ where: { id: sessionId } });
    if (!session) throw new NotFoundException({ i18nKey: 'session.not_found' });
    if (session.user_id !== userId) throw new ForbiddenException();

    await this.dataSource.transaction(async (em) => {
      await em
        .getRepository(GuardViolationEntity)
        .update({ session_id: sessionId }, { session_id: null });
      await em
        .getRepository(ConversationMessageEntity)
        .delete({ session_id: sessionId });
      await em
        .getRepository(SessionScoreEntity)
        .delete({ session_id: sessionId });
      await em
        .getRepository(ConversationSessionEntity)
        .delete({ id: sessionId });
    });
    return { ok: true };
  }

  async endSession(
    userId: string,
    sessionId: string,
    dto: EndSessionDto,
  ): Promise<SessionDto> {
    const session = await this.sessions.findOne({ where: { id: sessionId } });
    if (!session) throw new NotFoundException({ i18nKey: 'session.not_found' });
    if (session.user_id !== userId) throw new ForbiddenException();
    if (session.status !== 'active') return this.toSessionDto(session);

    session.status = dto.status ?? 'completed';
    session.ended_at = new Date();
    session.duration_seconds = Math.floor(
      (session.ended_at.getTime() - session.started_at.getTime()) / 1000,
    );

    // Simple XP rule: 1 XP per word spoken, capped at scenario reward when known
    let xp = Math.min(session.word_count, 200);
    if (session.scenario_id) {
      const scenario = await this.scenarios.findOne({
        where: { id: session.scenario_id },
      });
      if (scenario) xp = Math.min(xp, scenario.xp_reward);
    }
    session.xp_earned = xp;
    await this.sessions.save(session);

    return this.toSessionDto(session);
  }

  // ─── Helpers ────────────────────────────────────────────
  private generatePlaceholderReply(userContent: string): string {
    // Placeholder until §09 AiProvider integration lands. Echoes a friendly
    // reply so the conversation UI is functional end-to-end.
    const lower = userContent.toLowerCase().trim();
    if (lower.length < 8) {
      return 'Could you tell me a bit more? I want to hear what you have to say.';
    }
    if (lower.endsWith('?')) {
      return "That's a great question! Let me think… What do you think the answer might be?";
    }
    return 'Nice! I understood that clearly. Can you tell me more about your experience with this?';
  }

  private countWords(text: string): number {
    return text.trim().split(/\s+/).filter(Boolean).length;
  }

  private toSessionDto(s: ConversationSessionEntity): SessionDto {
    return {
      id: s.id,
      scenarioId: s.scenario_id,
      personaId: s.persona_id,
      mode: s.mode,
      status: s.status,
      startedAt: s.started_at,
      endedAt: s.ended_at,
      turnCount: s.turn_count,
      wordCount: s.word_count,
      xpEarned: s.xp_earned,
      cefrLevel: s.cefr_level,
    };
  }

  private toMessageDto(m: ConversationMessageEntity): MessageDto {
    return {
      id: m.id,
      role: m.role,
      content: m.content,
      sequence: m.sequence,
      createdAt: m.created_at,
    };
  }
}
