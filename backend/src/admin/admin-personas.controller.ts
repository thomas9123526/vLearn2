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
  IsBoolean,
  IsHexColor,
  IsIn,
  IsOptional,
  IsString,
  Length,
} from 'class-validator';
import * as fs from 'fs';
import * as path from 'path';
import { PersonaEntity } from '../database/entities/persona.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionGuard, RequirePermission } from './permissions/permission.guard';

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
  @ApiProperty({ required: false }) @IsOptional() @IsString() @Length(1, 100) rive_asset?: string;
  @ApiProperty({ required: false }) @IsOptional() @IsString() @Length(1, 100) voice_id?: string;
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
  @ApiProperty({ required: false }) @IsOptional() @IsString() @Length(1, 100) rive_asset?: string;
  @ApiProperty({ required: false }) @IsOptional() @IsString() @Length(1, 100) voice_id?: string;
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
    const p = await this.personas.findOne({ where: { id } });
    if (!p) throw new NotFoundException({ i18nKey: 'persona.not_found' });
    return p;
  }

  @Post()
  @RequirePermission('personas.edit')
  async create(@Body() dto: CreatePersonaDto) {
    const existing = await this.personas.findOne({ where: { slug: dto.slug } });
    if (existing) {
      throw new BadRequestException({ i18nKey: 'persona.slug_taken' });
    }
    const p = this.personas.create({
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
    return this.personas.save(p);
  }

  @Patch(':id')
  @RequirePermission('personas.edit')
  async update(@Param('id') id: string, @Body() dto: UpdatePersonaDto) {
    const p = await this.get(id);
    Object.assign(p, dto);
    return this.personas.save(p);
  }

  /**
   * Soft-delete. We never hard-delete personas because historical
   * conversation sessions reference them.
   */
  @Delete(':id')
  @RequirePermission('personas.edit')
  async deactivate(@Param('id') id: string) {
    const p = await this.get(id);
    p.is_active = false;
    await this.personas.save(p);
    return { ok: true };
  }

  @Post(':id/restore')
  @RequirePermission('personas.edit')
  async restore(@Param('id') id: string) {
    const p = await this.get(id);
    p.is_active = true;
    await this.personas.save(p);
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
    @Param('id') id: string,
    @UploadedFile() file: { originalname: string; buffer: Buffer; mimetype: string },
  ) {
    if (!file) throw new BadRequestException({ i18nKey: 'upload.no_file' });
    if (!/^image\/(jpe?g|png|webp)$/.test(file.mimetype)) {
      throw new BadRequestException({ i18nKey: 'upload.bad_mime' });
    }
    const p = await this.get(id);
    const uploadsDir = process.env.UPLOADS_DIR ?? path.resolve('uploads');
    const dir = path.join(uploadsDir, 'personas');
    fs.mkdirSync(dir, { recursive: true });
    const ext = (file.originalname.split('.').pop() ?? 'jpg').toLowerCase();
    const filename = `${id}.${ext}`;
    const abs = path.join(dir, filename);
    fs.writeFileSync(abs, file.buffer);
    p.image_storage_key = path.posix.join('personas', filename);
    p.image_url = `/uploads/${p.image_storage_key}`;
    await this.personas.save(p);
    return { image_url: p.image_url };
  }
}
