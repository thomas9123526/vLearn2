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
import { DataSource, EntityManager, Repository } from 'typeorm';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiTags,
  ApiProperty,
} from '@nestjs/swagger';
import {
  ArrayMinSize,
  IsArray,
  IsEmail,
  IsString,
  MinLength,
  MaxLength,
} from 'class-validator';
import * as bcrypt from 'bcrypt';
import { AdminEntity } from '../../database/entities/admin.entity';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import type { JwtPayload } from '../../auth/strategies/jwt.strategy';
import { AdminPermissionsService } from '../permissions/admin-permissions.service';
import {
  PermissionGuard,
  RequirePermission,
} from '../permissions/permission.guard';
import {
  GRANTABLE_PERMISSION_KEYS,
  PERMISSION_CATALOG,
  PERMISSION_KEYS,
} from '../permissions/catalog';
import { AdminAuditLogService } from '../audit/admin-audit-log.service';

class CreateSubAdminDto {
  @ApiProperty() @IsEmail() email!: string;
  @ApiProperty() @IsString() @MinLength(12) @MaxLength(128) password!: string;
  @ApiProperty() @IsString() @MinLength(2) @MaxLength(100) displayName!: string;
  @ApiProperty({ type: [String], required: false })
  @IsArray()
  @IsString({ each: true })
  permissions: string[] = [];
}

