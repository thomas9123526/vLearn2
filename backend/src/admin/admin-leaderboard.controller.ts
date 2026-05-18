import {
  Controller,
  Get,
  Query,
  UseGuards,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { UserEntity } from '../database/entities/user.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionGuard, RequirePermission } from './permissions/permission.guard';

type Metric = 'xp_total' | 'streak_days' | 'current_level';

const METRIC_COLUMN: Record<Metric, string> = {
  xp_total: 'xp_total',
  streak_days: 'streak_days',
  current_level: 'current_level',
};

/**
 * Leaderboard for the admin panel. Differs from any user-facing leaderboard
 * in that it's not filtered by `leaderboard_opt_in` — admins see everyone.
 *
 * Available metrics: total XP, streak days, current level. Default 50 rows;
 * cap at 200 to keep the query small.
 */
@ApiTags('Admin / Leaderboard')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionGuard)
@Controller('admin/leaderboard')
export class AdminLeaderboardController {
  constructor(
    @InjectRepository(UserEntity)
    private readonly users: Repository<UserEntity>,
  ) {}

  @Get()
  @RequirePermission('leaderboard.view')
  @ApiOperation({ summary: 'Top users by chosen metric' })
  @ApiQuery({ name: 'metric', required: false, enum: ['xp_total', 'streak_days', 'current_level'] })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'language', required: false })
  async top(
    @Query('metric') metric: Metric = 'xp_total',
    @Query('limit') limit?: string,
    @Query('language') language?: string,
  ) {
    const col = METRIC_COLUMN[metric] ?? METRIC_COLUMN.xp_total;
    const lim = Math.min(parseInt(limit ?? '50', 10) || 50, 200);
    const qb = this.users
      .createQueryBuilder('u')
      .select([
        'u.id',
        'u.email',
        'u.name',
        'u.avatar_emoji',
        'u.ui_language',
        'u.xp_total',
        'u.current_level',
        'u.streak_days',
        'u.status',
      ])
      .where(`u.role = 'user' AND u.status = 'active'`)
      .orderBy(`u.${col}`, 'DESC')
      .limit(lim);
    if (language) qb.andWhere('u.ui_language = :lang', { lang: language });
    const rows = await qb.getMany();
    return rows.map((u, i) => ({
      rank: i + 1,
      id: u.id,
      email: u.email,
      display_name: u.name,
      avatar_emoji: u.avatar_emoji,
      ui_language: u.ui_language,
      xp_total: u.xp_total,
      current_level: u.current_level,
      streak_days: u.streak_days,
      score:
        metric === 'xp_total'
          ? u.xp_total
          : metric === 'streak_days'
            ? u.streak_days
            : u.current_level,
    }));
  }
}
