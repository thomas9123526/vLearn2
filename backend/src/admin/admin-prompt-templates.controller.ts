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
import { Repository } from 'typeorm';
import { ApiBearerAuth, ApiOperation, ApiProperty, ApiTags } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsString } from 'class-validator';
import { PromptTemplateEntity } from '../database/entities/prompt-template.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionGuard, RequirePermission } from './permissions/permission.guard';

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
    @Param('kind') kind: string,
    @Body() dto: UpdatePromptTemplateDto,
  ) {
    const tpl = await this.templates.findOne({ where: { kind: kind as never } });
    if (!tpl) throw new NotFoundException({ i18nKey: 'prompt_template.not_found' });
    if (dto.label !== undefined) tpl.label = dto.label;
    if (dto.description !== undefined) tpl.description = dto.description ?? null;
    if (dto.template !== undefined) tpl.template = dto.template;
    if (dto.is_active !== undefined) tpl.is_active = dto.is_active;
    return this.templates.save(tpl);
  }
}
