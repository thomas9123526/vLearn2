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
import { Repository } from 'typeorm';
import { ApiBearerAuth, ApiOperation, ApiProperty, ApiTags } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength } from 'class-validator';
import { UserEntity } from '../database/entities/user.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionGuard, RequirePermission } from './permissions/permission.guard';

class SuspendUserDto {
  @ApiProperty({ required: false }) @IsOptional() @IsString() @MaxLength(500)
  reason?: string;
  @ApiProperty({ required: false, description: 'ISO timestamp; omit for indefinite' })
  @IsOptional()
  @IsString()
  until?: string;
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
    @InjectRepository(UserEntity)
    private readonly users: Repository<UserEntity>,
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
    const qb = this.users
      .createQueryBuilder('u')
      .where(`u.role = 'user'`)
      .orderBy('u.created_at', 'DESC')
      .skip(off)
      .take(lim);
    if (q) {
      qb.andWhere(`(u.email ILIKE :q OR u.display_name ILIKE :q)`, { q: `%${q}%` });
    }
    if (status) qb.andWhere('u.status = :s', { s: status });
    const [items, total] = await qb.getManyAndCount();
    return {
      items: items.map((u) => ({
        id: u.id,
        email: u.email,
        display_name: u.display_name,
        status: u.status,
        suspended_until: u.suspended_until,
        suspended_reason: u.suspended_reason,
        xp_total: u.xp_total,
        current_level: u.current_level,
        streak_days: u.streak_days,
        created_at: u.created_at,
      })),
      total,
      page: parseInt(page ?? '1', 10) || 1,
      limit: lim,
    };
  }

  @Get(':id')
  @RequirePermission('users.view')
  async get(@Param('id') id: string) {
    const u = await this.users.findOne({ where: { id } });
    if (!u) throw new NotFoundException({ i18nKey: 'user.not_found' });
    return u;
  }

  @Post(':id/suspend')
  @RequirePermission('users.suspend')
  @ApiOperation({ summary: 'Suspend (block) a user — sub-admins use this to stop abusers' })
  async suspend(@Param('id') id: string, @Body() dto: SuspendUserDto) {
    const u = await this.users.findOne({ where: { id } });
    if (!u) throw new NotFoundException({ i18nKey: 'user.not_found' });
    if (u.role !== 'user') {
      throw new BadRequestException({ i18nKey: 'user.cannot_suspend_admin' });
    }
    u.status = 'suspended';
    u.suspended_reason = dto.reason ?? null;
    u.suspended_until = dto.until ? new Date(dto.until) : null;
    await this.users.save(u);
    return { ok: true };
  }

  @Post(':id/restore')
  @RequirePermission('users.suspend')
  @ApiOperation({ summary: 'Restore a previously suspended user' })
  async restore(@Param('id') id: string) {
    const u = await this.users.findOne({ where: { id } });
    if (!u) throw new NotFoundException({ i18nKey: 'user.not_found' });
    u.status = 'active';
    u.suspended_reason = null;
    u.suspended_until = null;
    await this.users.save(u);
    return { ok: true };
  }
}
