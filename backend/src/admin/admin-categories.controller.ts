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
  UseGuards,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, EntityManager, Repository } from 'typeorm';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiProperty,
  ApiTags,
} from '@nestjs/swagger';
import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  Length,
  Matches,
  Min,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { CategoryEntity } from '../database/entities/category.entity';
import { ScenarioEntity, type I18nText } from '../database/entities/scenario.entity';
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

class CreateCategoryDto {
  /**
   * URL-safe slug. Immutable after create so the denormalized
   * `vl_scenarios.category` column can never drift from the FK target.
   */
  @ApiProperty()
  @IsString()
  @Length(2, 50)
  @Matches(/^[a-z0-9_-]+$/, { message: 'slug must be lowercase a-z, 0-9, _ or -' })
  slug!: string;

  @ApiProperty({ type: I18nTextDto })
  @ValidateNested()
  @Type(() => I18nTextDto)
  title!: I18nTextDto;

  @ApiProperty({ type: I18nTextDto, required: false })
  @ValidateNested()
  @Type(() => I18nTextDto)
  @IsOptional()
  description?: I18nTextDto;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsInt()
  @Min(0)
  order_index?: number;
}

class UpdateCategoryDto {
  /**
   * Title only — slug is intentionally NOT in this DTO. Renaming slugs
   * would invalidate the denormalized cache on every scenario row.
   */
  @ApiProperty({ type: I18nTextDto, required: false })
  @ValidateNested()
  @Type(() => I18nTextDto)
  @IsOptional()
  title?: I18nTextDto;

  @ApiProperty({ type: I18nTextDto, required: false })
  @ValidateNested()
  @Type(() => I18nTextDto)
  @IsOptional()
  description?: I18nTextDto | null;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsInt()
  @Min(0)
  order_index?: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsBoolean()
  is_active?: boolean;
}

/**
 * Admin CRUD for scenario categories. Categories are the source-of-truth
 * for the picker shown in `/admin/scenarios/new` and the filter chips in
 * the Flutter scenarios screen.
 *
 * Soft-delete (set `is_active = false`) is preferred over hard-delete: the
 * FK on `vl_scenarios.category_id` is `ON DELETE RESTRICT`, so any DELETE
 * against a category still referenced by a scenario returns 409 instead
 * of cascading. Authors should reassign scenarios first.
 */
@ApiTags('Admin / Categories')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionGuard)
@Controller('admin/categories')
export class AdminCategoriesController {
  constructor(
    @InjectRepository(CategoryEntity)
    private readonly categories: Repository<CategoryEntity>,
    private readonly audit: AdminAuditLogService,
    private readonly dataSource: DataSource,
  ) {}

  @Get()
  @RequirePermission('categories.view')
  @ApiOperation({ summary: 'List all categories (including inactive)' })
  async list() {
    return this.categories.find({
      order: { order_index: 'ASC', slug: 'ASC' },
    });
  }

  @Get(':id')
  @RequirePermission('categories.view')
  async get(@Param('id') id: string) {
    return this.findById(id);
  }

  @Post()
  @RequirePermission('categories.edit')
  async create(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateCategoryDto,
  ) {
    return this.dataSource.transaction(async (em) => {
      const repo = em.getRepository(CategoryEntity);
      const existing = await repo.findOne({ where: { slug: dto.slug } });
      if (existing) {
        throw new BadRequestException({ i18nKey: 'category.slug_taken' });
      }
      const c = repo.create({
        slug: dto.slug,
        title: dto.title,
        description: dto.description ?? null,
        order_index: dto.order_index ?? 0,
        is_active: true,
      });
      const saved = await repo.save(c);
      await this.audit.record(
        {
          actorId: user.sub,
          action: 'category.create',
          targetType: 'category',
          targetId: saved.id,
          newValue: {
            slug: saved.slug,
            title: saved.title,
            order_index: saved.order_index,
          },
        },
        em,
      );
      return saved;
    });
  }

  @Patch(':id')
  @RequirePermission('categories.edit')
  async update(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: UpdateCategoryDto,
  ) {
    return this.dataSource.transaction(async (em) => {
      const repo = em.getRepository(CategoryEntity);
      const c = await this.findById(id, em);
      const before: Record<string, unknown> = {};
      const after: Record<string, unknown> = {};
      for (const [k, v] of Object.entries(dto) as [keyof UpdateCategoryDto, unknown][]) {
        if (v === undefined) continue;
        const current = (c as unknown as Record<string, unknown>)[k as string];
        if (deepEqual(current, v)) continue;
        before[k as string] = current;
        after[k as string] = v;
      }
      if (dto.title !== undefined) c.title = dto.title;
      if (dto.description !== undefined) c.description = dto.description ?? null;
      if (dto.order_index !== undefined) c.order_index = dto.order_index;
      if (dto.is_active !== undefined) c.is_active = dto.is_active;
      const saved = await repo.save(c);
      if (Object.keys(after).length > 0) {
        await this.audit.record(
          {
            actorId: user.sub,
            action: 'category.update',
            targetType: 'category',
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

  /**
   * Hard-delete only when no scenario still references the category.
   * The FK constraint enforces this at the DB level; we check first to
   * return a clean 409 with a usable message instead of a raw Postgres
   * constraint error.
   */
  @Delete(':id')
  @RequirePermission('categories.delete')
  async remove(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    await this.dataSource.transaction(async (em) => {
      const repo = em.getRepository(CategoryEntity);
      const c = await this.findById(id, em);
      const inUse = await em
        .getRepository(ScenarioEntity)
        .count({ where: { category_id: id } });
      if (inUse > 0) {
        throw new BadRequestException({
          i18nKey: 'category.in_use',
          inUseCount: inUse,
        });
      }
      await repo.delete({ id });
      await this.audit.record(
        {
          actorId: user.sub,
          action: 'category.delete',
          targetType: 'category',
          targetId: id,
          oldValue: { slug: c.slug, title: c.title, is_active: c.is_active },
        },
        em,
      );
    });
    return { ok: true };
  }

  private async findById(
    id: string,
    em?: EntityManager,
  ): Promise<CategoryEntity> {
    const repo = em ? em.getRepository(CategoryEntity) : this.categories;
    const c = await repo.findOne({ where: { id } });
    if (!c) throw new NotFoundException({ i18nKey: 'category.not_found' });
    return c;
  }
}

function deepEqual(a: unknown, b: unknown): boolean {
  if (a === b) return true;
  if (a === null || b === null) return false;
  if (typeof a !== 'object' || typeof b !== 'object') return false;
  return JSON.stringify(a) === JSON.stringify(b);
}
