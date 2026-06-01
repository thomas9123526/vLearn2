import {
  BadRequestException,
  Body,
  Controller,
  Get,
  NotFoundException,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, Repository } from 'typeorm';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiProperty,
  ApiTags,
} from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import * as bcrypt from 'bcrypt';
import { UserInfoEntity } from '../database/entities/user-info.entity';
import { UserEntity } from '../database/entities/user.entity';
import { RefreshTokenEntity } from '../database/entities/refresh-token.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { JwtPayload } from '../auth/strategies/jwt.strategy';
import {
  PermissionGuard,
  RequirePermission,
} from './permissions/permission.guard';
import { AdminAuditLogService } from './audit/admin-audit-log.service';
import { NetworkStatsService } from '../network-stats/network-stats.service';
import { encryptField } from '../common/field-encryption';

const BCRYPT_ROUNDS = 10;

class SuspendUserDto {
  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
  @ApiProperty({
    required: false,
    description: 'ISO timestamp; omit for indefinite',
  })
  @IsOptional()
  @IsString()
  until?: string;
}

class ResetPasswordDto {
  @ApiProperty({
    description:
      'New plain-text password chosen by the admin. Must satisfy the same length-only rule as user sign-up (≥ 6 chars).',
    example: 'temp1234',
  })
  @IsString()
  @MinLength(6)
  @MaxLength(128)
  newPassword!: string;
}

/**
 * Admin endpoints for managing app users (not sub-admins — those live under
 * `/admin/admins`). Suspend/restore is the most-used path and is granted to
 * sub-admins via the `users.suspend` permission.
 */
@ApiTags('Admin / Users')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionGuard)
@Controller('admin/users')
export class AdminUsersController {
  constructor(
    @InjectRepository(UserInfoEntity)
    private readonly userInfos: Repository<UserInfoEntity>,
    @InjectRepository(UserEntity)
    private readonly users: Repository<UserEntity>,
    @InjectRepository(RefreshTokenEntity)
    private readonly refreshTokens: Repository<RefreshTokenEntity>,
    private readonly audit: AdminAuditLogService,
    private readonly dataSource: DataSource,
    private readonly networkStats: NetworkStatsService,
  ) {}

  @Get()
  @RequirePermission('users.view')
  @ApiOperation({ summary: 'Search users with pagination' })
  async list(
    @Query('q') q?: string,
    @Query('status') status?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const lim = Math.min(parseInt(limit ?? '20', 10) || 20, 100);
    const off = Math.max((parseInt(page ?? '1', 10) || 1) - 1, 0) * lim;
    const qb = this.userInfos
      .createQueryBuilder('i')
      .leftJoinAndSelect('i.user', 'u')
      .where(`i.role = 'user'`)
      .orderBy('u.created_at', 'DESC')
      .skip(off)
      .take(lim);
    if (q) {
      // email is AES-encrypted — only exact-match is possible; name supports ILIKE partial match.
      qb.andWhere(`(i.email = :eq OR u.name ILIKE :q)`, {
        eq: encryptField(q),
        q: `%${q}%`,
      });
    }
    if (status) qb.andWhere('i.status = :s', { s: status });
    const [items, total] = await qb.getManyAndCount();
    return {
      items: items.map((i) => ({
        id: i.user_id,
        email: i.email,
        display_name: i.user.name,
        status: i.status,
        suspended_until: i.suspended_until,
        suspended_reason: i.suspended_reason,
        xp_total: i.xp_total,
        current_level: i.current_level,
        streak_days: i.streak_days,
        license_platform: i.user.license_platform,
        license_valid_until: i.user.license_valid_until,
        created_at: i.user.created_at,
      })),
      total,
      page: parseInt(page ?? '1', 10) || 1,
      limit: lim,
    };
  }

  @Get(':id')
  @RequirePermission('users.view')
  async get(@Param('id') id: string) {
    const i = await this.userInfos.findOne({
      where: { user_id: id },
      relations: ['user'],
    });
    if (!i) throw new NotFoundException({ i18nKey: 'user.not_found' });
    const netStats = await this.networkStats.getStatsForUser(id);
    return {
      id: i.user_id,
      email: i.email,
      display_name: i.user.name,
      avatar_url: i.avatar_url,
      avatar_emoji: i.avatar_emoji,
      status: i.status,
      suspended_until: i.suspended_until,
      suspended_reason: i.suspended_reason,
      xp_total: i.xp_total,
      current_level: i.current_level,
      streak_days: i.streak_days,
      native_language: i.native_language,
      ui_language: i.ui_language,
      active_theme: i.active_theme,
      onboarding_done: i.onboarding_done,
      last_active_date: i.last_active_date,
      license_platform: i.user.license_platform,
      license_valid_until: i.user.license_valid_until,
      created_at: i.user.created_at,
      network_stats: netStats,
    };
  }

