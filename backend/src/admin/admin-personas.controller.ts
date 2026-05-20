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
import { ApiBearerAuth, ApiOperation, ApiProperty, ApiTags } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsHexColor,
  IsIn,
  IsOptional,
  IsString,
  Length,
} from 'class-validator';

/** Treat empty form strings as null so @IsOptional skips @Length on PATCH. */
const emptyToNull = ({ value }: { value: unknown }) =>
  value === '' || value === undefined ? null : value;
import * as fs from 'fs';
import * as path from 'path';
import { PersonaEntity } from '../database/entities/persona.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { JwtPayload } from '../auth/strategies/jwt.strategy';
import { PermissionGuard, RequirePermission } from './permissions/permission.guard';
import { AdminAuditLogService } from './audit/admin-audit-log.service';

/**
 * Admin CRUD for personas (a.k.a. AI tutors).
 *
 * Image upload writes to `<UPLOADS_DIR>/personas/<id>.<ext>` and stores the
 * relative path in `image_storage_key`; `image_url` is set to
 * `/uploads/personas/<file>` so the static-file middleware in main.ts can
 * serve it directly to the Flutter app.
 *
 * Deletion is **soft** by toggling `is_active`. We don't hard-delete because
 * `conversation_sessions` and `user_progress` reference persona_id, and we
 * want to preserve historical attribution even after a tutor is retired.
 */
class CreatePersonaDto {
  @ApiProperty() @IsString() @Length(2, 50) slug!: string;
  @ApiProperty() @IsString() @Length(1, 50) name!: string;
  @ApiProperty() @IsString() @Length(1, 100) accent!: string;
  @ApiProperty() @IsString() @Length(1, 100) style!: string;
  @ApiProperty({ type: [String] }) @IsArray() specialties!: string[];
  @ApiProperty() @IsHexColor() gradient_from!: string;
  @ApiProperty() @IsHexColor() gradient_to!: string;
  @ApiProperty({ required: false })
  @Transform(emptyToNull)
  @IsOptional()
  @IsString()
  @Length(1, 100)
  rive_asset?: string | null;
  @ApiProperty({ required: false })
  @Transform(emptyToNull)
  @IsOptional()
  @IsString()
  @Length(1, 100)
  voice_id?: string | null;
  @ApiProperty({ required: false, enum: ['female', 'male', 'neutral'] })
  @IsOptional()
  @IsIn(['female', 'male', 'neutral'])
  gender?: 'female' | 'male' | 'neutral';
  @ApiProperty({ required: false }) @IsOptional() @IsBoolean() is_active?: boolean;
}

class UpdatePersonaDto {
  @ApiProperty({ required: false }) @IsOptional() @IsString() @Length(2, 50) slug?: string;
  @ApiProperty({ required: false }) @IsOptional() @IsString() @Length(1, 50) name?: string;
  @ApiProperty({ required: false }) @IsOptional() @IsString() @Length(1, 100) accent?: string;
  @ApiProperty({ required: false }) @IsOptional() @IsString() @Length(1, 100) style?: string;
  @ApiProperty({ required: false, type: [String] }) @IsOptional() @IsArray() specialties?: string[];
  @ApiProperty({ required: false }) @IsOptional() @IsHexColor() gradient_from?: string;
  @ApiProperty({ required: false }) @IsOptional() @IsHexColor() gradient_to?: string;
  @ApiProperty({ required: false })
  @Transform(emptyToNull)
  @IsOptional()
  @IsString()
  @Length(1, 100)
  rive_asset?: string | null;
  @ApiProperty({ required: false })
  @Transform(emptyToNull)
  @IsOptional()
  @IsString()
  @Length(1, 100)
  voice_id?: string | null;
  @ApiProperty({ required: false, enum: ['female', 'male', 'neutral'] })
  @IsOptional()
  @IsIn(['female', 'male', 'neutral'])
  gender?: 'female' | 'male' | 'neutral';
  @ApiProperty({ required: false }) @IsOptional() @IsBoolean() is_active?: boolean;
}

@ApiTags('Admin / Personas')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionGuard)
@Controller('admin/personas')
export class AdminPersonasController {
  constructor(
    @InjectRepository(PersonaEntity)
    private readonly personas: Repository<PersonaEntity>,
    private readonly audit: AdminAuditLogService,
    private readonly dataSource: DataSource,
  ) {}

  @Get()
  @RequirePermission('personas.edit')
  @ApiOperation({ summary: 'List all personas (including inactive)' })
  async list(@Query('q') q?: string) {
    const qb = this.personas.createQueryBuilder('p').orderBy('p.name', 'ASC');
    if (q) qb.andWhere('p.name ILIKE :q OR p.slug ILIKE :q', { q: `%${q}%` });
    return qb.getMany();
  }

  @Get(':id')
  @RequirePermission('personas.edit')
  async get(@Param('id') id: string) {
    return this.findById(id);
  }

