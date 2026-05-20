import { Controller, Get, UseGuards } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { UserInfoEntity } from '../../database/entities/user-info.entity';
import { ConversationSessionEntity } from '../../database/entities/conversation.entity';
import { ScenarioEntity } from '../../database/entities/scenario.entity';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import {
  PermissionGuard,
  RequirePermission,
} from '../permissions/permission.guard';

interface AdminStatsResponse {
  users_total: number;
  users_active_30d: number;
  sessions_total: number;
  scenarios_published: number;
}

@ApiTags('Admin / Stats')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionGuard)
@Controller('admin/stats')
export class AdminStatsController {
  constructor(
    @InjectRepository(UserInfoEntity)
    private readonly userInfos: Repository<UserInfoEntity>,
    @InjectRepository(ConversationSessionEntity)
    private readonly sessions: Repository<ConversationSessionEntity>,
    @InjectRepository(ScenarioEntity)
    private readonly scenarios: Repository<ScenarioEntity>,
  ) {}

  @Get()
  @RequirePermission() // any admin/superadmin
  @ApiOperation({ summary: 'Cheap dashboard counters for the admin panel' })
  async overview(): Promise<AdminStatsResponse> {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const [usersTotal, usersActive, sessionsTotal, scenariosPublished] =
      await Promise.all([
        this.userInfos.count({ where: { role: 'user' } }),
        this.userInfos
          .createQueryBuilder('i')
          .where(`i.role = 'user' AND i.last_active_date >= :since`, {
            since: thirtyDaysAgo,
          })
          .getCount(),
        this.sessions.count(),
        this.scenarios.count({ where: { status: 'published' } }),
      ]);

    return {
      users_total: usersTotal,
      users_active_30d: usersActive,
      sessions_total: sessionsTotal,
      scenarios_published: scenariosPublished,
    };
  }
}