  @Post(':id/suspend')
  @RequirePermission('users.suspend')
  @ApiOperation({
    summary: 'Suspend (block) a user — sub-admins use this to stop abusers',
  })
  async suspend(
    @CurrentUser() actor: JwtPayload,
    @Param('id') id: string,
    @Body() dto: SuspendUserDto,
  ) {
    await this.dataSource.transaction(async (em) => {
      const repo = em.getRepository(UserInfoEntity);
      const i = await repo.findOne({ where: { user_id: id } });
      if (!i) throw new NotFoundException({ i18nKey: 'user.not_found' });
      if (i.role !== 'user') {
        throw new BadRequestException({ i18nKey: 'user.cannot_suspend_admin' });
      }
      const before = {
        status: i.status,
        suspended_reason: i.suspended_reason,
        suspended_until: i.suspended_until,
      };
      i.status = 'suspended';
      i.suspended_reason = dto.reason ?? null;
      i.suspended_until = dto.until ? new Date(dto.until) : null;
      await repo.save(i);
      await this.audit.record(
        {
          actorId: actor.sub,
          action: 'user.suspend',
          targetType: 'user',
          targetId: id,
          oldValue: before,
          newValue: {
            status: 'suspended',
            suspended_reason: i.suspended_reason,
            suspended_until: i.suspended_until,
          },
        },
        em,
      );
    });
    return { ok: true };
  }

  @Post(':id/restore')
  @RequirePermission('users.suspend')
  @ApiOperation({ summary: 'Restore a previously suspended user' })
  async restore(@CurrentUser() actor: JwtPayload, @Param('id') id: string) {
    await this.dataSource.transaction(async (em) => {
      const repo = em.getRepository(UserInfoEntity);
      const i = await repo.findOne({ where: { user_id: id } });
      if (!i) throw new NotFoundException({ i18nKey: 'user.not_found' });
      const before = {
        status: i.status,
        suspended_reason: i.suspended_reason,
        suspended_until: i.suspended_until,
      };
      i.status = 'active';
      i.suspended_reason = null;
      i.suspended_until = null;
      await repo.save(i);
      await this.audit.record(
        {
          actorId: actor.sub,
          action: 'user.restore',
          targetType: 'user',
          targetId: id,
          oldValue: before,
          newValue: {
            status: 'active',
            suspended_reason: null,
            suspended_until: null,
          },
        },
        em,
      );
    });
    return { ok: true };
  }

  /**
   * Admin-driven password reset. The admin types the new password; we
   * bcrypt-hash it, overwrite the user's `password_hash`, and revoke every
   * outstanding refresh token for that user so any concurrent sessions
   * are kicked out. The plain-text password is **not** echoed back —
   * the admin already knows what they typed; we just confirm "ok".
   *
   * Length-only constraint (≥ 6 chars) matches the sign-up DTO.
   */
  @Post(':id/reset-password')
  @RequirePermission('users.reset_password')
  @ApiOperation({
    summary: 'Reset a user’s password (overwrite + revoke sessions)',
  })
  async resetPassword(
    @CurrentUser() actor: JwtPayload,
    @Param('id') id: string,
    @Body() dto: ResetPasswordDto,
  ) {
    await this.dataSource.transaction(async (em) => {
      const userRepo = em.getRepository(UserEntity);
      const infoRepo = em.getRepository(UserInfoEntity);
      const refreshRepo = em.getRepository(RefreshTokenEntity);

      const info = await infoRepo.findOne({ where: { user_id: id } });
      if (!info) throw new NotFoundException({ i18nKey: 'user.not_found' });
      if (info.role !== 'user') {
        // Admin password changes happen via the admin-side flow, not here.
        throw new BadRequestException({
          i18nKey: 'user.cannot_reset_admin_password',
        });
      }

      const target = await userRepo.findOne({ where: { id } });
      if (!target) throw new NotFoundException({ i18nKey: 'user.not_found' });

      target.password_hash = await bcrypt.hash(dto.newPassword, BCRYPT_ROUNDS);
      await userRepo.save(target);

      // Kick every device — they must re-sign-in with the new password.
      const revoked = await refreshRepo.delete({ user_id: id });

      await this.audit.record(
        {
          actorId: actor.sub,
          action: 'user.reset_password',
          targetType: 'user',
          targetId: id,
          // Do NOT log the plain-text password or the hash. Just the fact
          // that a reset happened and how many sessions were revoked.
          oldValue: null,
          newValue: { revokedSessions: revoked.affected ?? 0 },
        },
        em,
      );
    });
    return { ok: true };
  }
}
