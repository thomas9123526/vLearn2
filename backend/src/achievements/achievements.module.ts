import { Module, Injectable, Controller, Get, UseGuards } from '@nestjs/common';
import { TypeOrmModule, InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { JwtPayload } from '../auth/strategies/jwt.strategy';
import {
  AchievementEntity,
  UserAchievementEntity,
} from '../database/entities/achievement.entity';

@Injectable()
class AchievementsService {
  constructor(
    @InjectRepository(AchievementEntity)
    private readonly catalog: Repository<AchievementEntity>,
    @InjectRepository(UserAchievementEntity)
    private readonly earned: Repository<UserAchievementEntity>,
  ) {}

  listAll() {
    return this.catalog.find({ order: { condition_value: 'ASC' } });
  }

  async listEarnedBy(userId: string) {
    const rows = await this.earned.find({ where: { user_id: userId } });
    if (rows.length === 0) return [];
    const ids = rows.map((r) => r.achievement_id);
    const defs = await this.catalog.find({ where: ids.map((id) => ({ id })) });
    return rows.map((r) => ({
      ...defs.find((d) => d.id === r.achievement_id),
      earnedAt: r.earned_at,
    }));
  }
}

@ApiTags('Achievements')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('achievements')
class AchievementsController {
  constructor(private readonly svc: AchievementsService) {}

  @Get()
  @ApiOperation({ summary: 'List all achievements (catalog)' })
  list() {
    return this.svc.listAll();
  }

  @Get('mine')
  @ApiOperation({ summary: 'List achievements I have earned' })
  mine(@CurrentUser() user: JwtPayload) {
    return this.svc.listEarnedBy(user.sub);
  }
}

@Module({
  imports: [
    TypeOrmModule.forFeature([AchievementEntity, UserAchievementEntity]),
  ],
  providers: [AchievementsService],
  controllers: [AchievementsController],
  exports: [AchievementsService],
})
export class AchievementsModule {}
