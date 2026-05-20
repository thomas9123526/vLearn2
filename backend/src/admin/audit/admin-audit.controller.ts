import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import {
  IsISO8601,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';
import { Type } from 'class-transformer';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import {
  PermissionGuard,
  RequirePermission,
} from '../permissions/permission.guard';
import { AdminAuditLogService } from './admin-audit-log.service';

class ListAuditQueryDto {
  @IsOptional() @IsUUID() actor?: string;
  @IsOptional() @IsString() @MaxLength(50) action?: string;
  @IsOptional() @IsString() @MaxLength(20) target_type?: string;
  @IsOptional() @IsString() @MaxLength(100) target_id?: string;
  @IsOptional() @IsISO8601() since?: string;
  @IsOptional() @IsISO8601() until?: string;
  @IsOptional() @Type(() => Number) page?: number;
  @IsOptional() @Type(() => Number) limit?: number;
}

@ApiTags('Admin / Audit log')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionGuard)
@Controller('admin/audit')
export class AdminAuditController {
  constructor(private readonly audit: AdminAuditLogService) {}

  @Get()
  @RequirePermission('audit.view')
  @ApiOperation({
    summary: 'List admin audit-log entries with filters and pagination',
  })
  async list(@Query() q: ListAuditQueryDto) {
    const page = Math.max(q.page ?? 1, 1);
    const limit = Math.min(Math.max(q.limit ?? 50, 1), 200);
    return this.audit.list({
      actor: q.actor,
      action: q.action,
      targetType: q.target_type,
      targetId: q.target_id,
      since: q.since ? new Date(q.since) : undefined,
      until: q.until ? new Date(q.until) : undefined,
      page,
      limit,
    });
  }
}
