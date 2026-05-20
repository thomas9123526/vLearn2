import {
  BadRequestException,
  Body,
  ConflictException,
  Controller,
  Delete,
  ForbiddenException,
  Get,
  NotFoundException,
  Param,
  Post,
  Put,
  UseGuards,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ApiBearerAuth, ApiOperation, ApiTags, ApiProperty } from '@nestjs/swagger';
import { ArrayMinSize, IsArray, IsEmail, IsString, MinLength, MaxLength } from 'class-validator';
import * as bcrypt from 'bcrypt';
import { AdminEntity } from '../../database/entities/admin.entity';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import type { JwtPayload } from '../../auth/strategies/jwt.strategy';
import { AdminPermissionsService } from '../permissions/admin-permissions.service';
import { PermissionGuard, RequirePermission } from '../permissions/permission.guard';
import { GRANTABLE_PERMISSION_KEYS, PERMISSION_CATALOG, PERMISSION_KEYS } from '../permissions/catalog';

class CreateSubAdminDto {
  @ApiProperty() @IsEmail() email!: string;
  @ApiProperty() @IsString() @MinLength(12) @MaxLength(128) password!: string;
  @ApiProperty() @IsString() @MinLength(2) @MaxLength(100) displayName!: string;
  @ApiProperty({ type: [String], required: false })
  @IsArray() @IsString({ each: true })
  permissions: string[] = [];
}

class ReplacePermissionsDto {
  @ApiProperty({ type: [String] })
  @IsArray() @IsString({ each: true }) @ArrayMinSize(0)
  permissions!: string[];
}

@ApiTags('Admin / Admins')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionGuard)
@Controller('admin/admins')
export class AdminAdminsController {
  constructor(
    @InjectRepository(AdminEntity)
    private readonly admins: Repository<AdminEntity>,
    private readonly permissions: AdminPermissionsService,
  ) {}

  @Get('catalog')
  @RequirePermission() // any admin/superadmin can read
  @ApiOperation({ summary: 'Permission catalog (used by the admin panel UI)' })
  catalog() {
    return PERMISSION_CATALOG;
  }

  @Get()
  @RequirePermission('admins.view')
  @ApiOperation({ summary: 'List all sub-admins with their permissions' })
  async list() {
    const admins = await this.admins.find({ where: { role: 'admin' } });
    const out = await Promise.all(
      admins.map(async (a) => ({
        id: a.id,
        email: a.email,
        display_name: a.display_name,
        role: a.role,
        status: a.status,
        permissions: [...(await this.permissions.getForUser(a.id))],
      })),
    );
    return out;
  }

  @Post()
  @RequirePermission('admins.create')
  @ApiOperation({ summary: 'Create a new sub-admin with an initial permission set' })
  async create(@CurrentUser() user: JwtPayload, @Body() dto: CreateSubAdminDto) {
    if (user.role !== 'superadmin') {
      throw new ForbiddenException({ i18nKey: 'admin.superadmin_only' });
    }
    const dup = await this.admins.findOne({ where: { email: dto.email } });
    if (dup) throw new ConflictException({ i18nKey: 'auth.email_taken' });

    this.validatePermissions(dto.permissions);

    const hash = await bcrypt.hash(dto.password, 10);
    const created = await this.admins.save(
      this.admins.create({
        email: dto.email,
        password_hash: hash,
        display_name: dto.displayName,
        role: 'admin',
      }),
    );
    await this.permissions.replaceAll(created.id, dto.permissions, user.sub);
    return { id: created.id, email: created.email, permissions: dto.permissions };
  }

  @Put(':id/permissions')
  @RequirePermission('admins.grant_permissions')
  @ApiOperation({ summary: 'Replace the permission set for a sub-admin' })
  async replacePerms(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: ReplacePermissionsDto,
  ) {
    await this.ensureTargetIsAdmin(id);
    this.validatePermissions(dto.permissions);
    await this.permissions.replaceAll(id, dto.permissions, user.sub);
    return { id, permissions: dto.permissions };
  }

  @Post(':id/permissions/:perm')
  @RequirePermission('admins.grant_permissions')
  @ApiOperation({ summary: 'Grant a single permission' })
  async grantOne(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Param('perm') perm: string,
  ) {
    await this.ensureTargetIsAdmin(id);
    this.validatePermissions([perm]);
    await this.permissions.grant(id, [perm], user.sub);
    return { ok: true };
  }

  @Delete(':id/permissions/:perm')
  @RequirePermission('admins.grant_permissions')
  @ApiOperation({ summary: 'Revoke a single permission' })
  async revokeOne(@Param('id') id: string, @Param('perm') perm: string) {
    await this.permissions.revoke(id, [perm]);
    return { ok: true };
  }

  @Post(':id/suspend')
  @RequirePermission('admins.suspend')
  @ApiOperation({ summary: 'Suspend a sub-admin' })
  async suspend(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    if (id === user.sub) throw new ForbiddenException({ i18nKey: 'admin.cannot_self_modify' });
    const a = await this.ensureTargetIsAdmin(id);
    a.status = 'suspended';
    await this.admins.save(a);
    return { ok: true };
  }

  @Post(':id/restore')
  @RequirePermission('admins.suspend')
  async restore(@Param('id') id: string) {
    const a = await this.ensureTargetIsAdmin(id);
    a.status = 'active';
    await this.admins.save(a);
    return { ok: true };
  }

  @Delete(':id')
  @RequirePermission('admins.delete')
  async softDelete(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    if (id === user.sub) throw new ForbiddenException({ i18nKey: 'admin.cannot_self_modify' });
    const a = await this.ensureTargetIsAdmin(id);
    a.status = 'deleted';
    a.email = `deleted-${id}@removed.local`;
    a.display_name = '(deleted)';
    await this.admins.save(a);
    return { ok: true };
  }

  private validatePermissions(perms: string[]) {
    const unknown = perms.filter((p) => !PERMISSION_KEYS.has(p));
    if (unknown.length > 0) {
      throw new BadRequestException({ i18nKey: 'admin.unknown_permissions', unknown });
    }
    const ungrantable = perms.filter((p) => !GRANTABLE_PERMISSION_KEYS.has(p));
    if (ungrantable.length > 0) {
      throw new BadRequestException({ i18nKey: 'admin.ungrantable', ungrantable });
    }
  }

  private async ensureTargetIsAdmin(id: string): Promise<AdminEntity> {
    const a = await this.admins.findOne({ where: { id, role: 'admin' } });
    if (!a) throw new NotFoundException({ i18nKey: 'admin.not_found' });
    return a;
  }
}