  @Post()
  @RequirePermission('personas.edit')
  async create(@CurrentUser() user: JwtPayload, @Body() dto: CreatePersonaDto) {
    return this.dataSource.transaction(async (em) => {
      const repo = em.getRepository(PersonaEntity);
      const existing = await repo.findOne({ where: { slug: dto.slug } });
      if (existing) {
        throw new BadRequestException({ i18nKey: 'persona.slug_taken' });
      }
      const p = repo.create({
        slug: dto.slug,
        name: dto.name,
        accent: dto.accent,
        style: dto.style,
        specialties: dto.specialties,
        gradient_from: dto.gradient_from,
        gradient_to: dto.gradient_to,
        rive_asset: dto.rive_asset ?? null,
        voice_id: dto.voice_id ?? null,
        gender: dto.gender ?? 'neutral',
        is_active: dto.is_active ?? true,
      });
      const saved = await repo.save(p);
      await this.audit.record(
        {
          actorId: user.sub,
          action: 'persona.create',
          targetType: 'persona',
          targetId: saved.id,
          newValue: {
            slug: saved.slug,
            name: saved.name,
            is_active: saved.is_active,
          },
        },
        em,
      );
      return saved;
    });
  }

  @Patch(':id')
  @RequirePermission('personas.edit')
  async update(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: UpdatePersonaDto,
  ) {
    return this.dataSource.transaction(async (em) => {
      const repo = em.getRepository(PersonaEntity);
      const p = await this.findById(id, em);
      const before: Record<string, unknown> = {};
      const after: Record<string, unknown> = {};
      for (const [k, v] of Object.entries(dto) as [keyof UpdatePersonaDto, unknown][]) {
        if (v === undefined) continue;
        const current = (p as unknown as Record<string, unknown>)[k as string];
        if (deepEqual(current, v)) continue;
        before[k as string] = current;
        after[k as string] = v;
      }
      Object.assign(p, dto);
      const saved = await repo.save(p);
      if (Object.keys(after).length > 0) {
        await this.audit.record(
          {
            actorId: user.sub,
            action: 'persona.update',
            targetType: 'persona',
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
   * Soft-delete. We never hard-delete personas because historical
   * conversation sessions reference them.
   */
  @Delete(':id')
  @RequirePermission('personas.edit')
  async deactivate(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    await this.dataSource.transaction(async (em) => {
      const repo = em.getRepository(PersonaEntity);
      const p = await this.findById(id, em);
      if (!p.is_active) return;
      p.is_active = false;
      await repo.save(p);
      await this.audit.record(
        {
          actorId: user.sub,
          action: 'persona.deactivate',
          targetType: 'persona',
          targetId: id,
          oldValue: { is_active: true },
          newValue: { is_active: false },
        },
        em,
      );
    });
    return { ok: true };
  }

  @Post(':id/restore')
  @RequirePermission('personas.edit')
  async restore(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    await this.dataSource.transaction(async (em) => {
      const repo = em.getRepository(PersonaEntity);
      const p = await this.findById(id, em);
      if (p.is_active) return;
      p.is_active = true;
      await repo.save(p);
      await this.audit.record(
        {
          actorId: user.sub,
          action: 'persona.restore',
          targetType: 'persona',
          targetId: id,
          oldValue: { is_active: false },
          newValue: { is_active: true },
        },
        em,
      );
    });
    return { ok: true };
  }

  /**
   * Hero / portrait image. Same pattern as scenarios:
   *   - reject anything that isn't jpeg/png/webp under 5 MB
   *   - write to `<UPLOADS_DIR>/personas/<id>.<ext>`
   *   - store the relative path in image_storage_key
   *   - mirror the public URL into image_url so the Flutter client doesn't
   *     have to know about UPLOADS_DIR
   */
  @Post(':id/image')
  @RequirePermission('personas.edit')
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
    // Disk write happens before the DB row update to keep the controller
    // simple; if either the DB save or the audit insert fails the orphan
    // file is harmless (next upload to the same id overwrites it).
    const uploadsDir = process.env.UPLOADS_DIR ?? path.resolve('uploads');
    const dir = path.join(uploadsDir, 'personas');
    fs.mkdirSync(dir, { recursive: true });
    const ext = (file.originalname.split('.').pop() ?? 'jpg').toLowerCase();
    const filename = `${id}.${ext}`;
    const abs = path.join(dir, filename);
    fs.writeFileSync(abs, file.buffer);

    return this.dataSource.transaction(async (em) => {
      const repo = em.getRepository(PersonaEntity);
      const p = await this.findById(id, em);
      const oldKey = p.image_storage_key;
      p.image_storage_key = path.posix.join('personas', filename);
      p.image_url = `/uploads/${p.image_storage_key}`;
      await repo.save(p);
      await this.audit.record(
        {
          actorId: user.sub,
          action: 'persona.upload_image',
          targetType: 'persona',
          targetId: id,
          oldValue: { image_storage_key: oldKey },
          newValue: { image_storage_key: p.image_storage_key },
        },
        em,
      );
      return { image_url: p.image_url };
    });
  }

  private async findById(id: string, em?: EntityManager): Promise<PersonaEntity> {
    const repo = em ? em.getRepository(PersonaEntity) : this.personas;
    const p = await repo.findOne({ where: { id } });
    if (!p) throw new NotFoundException({ i18nKey: 'persona.not_found' });
    return p;
  }
}

/**
 * Cheap value-equality for audit diffing. Same rationale as in
 * admin-scenarios.controller.ts — JSON-roundtrip is good enough because we
 * only need to know whether to record a field at all.
 */
function deepEqual(a: unknown, b: unknown): boolean {
  if (a === b) return true;
  if (a === null || b === null) return false;
  if (typeof a !== 'object' || typeof b !== 'object') return false;
  return JSON.stringify(a) === JSON.stringify(b);
}