class ReplacePermissionsDto {
  @ApiProperty({ type: [String] })
  @IsArray()
  @IsString({ each: true })
  @ArrayMinSize(0)
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
    private readonly audit: AdminAuditLogService,
    private readonly dataSource: DataSource,
  ) {}

  @Get('catalog')
  @RequirePermission() // any admin/superadmin can read
  @ApiOperation({ summary: 'Permission catalog (used by the admin panel UI)' })
  catalog() {
    return PERMISSION_CATALOG;
  }

  @Get('me/permissions')
  @RequirePermission() // any logged-in admin reads their own perms
  @ApiOperation({
    summary:
      "Current admin's effective permission set (used by the admin panel UI)",
  })
  async myPermissions(@CurrentUser() user: JwtPayload): Promise<string[]> {
    // Superadmin holds every permission implicitly — the frontend already
    // short-circuits on role, but be explicit for direct callers.
    if (user.role === 'superadmin') {
      return [...PERMISSION_KEYS];
    }
    return [...(await this.permissions.getForUser(user.sub))];
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
  @ApiOperation({
    summary: 'Create a new sub-admin with an initial permission set',
  })
  async create(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateSubAdminDto,
  ) {
    if (user.role !== 'superadmin') {
      throw new ForbiddenException({ i18nKey: 'admin.superadmin_only' });
    }
    this.validatePermissions(dto.permissions);
    const hash = await bcrypt.hash(dto.password, 10);

    return this.dataSource.transaction(async (em) => {
      const adminRepo = em.getRepository(AdminEntity);
      const dup = await adminRepo.findOne({ where: { email: dto.email } });
      if (dup) throw new ConflictException({ i18nKey: 'auth.email_taken' });

      const created = await adminRepo.save(
        adminRepo.create({
          email: dto.email,
          password_hash: hash,
          display_name: dto.displayName,
          role: 'admin',
        }),
      );
      await this.permissions.replaceAll(
        created.id,
        dto.permissions,
        user.sub,
        em,
      );
      await this.audit.record(
        {
          actorId: user.sub,
          action: 'admin.create',
          targetType: 'admin',
          targetId: created.id,
          newValue: {
            email: dto.email,
            display_name: dto.displayName,
            permissions: dto.permissions,
          },
        },
        em,
      );
      return {
        id: created.id,
        email: created.email,
        permissions: dto.permissions,
      };
    });
  }

  @Put(':id/permissions')
  @RequirePermission('admins.grant_permissions')
  @ApiOperation({ summary: 'Replace the permission set for a sub-admin' })
  async replacePerms(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: ReplacePermissionsDto,
  ) {
    this.validatePermissions(dto.permissions);
    return this.dataSource.transaction(async (em) => {
      await this.ensureTargetIsAdmin(id, em);
      const before = [...(await this.permissions.getForUser(id, em))].sort();
      await this.permissions.replaceAll(id, dto.permissions, user.sub, em);
      await this.audit.record(
        {
          actorId: user.sub,
          action: 'admin.replace_permissions',
          targetType: 'admin',
          targetId: id,
          oldValue: { permissions: before },
          newValue: { permissions: [...dto.permissions].sort() },
        },
        em,
      );
      return { id, permissions: dto.permissions };
    });
  }

  @Post(':id/permissions/:perm')
  @RequirePermission('admins.grant_permissions')
  @ApiOperation({ summary: 'Grant a single permission' })
  async grantOne(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Param('perm') perm: string,
  ) {
    this.validatePermissions([perm]);
    await this.dataSource.transaction(async (em) => {
      await this.ensureTargetIsAdmin(id, em);
      await this.permissions.grant(id, [perm], user.sub, em);
      await this.audit.record(
        {
          actorId: user.sub,
          action: 'admin.grant_permission',
          targetType: 'admin',
          targetId: id,
          newValue: { permission: perm },
        },
        em,
      );
    });
    return { ok: true };
  }

  @Delete(':id/permissions/:perm')
  @RequirePermission('admins.grant_permissions')
  @ApiOperation({ summary: 'Revoke a single permission' })
  async revokeOne(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Param('perm') perm: string,
  ) {
    await this.dataSource.transaction(async (em) => {
      await this.permissions.revoke(id, [perm], em);
      await this.audit.record(
        {
          actorId: user.sub,
          action: 'admin.revoke_permission',
          targetType: 'admin',
          targetId: id,
          oldValue: { permission: perm },
        },
        em,
      );
    });
    return { ok: true };
  }

  @Post(':id/suspend')
  @RequirePermission('admins.suspend')
  @ApiOperation({ summary: 'Suspend a sub-admin' })
  async suspend(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    if (id === user.sub)
      throw new ForbiddenException({ i18nKey: 'admin.cannot_self_modify' });
    await this.dataSource.transaction(async (em) => {
      const a = await this.ensureTargetIsAdmin(id, em);
      const oldStatus = a.status;
      a.status = 'suspended';
      await em.getRepository(AdminEntity).save(a);
      await this.audit.record(
        {
          actorId: user.sub,
          action: 'admin.suspend',
          targetType: 'admin',
          targetId: id,
          oldValue: { status: oldStatus },
          newValue: { status: 'suspended' },
        },
        em,
      );
    });
    return { ok: true };
  }

  @Post(':id/restore')
  @RequirePermission('admins.suspend')
  async restore(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    await this.dataSource.transaction(async (em) => {
      const a = await this.ensureTargetIsAdmin(id, em);
      const oldStatus = a.status;
      a.status = 'active';
      await em.getRepository(AdminEntity).save(a);
      await this.audit.record(
        {
          actorId: user.sub,
          action: 'admin.restore',
          targetType: 'admin',
          targetId: id,
          oldValue: { status: oldStatus },
          newValue: { status: 'active' },
        },
        em,
      );
    });
    return { ok: true };
  }

  @Delete(':id')
  @RequirePermission('admins.delete')
  async softDelete(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    if (id === user.sub)
      throw new ForbiddenException({ i18nKey: 'admin.cannot_self_modify' });
    await this.dataSource.transaction(async (em) => {
      const a = await this.ensureTargetIsAdmin(id, em);
      const before = {
        status: a.status,
        email: a.email,
        display_name: a.display_name,
      };
      a.status = 'deleted';
      a.email = `deleted-${id}@removed.local`;
      a.display_name = '(deleted)';
      await em.getRepository(AdminEntity).save(a);
      await this.audit.record(
        {
          actorId: user.sub,
          action: 'admin.delete',
          targetType: 'admin',
          targetId: id,
          oldValue: before,
          newValue: {
            status: 'deleted',
            email: a.email,
            display_name: a.display_name,
          },
        },
        em,
      );
    });
    return { ok: true };
  }

  private validatePermissions(perms: string[]) {
    const unknown = perms.filter((p) => !PERMISSION_KEYS.has(p));
    if (unknown.length > 0) {
      throw new BadRequestException({
        i18nKey: 'admin.unknown_permissions',
        unknown,
      });
    }
    const ungrantable = perms.filter((p) => !GRANTABLE_PERMISSION_KEYS.has(p));
    if (ungrantable.length > 0) {
      throw new BadRequestException({
        i18nKey: 'admin.ungrantable',
        ungrantable,
      });
    }
  }

  private async ensureTargetIsAdmin(
    id: string,
    em?: EntityManager,
  ): Promise<AdminEntity> {
    const repo = em ? em.getRepository(AdminEntity) : this.admins;
    const a = await repo.findOne({ where: { id, role: 'admin' } });
    if (!a) throw new NotFoundException({ i18nKey: 'admin.not_found' });
    return a;
  }
}
