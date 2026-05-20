import {
  Body,
  Controller,
  Get,
  NotFoundException,
  Param,
  Patch,
  UseGuards,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, Repository } from 'typeorm';
import { ApiBearerAuth, ApiOperation, ApiProperty, ApiTags } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsString } from 'class-validator';
import { PromptTemplateEntity } from '../database/entities/prompt-template.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { JwtPayload } from '../auth/strategies/jwt.strategy';
import { PermissionGuard, RequirePermission } from './permissions/permission.guard';
import { AdminAuditLogService } from './audit/admin-audit-log.service';

class UpdatePromptTemplateDto {
  @ApiProperty({ required: false }) @IsOptional() @IsString() label?: string;
  @ApiProperty({ required: false }) @IsOptional() @IsString() description?: string | null;
  @ApiProperty({ required: false }) @IsOptional() @IsString() template?: string;
  @ApiProperty({ required: false }) @IsOptional() @IsBoolean() is_active?: boolean;
}

/**
 * Edits the prompt templates used by the AI orchestration layer. Templates
 * live in `vl_prompt_templates` with one row per kind. The PromptBuilderService
 * reads the active row at request time, so changes take effect immediately
 * for the next chat call — no server restart needed.
 */
@ApiTags('Admin / Prompt templates')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionGuard)
@Controller('admin/prompt-templates')
export class AdminPromptTemplatesController {
  constructor(
    @InjectRepository(PromptTemplateEntity)
    private readonly templates: Repository<PromptTemplateEntity>,
    private readonly audit: AdminAuditLogService,
    private readonly dataSource: DataSource,
  ) {}

  @Get()
  @RequirePermission('prompts.view')
  @ApiOperation({ summary: 'List all prompt templates' })
  async list() {
    return this.templates.find({ order: { kind: 'ASC' } });
  }

  @Get(':kind')
  @RequirePermission('prompts.view')
  @ApiOperation({ summary: 'Get one prompt template by kind' })
  async get(@Param('kind') kind: string) {
    const tpl = await this.templates.findOne({ where: { kind: kind as never } });
    if (!tpl) throw new NotFoundException({ i18nKey: 'prompt_template.not_found' });
    return tpl;
  }

  @Patch(':kind')
  @RequirePermission('prompts.edit')
  @ApiOperation({ summary: 'Update prompt template fields (label/template/is_active)' })
  async update(
    @CurrentUser() user: JwtPayload,
    @Param('kind') kind: string,
    @Body() dto: UpdatePromptTemplateDto,
  ) {
    return this.dataSource.transaction(async (em) => {
      const repo = em.getRepository(PromptTemplateEntity);
      const tpl = await repo.findOne({ where: { kind: kind as never } });
      if (!tpl) throw new NotFoundException({ i18nKey: 'prompt_template.not_found' });

      const before: Record<string, unknown> = {};
      const after: Record<string, unknown> = {};
      if (dto.label !== undefined && dto.label !== tpl.label) {
        before.label = tpl.label;
        after.label = dto.label;
        tpl.label = dto.label;
      }
      if (dto.description !== undefined) {
        const next = dto.description ?? null;
        if (next !== tpl.description) {
          before.description = tpl.description;
          after.description = next;
          tpl.description = next;
        }
      }
      if (dto.template !== undefined && dto.template !== tpl.template) {
        before.template = tpl.template;
        after.template = dto.template;
        tpl.template = dto.template;
      }
      if (dto.is_active !== undefined && dto.is_active !== tpl.is_active) {
        before.is_active = tpl.is_active;
        after.is_active = dto.is_active;
        tpl.is_active = dto.is_active;
      }

      const saved = await repo.save(tpl);
      if (Object.keys(after).length > 0) {
        await this.audit.record(
          {
            actorId: user.sub,
            action: 'prompt_template.update',
            targetType: 'prompt_template',
            targetId: kind,
            oldValue: before,
            newValue: after,
          },
          em,
        );
      }
      return saved;
    });
  }
}
