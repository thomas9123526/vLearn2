import {
  Module,
  Injectable,
  Controller,
  Get,
  Post,
  Body,
  UseGuards,
  BadRequestException,
} from '@nestjs/common';
import { TypeOrmModule, InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { JwtPayload } from '../auth/strategies/jwt.strategy';
import {
  UserProgressEntity,
  SkillSnapshotEntity,
  UserScenarioCompletionEntity,
} from '../database/entities/progress.entity';

@Injectable()
class ProgressService {
  constructor(
    @InjectRepository(UserProgressEntity)
    private readonly progress: Repository<UserProgressEntity>,
    @InjectRepository(SkillSnapshotEntity)
    private readonly snapshots: Repository<SkillSnapshotEntity>,
    @InjectRepository(UserScenarioCompletionEntity)
    private readonly completions: Repository<UserScenarioCompletionEntity>,
  ) {}

  async getProgress(userId: string) {
    let row = await this.progress.findOne({ where: { user_id: userId } });
    if (!row) {
      row = await this.progress.save(this.progress.create({ user_id: userId }));
    }
    const latestSnapshot = await this.snapshots.findOne({
      where: { user_id: userId },
      order: { snapshot_date: 'DESC' },
    });
    return { ...row, latestSnapshot };
  }

  listSnapshots(userId: string, limit = 12) {
    return this.snapshots.find({
      where: { user_id: userId },
      order: { snapshot_date: 'DESC' },
      take: limit,
    });
  }

  listCompletions(userId: string) {
    return this.completions.find({
      where: { user_id: userId },
      order: { last_completed_at: 'DESC' },
    });
  }

  /// Upsert a skill snapshot for today. Apps submit one after each session,
  /// using their own heuristics (or AI-derived scores once we have that on
  /// the backend); we just store them and let the UI chart over time.
  async upsertSnapshot(
    userId: string,
    body: {
      pronunciation?: number;
      fluency?: number;
      vocabulary?: number;
      grammar?: number;
      listening?: number;
      confidence?: number;
    },
  ): Promise<SkillSnapshotEntity> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const existing = await this.snapshots.findOne({
      where: { user_id: userId, snapshot_date: today },
    });
    const merged = existing ?? this.snapshots.create({ user_id: userId, snapshot_date: today });
    for (const key of [
      'pronunciation',
      'fluency',
      'vocabulary',
      'grammar',
      'listening',
      'confidence',
    ] as const) {
      const raw = body[key];
      if (raw == null) continue;
      if (typeof raw !== 'number' || raw < 0 || raw > 100) {
        throw new BadRequestException({ i18nKey: 'progress.score_out_of_range', key });
      }
      // Running average — keep newer evidence weighted higher.
      if (existing && existing[key] != null) {
        const prev = existing[key]!;
        (merged as Record<typeof key, number>)[key] = Math.round(prev * 0.7 + raw * 0.3);
      } else {
        (merged as Record<typeof key, number>)[key] = Math.round(raw);
      }
    }
    merged.sessions_in_window = (existing?.sessions_in_window ?? 0) + 1;
    return this.snapshots.save(merged);
  }
}

@ApiTags('Progress')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('progress')
class ProgressController {
  constructor(private readonly svc: ProgressService) {}

  @Get()
  @ApiOperation({ summary: 'Get my aggregated progress + latest skill snapshot' })
  get(@CurrentUser() user: JwtPayload) {
    return this.svc.getProgress(user.sub);
  }

  @Get('snapshots')
  @ApiOperation({ summary: 'List my weekly skill snapshots (latest first)' })
  snapshots(@CurrentUser() user: JwtPayload) {
    return this.svc.listSnapshots(user.sub);
  }

  @Get('completions')
  @ApiOperation({ summary: 'List my scenario completions' })
  completions(@CurrentUser() user: JwtPayload) {
    return this.svc.listCompletions(user.sub);
  }

  @Post('snapshots')
  @ApiOperation({ summary: 'Submit today\'s skill snapshot (app-side heuristics)' })
  postSnapshot(
    @CurrentUser() user: JwtPayload,
    @Body()
    body: {
      pronunciation?: number;
      fluency?: number;
      vocabulary?: number;
      grammar?: number;
      listening?: number;
      confidence?: number;
    },
  ) {
    return this.svc.upsertSnapshot(user.sub, body);
  }
}

@Module({
  imports: [
    TypeOrmModule.forFeature([
      UserProgressEntity,
      SkillSnapshotEntity,
      UserScenarioCompletionEntity,
    ]),
  ],
  providers: [ProgressService],
  controllers: [ProgressController],
  exports: [ProgressService],
})
export class ProgressModule {}
