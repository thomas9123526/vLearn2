import {
  Module,
  Injectable,
  Controller,
  Get,
  Patch,
  Param,
  Body,
  Post,
  ForbiddenException,
  NotFoundException,
  BadRequestException,
  UseGuards,
} from '@nestjs/common';
import { TypeOrmModule, InjectRepository } from '@nestjs/typeorm';
import { DataSource, Repository } from 'typeorm';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { AppConfigEntity } from '../database/entities/app-config.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { JwtPayload } from '../auth/strategies/jwt.strategy';
import {
  PermissionGuard,
  RequirePermission,
} from '../admin/permissions/permission.guard';
import { AdminAuditLogService } from '../admin/audit/admin-audit-log.service';

/// Live in-memory cache for the gzip-enable flag. The compression filter in
/// `main.ts` reads this directly because it's on the hot path of every
/// request. The cache is seeded on service init and refreshed whenever an
/// admin updates `system.gzip_enabled`.
class GzipFlagCache {
  static enabled = true;
}

@Injectable()
class AppConfigService {
  constructor(
    @InjectRepository(AppConfigEntity)
    private readonly repo: Repository<AppConfigEntity>,
    private readonly audit: AdminAuditLogService,
    private readonly dataSource: DataSource,
  ) {
    void this.refreshGzipCache();
  }

  async refreshGzipCache(): Promise<void> {
    const row = await this.repo.findOne({
      where: { key: 'system.gzip_enabled' },
    });
    if (row && typeof row.value === 'boolean') {
      GzipFlagCache.enabled = row.value;
    }
  }

  async appVisibleFlags(): Promise<{
    version: string;
    flags: Record<string, unknown>;
  }> {
    const rows = await this.repo.find({ where: { is_visible_to_app: true } });
    const flags: Record<string, unknown> = {};
    let max = new Date(0);
    for (const r of rows) {
      flags[r.key] = r.value;
      if (r.updated_at > max) max = r.updated_at;
    }
    return { version: max.toISOString(), flags };
  }

  listAll() {
    return this.repo.find({ order: { category: 'ASC', key: 'ASC' } });
  }

  async getOne(key: string): Promise<AppConfigEntity> {
    const row = await this.repo.findOne({ where: { key } });
    if (!row) throw new NotFoundException({ i18nKey: 'config.not_found' });
    return row;
  }

  async update(
    key: string,
    value: unknown,
    updatedBy: string,
  ): Promise<AppConfigEntity> {
    return this.dataSource.transaction(async (em) => {
      const repo = em.getRepository(AppConfigEntity);
      const row = await repo.findOne({ where: { key } });
      if (!row) throw new NotFoundException({ i18nKey: 'config.not_found' });
      if (!this.typeMatches(row.value_type, value)) {
        throw new BadRequestException({
          i18nKey: 'config.type_mismatch',
          expected: row.value_type,
        });
      }
      const oldValue = row.value;
      row.value = value;
      row.updated_by = updatedBy;
      const saved = await repo.save(row);
      await this.audit.record(
        {
          actorId: updatedBy,
          action: 'config.update',
          targetType: 'config',
          targetId: key,
          oldValue: { value: oldValue },
          newValue: { value },
        },
        em,
      );
      if (key === 'system.gzip_enabled' && typeof value === 'boolean') {
        GzipFlagCache.enabled = value;
      }
      return saved;
    });
  }

  async reset(key: string, updatedBy: string): Promise<AppConfigEntity> {
    return this.dataSource.transaction(async (em) => {
      const repo = em.getRepository(AppConfigEntity);
      const row = await repo.findOne({ where: { key } });
      if (!row) throw new NotFoundException({ i18nKey: 'config.not_found' });
      const oldValue = row.value;
      row.value = row.default_value;
      row.updated_by = updatedBy;
      const saved = await repo.save(row);
      await this.audit.record(
        {
          actorId: updatedBy,
          action: 'config.reset',
          targetType: 'config',
          targetId: key,
          oldValue: { value: oldValue },
          newValue: { value: row.default_value },
        },
        em,
      );
      if (key === 'system.gzip_enabled' && typeof row.value === 'boolean') {
        GzipFlagCache.enabled = row.value;
      }
      return saved;
    });
  }

  private typeMatches(t: string, v: unknown): boolean {
    switch (t) {
      case 'boolean':
        return typeof v === 'boolean';
      case 'string':
        return typeof v === 'string';
      case 'number':
        return typeof v === 'number';
      case 'array':
        return Array.isArray(v);
      case 'object':
        return typeof v === 'object' && v !== null && !Array.isArray(v);
      default:
        return true;
    }
  }
}

@ApiTags('App Config')
@Controller('app-config')
class AppConfigController {
  constructor(private readonly svc: AppConfigService) {}

  @Get()
  @ApiOperation({
    summary: 'All visibility flags for the Flutter app to cache (public)',
  })
  flags() {
    return this.svc.appVisibleFlags();
  }
}

@ApiTags('Admin / Config')
@UseGuards(JwtAuthGuard, PermissionGuard)
@ApiBearerAuth()
@Controller('admin/config')
class AdminConfigController {
  constructor(private readonly svc: AppConfigService) {}

  @Get()
  @RequirePermission('config.view')
  list() {
    return this.svc.listAll();
  }

  @Get(':key')
  @RequirePermission('config.view')
  get(@Param('key') key: string) {
    return this.svc.getOne(key);
  }

  @Patch(':key')
  @RequirePermission('config.edit')
  update(
    @CurrentUser() user: JwtPayload,
    @Param('key') key: string,
    @Body() body: { value: unknown },
  ) {
    return this.svc.update(key, body.value, user.sub);
  }

  @Post('reset/:key')
  @RequirePermission('config.edit')
  reset(@CurrentUser() user: JwtPayload, @Param('key') key: string) {
    return this.svc.reset(key, user.sub);
  }

  @Post('reset-all')
  async resetAll(@CurrentUser() user: JwtPayload) {
    if (user.role !== 'superadmin') {
      throw new ForbiddenException({ i18nKey: 'admin.superadmin_only' });
    }
    const all = await this.svc.listAll();
    for (const row of all) {
      await this.svc.reset(row.key, user.sub);
    }
    return { reset: all.length };
  }
}

@Module({
  imports: [TypeOrmModule.forFeature([AppConfigEntity])],
  providers: [AppConfigService],
  controllers: [AppConfigController, AdminConfigController],
  exports: [AppConfigService],
})
export class AppConfigModule {}

export { GzipFlagCache };
