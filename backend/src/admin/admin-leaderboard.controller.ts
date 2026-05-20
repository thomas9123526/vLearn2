import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
  ApiTags,
} from '@nestjs/swagger';
import { UserInfoEntity } from '../database/entities/user-info.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  PermissionGuard,
  RequirePermission,
} from './permissions/permission.guard';

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
    @InjectRepository(UserInfoEntity)
    private readonly userInfos: Repository<UserInfoEntity>,
  ) {}

  @Get()
  @RequirePermission('leaderboard.view')
  @ApiOperation({ summary: 'Top users by chosen metric' })
  @ApiQuery({
    name: 'metric',
    required: false,
    enum: ['xp_total', 'streak_days', 'current_level'],
  })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'language', required: false })
  async top(
    @Query('metric') metric: Metric = 'xp_total',
    @Query('limit') limit?: string,
    @Query('language') language?: string,
  ) {
    const col = METRIC_COLUMN[metric] ?? METRIC_COLUMN.xp_total;
    const lim = Math.min(parseInt(limit ?? '50', 10) || 50, 200);
    const qb = this.userInfos
      .createQueryBuilder('i')
      .leftJoinAndSelect('i.user', 'u')
      .where(`i.role = 'user' AND i.status = 'active'`)
      .orderBy(`i.${col}`, 'DESC')
      .limit(lim);
    if (language) qb.andWhere('i.ui_language = :lang', { lang: language });
    const rows = await qb.getMany();
    return rows.map((i, idx) => ({
      rank: idx + 1,
      id: i.user_id,
      email: i.email,
      display_name: i.user.name,
      avatar_emoji: i.avatar_emoji,
      ui_language: i.ui_language,
      xp_total: i.xp_total,
      current_level: i.current_level,
      streak_days: i.streak_days,
      score:
        metric === 'xp_total'
          ? i.xp_total
          : metric === 'streak_days'
            ? i.streak_days
            : i.current_level,
    }));
  }
}
