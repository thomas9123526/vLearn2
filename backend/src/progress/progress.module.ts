import { Module, Injectable, Controller, Get, UseGuards } from '@nestjs/common';
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
