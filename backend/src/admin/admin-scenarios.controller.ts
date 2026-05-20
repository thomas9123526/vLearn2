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
import { DataSource, EntityManager, Repository } from 'typeorm';
import { ApiBearerAuth, ApiProperty, ApiTags } from '@nestjs/swagger';
import {
  IsArray,
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
  type ScenarioObjective,
  type KeyPhrase,
} from '../database/entities/scenario.entity';
import { CategoryEntity } from '../database/entities/category.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { JwtPayload } from '../auth/strategies/jwt.strategy';
import { PermissionGuard, RequirePermission } from './permissions/permission.guard';
import { AdminAuditLogService } from './audit/admin-audit-log.service';

class I18nTextDto implements I18nText {
  @ApiProperty() @IsString() en!: string;
  @ApiProperty({ required: false }) @IsString() @IsOptional() ko?: string;
  @ApiProperty({ required: false }) @IsString() @IsOptional() zh?: string;
}

class CreateScenarioDto {
  @ApiProperty() @IsString() slug!: string;
  /** Category slug — resolved server-side to category_id. Must reference an active row in vl_categories. */
  @ApiProperty() @IsString() category!: string;
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
  @ApiProperty({ required: false }) @IsOptional() @IsString() category?: string;
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
    private readonly audit: AdminAuditLogService,
    private readonly dataSource: DataSource,
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
    return this.dataSource.transaction(async (em) => {
      const repo = em.getRepository(ScenarioEntity);
      const existing = await repo.findOne({ where: { slug: dto.slug } });
      if (existing) throw new BadRequestException({ i18nKey: 'scenario.slug_taken' });
      const cat = await this.resolveCategoryBySlug(dto.category, em);
      const s = repo.create({
        slug: dto.slug,
        category: cat.slug,
        category_id: cat.id,
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
      const saved = await repo.save(s);
      await this.audit.record(
        {
          actorId: user.sub,
          action: 'scenario.create',
          targetType: 'scenario',
          targetId: saved.id,
          newValue: {
            slug: saved.slug,
            category: saved.category,
            difficulty: saved.difficulty,
            status: saved.status,
          },
        },
        em,
      );
      return saved;
    });
  }

  @Patch(':id')
  @RequirePermission('scenarios.edit')
  async update(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: UpdateScenarioDto,
  ) {
    return this.dataSource.transaction(async (em) => {
      const repo = em.getRepository(ScenarioEntity);
      const s = await this.findById(id, em);
      const before: Record<string, unknown> = {};
      const after: Record<string, unknown> = {};
      // Resolve slug → category before diffing so the audit log carries the
      // category slug that the admin actually typed, not the FK uuid.
      let nextCategoryId: string | undefined;
      if (dto.category !== undefined && dto.category !== s.category) {
        const cat = await this.resolveCategoryBySlug(dto.category, em);
        nextCategoryId = cat.id;
      }
      for (const [k, v] of Object.entries(dto) as [keyof UpdateScenarioDto, unknown][]) {
        if (v === undefined) continue;
        const current = (s as unknown as Record<string, unknown>)[k as string];
        if (deepEqual(current, v)) continue;
        before[k as string] = current;
        after[k as string] = v;
      }
      Object.assign(s, dto);
      if (nextCategoryId) s.category_id = nextCategoryId;
      const saved = await repo.save(s);
      if (Object.keys(after).length > 0) {
        await this.audit.record(
          {
            actorId: user.sub,
            action: 'scenario.update',
            targetType: 'scenario',
            targetId: id,
            oldValue: before,
            newValue: after,
          },
          em,
        );
      }
      return saved;
    });
  }

  @Post(':id/publish')
  @RequirePermission('scenarios.edit')
  async publish(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.dataSource.transaction(async (em) => {
      const repo = em.getRepository(ScenarioEntity);
      const s = await this.findById(id, em);
      const oldStatus = s.status;
      s.status = 'published';
      s.published_at ??= new Date();
      const saved = await repo.save(s);
      await this.audit.record(
        {
          actorId: user.sub,
          action: 'scenario.publish',
          targetType: 'scenario',
          targetId: id,
          oldValue: { status: oldStatus },
          newValue: { status: 'published' },
        },
        em,
      );
      return saved;
    });
  }

  @Post(':id/archive')
  @RequirePermission('scenarios.edit')
  async archive(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.dataSource.transaction(async (em) => {
      const repo = em.getRepository(ScenarioEntity);
      const s = await this.findById(id, em);
      const oldStatus = s.status;
      s.status = 'archived';
      const saved = await repo.save(s);
      await this.audit.record(
        {
          actorId: user.sub,
          action: 'scenario.archive',
          targetType: 'scenario',
          targetId: id,
          oldValue: { status: oldStatus },
          newValue: { status: 'archived' },
        },
        em,
      );
      return saved;
    });
  }

  @Delete(':id')
  @RequirePermission('scenarios.delete')
  async remove(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    await this.dataSource.transaction(async (em) => {
      const repo = em.getRepository(ScenarioEntity);
      const s = await repo.findOne({ where: { id } });
      if (!s) throw new NotFoundException({ i18nKey: 'scenario.not_found' });
      await repo.delete({ id });
      await this.audit.record(
        {
          actorId: user.sub,
          action: 'scenario.delete',
          targetType: 'scenario',
          targetId: id,
          oldValue: { slug: s.slug, status: s.status },
        },
        em,
      );
    });
    return { ok: true };
  }

  @Post(':id/image')
  @RequirePermission('scenarios.upload_image')
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 5 * 1024 * 1024 } }))
  async uploadImage(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @UploadedFile() file: { originalname: string; buffer: Buffer; mimetype: string },
  ) {
    if (!file) throw new BadRequestException({ i18nKey: 'upload.no_file' });
    if (!/^image\/(jpe?g|png|webp)$/.test(file.mimetype)) {
      throw new BadRequestException({ i18nKey: 'upload.bad_mime' });
    }
    const uploadsDir = process.env.UPLOADS_DIR ?? path.resolve('uploads');
    const dir = path.join(uploadsDir, 'scenarios');
    fs.mkdirSync(dir, { recursive: true });
    const ext = (file.originalname.split('.').pop() ?? 'jpg').toLowerCase();
    const filename = `${id}.${ext}`;
    const abs = path.join(dir, filename);
    fs.writeFileSync(abs, file.buffer);

    return this.dataSource.transaction(async (em) => {
      const repo = em.getRepository(ScenarioEntity);
      const s = await this.findById(id, em);
      const oldKey = s.image_storage_key;
      s.image_storage_key = path.posix.join('scenarios', filename);
      s.image_url = `/uploads/${s.image_storage_key}`;
      await repo.save(s);
      await this.audit.record(
        {
          actorId: user.sub,
          action: 'scenario.upload_image',
          targetType: 'scenario',
          targetId: id,
          oldValue: { image_storage_key: oldKey },
          newValue: { image_storage_key: s.image_storage_key },
        },
        em,
      );
      return { image_url: s.image_url };
    });
  }

  private async findById(id: string, em?: EntityManager): Promise<ScenarioEntity> {
    const repo = em ? em.getRepository(ScenarioEntity) : this.scenarios;
    const s = await repo.findOne({ where: { id } });
    if (!s) throw new NotFoundException({ i18nKey: 'scenario.not_found' });
    return s;
  }

  private async resolveCategoryBySlug(
    slug: string,
    em: EntityManager,
  ): Promise<CategoryEntity> {
    const cat = await em
      .getRepository(CategoryEntity)
      .findOne({ where: { slug } });
    if (!cat || !cat.is_active) {
      throw new BadRequestException({ i18nKey: 'scenario.category_invalid' });
    }
    return cat;
  }
}

/**
 * Cheap value-equality used by audit diffing — we only need to know whether
 * to record a field, so JSON-roundtrip equality is fine. Order-sensitive for
 * arrays (matches user intent: reordering `objectives` IS a meaningful edit).
 */
function deepEqual(a: unknown, b: unknown): boolean {
  if (a === b) return true;
  if (a === null || b === null) return false;
  if (typeof a !== 'object' || typeof b !== 'object') return false;
  return JSON.stringify(a) === JSON.stringify(b);
}
