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
import { UserInfoEntity } from '../database/entities/user-info.entity';
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
    @InjectRepository(UserInfoEntity)
    private readonly userInfos: Repository<UserInfoEntity>,
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
      qb.andWhere(`(i.email ILIKE :q OR u.name ILIKE :q)`, { q: `%${q}%` });
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
    const i = await this.userInfos.findOne({ where: { user_id: id }, relations: ['user'] });
    if (!i) throw new NotFoundException({ i18nKey: 'user.not_found' });
    return i;
  }

  @Post(':id/suspend')
  @RequirePermission('users.suspend')
  @ApiOperation({ summary: 'Suspend (block) a user — sub-admins use this to stop abusers' })
  async suspend(@Param('id') id: string, @Body() dto: SuspendUserDto) {
    const i = await this.userInfos.findOne({ where: { user_id: id } });
    if (!i) throw new NotFoundException({ i18nKey: 'user.not_found' });
    if (i.role !== 'user') {
      throw new BadRequestException({ i18nKey: 'user.cannot_suspend_admin' });
    }
    i.status = 'suspended';
    i.suspended_reason = dto.reason ?? null;
    i.suspended_until = dto.until ? new Date(dto.until) : null;
    await this.userInfos.save(i);
    return { ok: true };
  }

  @Post(':id/restore')
  @RequirePermission('users.suspend')
  @ApiOperation({ summary: 'Restore a previously suspended user' })
  async restore(@Param('id') id: string) {
    const i = await this.userInfos.findOne({ where: { user_id: id } });
    if (!i) throw new NotFoundException({ i18nKey: 'user.not_found' });
    i.status = 'active';
    i.suspended_reason = null;
    i.suspended_until = null;
    await this.userInfos.save(i);
    return { ok: true };
  }
}
