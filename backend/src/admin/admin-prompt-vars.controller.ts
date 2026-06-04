import {
  Body,
  Controller,
  Delete,
  Get,
  NotFoundException,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ApiBearerAuth, ApiProperty, ApiTags } from '@nestjs/swagger';
import { IsBoolean, IsInt, IsOptional, IsString } from 'class-validator';
import { PromptVarEntity } from '../database/entities/prompt-var.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  PermissionGuard,
  RequirePermission,
} from './permissions/permission.guard';

class CreatePromptVarDto {
  @ApiProperty() @IsString() key!: string;
  @ApiProperty() @IsString() label!: string;
  @ApiProperty({ required: false, nullable: true })
  @IsOptional()
  @IsString()
  description?: string | null;
  @ApiProperty({ required: false, nullable: true })
  @IsOptional()
  @IsString()
  global_value?: string | null;
  @ApiProperty({ required: false })
  @IsOptional()
  @IsBoolean()
  scenario_overridable?: boolean;
  @ApiProperty({ required: false })
  @IsOptional()
  @IsInt()
  sort_order?: number;
}

class UpdatePromptVarDto {
  @ApiProperty({ required: false }) @IsOptional() @IsString() label?: string;
  @ApiProperty({ required: false, nullable: true })
  @IsOptional()
  @IsString()
  description?: string | null;
  @ApiProperty({ required: false, nullable: true })
  @IsOptional()
  @IsString()
  global_value?: string | null;
  @ApiProperty({ required: false })
  @IsOptional()
  @IsBoolean()
  scenario_overridable?: boolean;
  @ApiProperty({ required: false })
  @IsOptional()
  @IsInt()
  sort_order?: number;
}

@ApiTags('Admin / Prompt Variables')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionGuard)
@Controller('admin/prompt-vars')
export class AdminPromptVarsController {
  constructor(
    @InjectRepository(PromptVarEntity)
    private readonly repo: Repository<PromptVarEntity>,
  ) {}

  @Get()
  @RequirePermission('prompts.view')
  list() {
    return this.repo.find({ order: { sort_order: 'ASC', key: 'ASC' } });
  }

  @Post()
  @RequirePermission('prompts.edit')
  create(@Body() dto: CreatePromptVarDto) {
    return this.repo.save(
      this.repo.create({
        key: dto.key,
        label: dto.label,
        description: dto.description ?? null,
        global_value: dto.global_value ?? null,
        scenario_overridable: dto.scenario_overridable ?? true,
        sort_order: dto.sort_order ?? 0,
      }),
    );
  }

  @Patch(':key')
  @RequirePermission('prompts.edit')
  async update(@Param('key') key: string, @Body() dto: UpdatePromptVarDto) {
    const row = await this.repo.findOne({ where: { key } });
    if (!row) throw new NotFoundException();
    Object.assign(row, dto);
    return this.repo.save(row);
  }

  @Delete(':key')
  @RequirePermission('prompts.edit')
  async remove(@Param('key') key: string) {
    const row = await this.repo.findOne({ where: { key } });
    if (!row) throw new NotFoundException();
    await this.repo.delete({ key });
    return { ok: true };
  }
}
