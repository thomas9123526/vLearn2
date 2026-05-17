import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  NotFoundException,
  Param,
  Patch,
  Post,
  Query,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ApiBearerAuth, ApiOperation, ApiProperty, ApiTags } from '@nestjs/swagger';
import {
  IsArray,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Min,
  Max,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import * as fs from 'fs';
import * as path from 'path';
import {
  ScenarioEntity,
  type I18nText,
  type ScenarioCategory,
  type ScenarioObjective,
  type KeyPhrase,
} from '../database/entities/scenario.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { JwtPayload } from '../auth/strategies/jwt.strategy';
import { PermissionGuard, RequirePermission } from './permissions/permission.guard';

class I18nTextDto implements I18nText {
  @ApiProperty() @IsString() en!: string;
  @ApiProperty({ required: false }) @IsString() @IsOptional() ko?: string;
  @ApiProperty({ required: false }) @IsString() @IsOptional() zh?: string;
}

class CreateScenarioDto {
  @ApiProperty() @IsString() slug!: string;
  @ApiProperty() @IsString() @IsIn(['travel', 'business', 'social', 'daily'])
  category!: ScenarioCategory;
  @ApiProperty() @IsInt() @Min(1) @Max(5) difficulty!: number;
  @ApiProperty({ type: I18nTextDto }) @ValidateNested() @Type(() => I18nTextDto) title!: I18nTextDto;
  @ApiProperty({ type: I18nTextDto }) @ValidateNested() @Type(() => I18nTextDto) description!: I18nTextDto;
  @ApiProperty({ type: I18nTextDto }) @ValidateNested() @Type(() => I18nTextDto) scene_description!: I18nTextDto;
  @ApiProperty({ type: I18nTextDto }) @ValidateNested() @Type(() => I18nTextDto) user_role!: I18nTextDto;
  @ApiProperty({ type: I18nTextDto }) @ValidateNested() @Type(() => I18nTextDto) tutor_role!: I18nTextDto;
  @ApiProperty({ type: [Object] }) @IsArray() objectives!: ScenarioObjective[];
  @ApiProperty({ type: [Object] }) @IsArray() key_phrases!: KeyPhrase[];
  @ApiProperty({ required: false }) @IsOptional() @IsInt() @Min(1) estimated_minutes?: number;
  @ApiProperty({ required: false }) @IsOptional() @IsInt() @Min(0) xp_reward?: number;
}

class UpdateScenarioDto {
  @ApiProperty({ required: false }) @IsOptional() @IsString() slug?: string;
  @ApiProperty({ required: false }) @IsOptional() @IsString() @IsIn(['travel', 'business', 'social', 'daily'])
  category?: ScenarioCategory;
  @ApiProperty({ required: false }) @IsOptional() @IsInt() @Min(1) @Max(5) difficulty?: number;
  @ApiProperty({ type: I18nTextDto, required: false }) @ValidateNested() @Type(() => I18nTextDto) @IsOptional() title?: I18nTextDto;
  @ApiProperty({ type: I18nTextDto, required: false }) @ValidateNested() @Type(() => I18nTextDto) @IsOptional() description?: I18nTextDto;
  @ApiProperty({ type: I18nTextDto, required: false }) @ValidateNested() @Type(() => I18nTextDto) @IsOptional() scene_description?: I18nTextDto;
  @ApiProperty({ type: I18nTextDto, required: false }) @ValidateNested() @Type(() => I18nTextDto) @IsOptional() user_role?: I18nTextDto;
  @ApiProperty({ type: I18nTextDto, required: false }) @ValidateNested() @Type(() => I18nTextDto) @IsOptional() tutor_role?: I18nTextDto;
  @ApiProperty({ required: false }) @IsOptional() @IsArray() objectives?: ScenarioObjective[];
  @ApiProperty({ required: false }) @IsOptional() @IsArray() key_phrases?: KeyPhrase[];
  @ApiProperty({ required: false }) @IsOptional() @IsInt() @Min(1) estimated_minutes?: number;
  @ApiProperty({ required: false }) @IsOptional() @IsInt() @Min(0) xp_reward?: number;
}

/**
 * Admin CRUD for scenarios. Image upload writes to `<UPLOADS_DIR>/scenarios/`
 * (configurable, default `./uploads/`) and stores the relative path in
 * `image_storage_key`. `image_url` is set to `/uploads/scenarios/<file>` so
 * the static-file middleware in main.ts can serve it directly.
 */
@ApiTags('Admin / Scenarios')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionGuard)
@Controller('admin/scenarios')
export class AdminScenariosController {
  constructor(
    @InjectRepository(ScenarioEntity)
    private readonly scenarios: Repository<ScenarioEntity>,
  ) {}

