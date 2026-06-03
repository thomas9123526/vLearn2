import {
  Module,
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  UseGuards,
  Query,
} from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { JwtPayload } from '../auth/strategies/jwt.strategy';
import {
  ConversationSessionEntity,
  ConversationMessageEntity,
  SessionScoreEntity,
} from '../database/entities/conversation.entity';
import { GuardViolationEntity } from '../database/entities/guard-violation.entity';
import { ScenarioEntity } from '../database/entities/scenario.entity';
import { PersonaEntity } from '../database/entities/persona.entity';
import { UserEntity } from '../database/entities/user.entity';
import { AiModule } from '../ai/ai.module';
import { ConversationsService } from './conversations.service';
import {
  StartSessionDto,
  SendMessageDto,
  EndSessionDto,
} from './dto/conversation.dto';

@ApiTags('Conversations')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('conversations')
class ConversationsController {
  constructor(private readonly svc: ConversationsService) {}

  @Post('sessions')
  @ApiOperation({ summary: 'Start a new conversation session' })
  start(@CurrentUser() user: JwtPayload, @Body() dto: StartSessionDto) {
    return this.svc.start(user.sub, dto);
  }

  @Get('sessions')
  @ApiOperation({ summary: 'List my sessions (most recent first)' })
  list(
    @CurrentUser() user: JwtPayload,
    @Query('limit') limit?: string,
    @Query('scenarioId') scenarioId?: string,
    @Query('status') status?: string,
  ) {
    return this.svc.listForUser(
      user.sub,
      limit ? parseInt(limit, 10) : 50,
      scenarioId,
      status,
    );
  }

  @Get('sessions/:id')
  @ApiOperation({ summary: 'Get a session with all its messages' })
  get(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.svc.getSession(user.sub, id);
  }

  @Post('sessions/:id/messages')
  @ApiOperation({ summary: 'Send a user message and get the tutor reply' })
  send(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: SendMessageDto,
  ) {
    return this.svc.sendMessage(user.sub, id, dto);
  }

  @Post('sessions/:id/end')
  @ApiOperation({ summary: 'End the session and compute final XP' })
  end(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: EndSessionDto,
  ) {
    return this.svc.endSession(user.sub, id, dto);
  }

  @Delete('sessions')
  @ApiOperation({ summary: 'Delete ALL sessions for the current user' })
  removeAll(@CurrentUser() user: JwtPayload) {
    return this.svc.deleteAllSessions(user.sub);
  }

  @Delete('sessions/:id')
  @ApiOperation({
    summary:
      'Delete the session and its messages/scores (guard violations are kept, FK nulled)',
  })
  remove(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.svc.deleteSession(user.sub, id);
  }

  @Post('sessions/:id/suggest')
  @ApiOperation({
    summary: 'Get a short suggested user line (used by tutor-mode idle prompt)',
  })
  suggest(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.svc.suggestNextLine(user.sub, id);
  }

  @Get('sessions/:id/score')
  @ApiOperation({
    summary:
      'Get the AI evaluation score for a completed session. Returns 404 while evaluation is still running — poll until 200.',
  })
  score(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.svc.getSessionScore(user.sub, id);
  }
}

@Module({
  imports: [
    TypeOrmModule.forFeature([
      ConversationSessionEntity,
      ConversationMessageEntity,
      SessionScoreEntity,
      GuardViolationEntity,
      ScenarioEntity,
      PersonaEntity,
      UserEntity,
    ]),
    AiModule,
  ],
  providers: [ConversationsService],
  controllers: [ConversationsController],
  exports: [ConversationsService],
})
export class ConversationsModule {}
