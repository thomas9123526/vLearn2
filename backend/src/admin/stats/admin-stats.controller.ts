import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, Repository } from 'typeorm';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { UserInfoEntity } from '../../database/entities/user-info.entity';
import { ConversationSessionEntity } from '../../database/entities/conversation.entity';
import { ScenarioEntity } from '../../database/entities/scenario.entity';
import { UserReportEntity } from '../../database/entities/user-report.entity';
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
    @InjectRepository(UserReportEntity)
    private readonly reports: Repository<UserReportEntity>,
    private readonly dataSource: DataSource,
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

  /** Global platform usage — sessions and network bytes per platform. */
  @Get('usage')
  @RequirePermission()
  @ApiOperation({ summary: 'Platform usage breakdown (sessions + bytes)' })
  async usage() {
    const [sessionsByPlatform, networkByPlatform] = await Promise.all([
      // Sessions per platform from vl_conversation_sessions joined to vl_user_info.
      this.dataSource.query(`
        SELECT ui.license_platform AS platform, COUNT(*)::int AS session_count
        FROM vl_conversation_sessions s
        JOIN vl_user_info ui ON ui.user_id = s.user_id
        WHERE ui.license_platform IS NOT NULL
        GROUP BY ui.license_platform
        ORDER BY session_count DESC
      `),
      // Network bytes per platform (summed across all users).
      this.dataSource.query(`
        SELECT platform,
               SUM(bytes_uploaded)::bigint   AS bytes_uploaded,
               SUM(bytes_downloaded)::bigint AS bytes_downloaded
        FROM vl_user_network_stats
        GROUP BY platform
        ORDER BY platform
      `),
    ]);

    return { sessions_by_platform: sessionsByPlatform, network_by_platform: networkByPlatform };
  }

  /** List user-submitted reports (paginated). */
  @Get('reports')
  @RequirePermission('reports.view')
  @ApiOperation({ summary: 'List user feedback/bug reports' })
  async listReports(
    @Query('type') type?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const lim = Math.min(parseInt(limit ?? '20', 10) || 20, 100);
    const off = Math.max((parseInt(page ?? '1', 10) || 1) - 1, 0) * lim;
    const qb = this.reports.createQueryBuilder('r').orderBy('r.created_at', 'DESC').skip(off).take(lim);
    if (type) qb.where('r.type = :t', { t: type });
    const [items, total] = await qb.getManyAndCount();
    return { items, total, page: parseInt(page ?? '1', 10) || 1, limit: lim };
  }
}