  @Get()
  @RequirePermission('scenarios.view')
  async list(@Query('status') status?: string, @Query('q') q?: string) {
    const qb = this.scenarios.createQueryBuilder('s').orderBy('s.created_at', 'DESC');
    if (status) qb.andWhere('s.status = :s', { s: status });
    if (q) qb.andWhere(`s.title ->> 'en' ILIKE :q`, { q: `%${q}%` });
    return qb.getMany();
  }

  @Get(':id')
  @RequirePermission('scenarios.view')
  async get(@Param('id') id: string) {
    const s = await this.scenarios.findOne({ where: { id } });
    if (!s) throw new NotFoundException({ i18nKey: 'scenario.not_found' });
    return s;
  }

  @Post()
  @RequirePermission('scenarios.edit')
  async create(@CurrentUser() user: JwtPayload, @Body() dto: CreateScenarioDto) {
    const existing = await this.scenarios.findOne({ where: { slug: dto.slug } });
    if (existing) throw new BadRequestException({ i18nKey: 'scenario.slug_taken' });
    const s = this.scenarios.create({
      slug: dto.slug,
      category: dto.category,
      difficulty: dto.difficulty,
      title: dto.title,
      description: dto.description,
      scene_description: dto.scene_description,
      user_role: dto.user_role,
      tutor_role: dto.tutor_role,
      objectives: dto.objectives,
      key_phrases: dto.key_phrases,
      estimated_minutes: dto.estimated_minutes ?? 5,
      xp_reward: dto.xp_reward ?? 50,
      author_id: user.sub,
      status: 'draft',
    });
    return this.scenarios.save(s);
  }

  @Patch(':id')
  @RequirePermission('scenarios.edit')
  async update(@Param('id') id: string, @Body() dto: UpdateScenarioDto) {
    const s = await this.get(id);
    Object.assign(s, dto);
    return this.scenarios.save(s);
  }

  @Post(':id/publish')
  @RequirePermission('scenarios.edit')
  async publish(@Param('id') id: string) {
    const s = await this.get(id);
    s.status = 'published';
    s.published_at ??= new Date();
    return this.scenarios.save(s);
  }

  @Post(':id/archive')
  @RequirePermission('scenarios.edit')
  async archive(@Param('id') id: string) {
    const s = await this.get(id);
    s.status = 'archived';
    return this.scenarios.save(s);
  }

  @Delete(':id')
  @RequirePermission('scenarios.delete')
  async remove(@Param('id') id: string) {
    const result = await this.scenarios.delete({ id });
    if (result.affected === 0) {
      throw new NotFoundException({ i18nKey: 'scenario.not_found' });
    }
    return { ok: true };
  }

  @Post(':id/image')
  @RequirePermission('scenarios.upload_image')
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 5 * 1024 * 1024 } }))
  async uploadImage(
    @Param('id') id: string,
    @UploadedFile() file: { originalname: string; buffer: Buffer; mimetype: string },
  ) {
    if (!file) throw new BadRequestException({ i18nKey: 'upload.no_file' });
    if (!/^image\/(jpe?g|png|webp)$/.test(file.mimetype)) {
      throw new BadRequestException({ i18nKey: 'upload.bad_mime' });
    }
    const s = await this.get(id);
    const uploadsDir = process.env.UPLOADS_DIR ?? path.resolve('uploads');
    const dir = path.join(uploadsDir, 'scenarios');
    fs.mkdirSync(dir, { recursive: true });
    const ext = (file.originalname.split('.').pop() ?? 'jpg').toLowerCase();
    const filename = `${id}.${ext}`;
    const abs = path.join(dir, filename);
    fs.writeFileSync(abs, file.buffer);
    s.image_storage_key = path.posix.join('scenarios', filename);
    s.image_url = `/uploads/${s.image_storage_key}`;
    await this.scenarios.save(s);
    return { image_url: s.image_url };
  }
}
