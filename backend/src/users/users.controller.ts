import {
  BadRequestException,
  Body,
  Controller,
  Get,
  HttpCode,
  Patch,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  ApiBearerAuth,
  ApiBody,
  ApiConsumes,
  ApiOkResponse,
  ApiOperation,
  ApiProperty,
  ApiTags,
} from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';
import * as fs from 'fs';
import * as path from 'path';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { JwtPayload } from '../auth/strategies/jwt.strategy';
import { UsersService } from './users.service';
import { UpdateProfileDto, UserProfileDto } from './dto/user.dto';
import { UserReportEntity } from '../database/entities/user-report.entity';

class CreateReportDto {
  @ApiProperty({ enum: ['feedback', 'bug', 'other'], required: false })
  @IsOptional()
  @IsIn(['feedback', 'bug', 'other'])
  type?: 'feedback' | 'bug' | 'other';

  @ApiProperty()
  @IsString()
  @MaxLength(2000)
  content!: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  platform?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  app_version?: string;
}

@ApiTags('Users')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('users')
export class UsersController {
  constructor(
    private readonly users: UsersService,
    @InjectRepository(UserReportEntity)
    private readonly reports: Repository<UserReportEntity>,
  ) {}

  @Get('profile')
  @ApiOperation({ summary: 'Get the current user profile' })
  @ApiOkResponse({ type: UserProfileDto })
  profile(@CurrentUser() user: JwtPayload): Promise<UserProfileDto> {
    return this.users.profileFor(user.sub);
  }

  @Patch('profile')
  @ApiOperation({ summary: 'Update the current user profile' })
  @ApiOkResponse({ type: UserProfileDto })
  update(
    @CurrentUser() user: JwtPayload,
    @Body() dto: UpdateProfileDto,
  ): Promise<UserProfileDto> {
    return this.users.updateProfile(user.sub, dto);
  }

  /**
   * Uploads a profile photo for the current user. Multipart form
   * field name is `file`; image/jpeg|png|webp under 5 MB. Saved to
   * `<UPLOADS_DIR>/avatars/<user_id>.<ext>` and the public
   * `/uploads/avatars/<file>` URL is mirrored into
   * vl_user_info.avatar_url so clients render it directly.
   */
  @Post('avatar')
  @UseInterceptors(
    FileInterceptor('file', { limits: { fileSize: 5 * 1024 * 1024 } }),
  )
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: { file: { type: 'string', format: 'binary' } },
    },
  })
  @ApiOkResponse({ type: UserProfileDto })
  async uploadAvatar(
    @CurrentUser() user: JwtPayload,
    @UploadedFile()
    file: { originalname: string; buffer: Buffer; mimetype: string },
  ): Promise<UserProfileDto> {
    if (!file) throw new BadRequestException({ i18nKey: 'upload.no_file' });
    if (!/^image\/(jpe?g|png|webp)$/.test(file.mimetype)) {
      throw new BadRequestException({ i18nKey: 'upload.bad_mime' });
    }
    const uploadsDir = process.env.UPLOADS_DIR ?? path.resolve('uploads');
    const dir = path.join(uploadsDir, 'avatars');
    fs.mkdirSync(dir, { recursive: true });
    const ext = (file.originalname.split('.').pop() ?? 'jpg').toLowerCase();
    const filename = `${user.sub}.${ext}`;
    const abs = path.join(dir, filename);
    fs.writeFileSync(abs, file.buffer);
    const storageKey = path.posix.join('avatars', filename);
    const publicUrl = `/uploads/${storageKey}`;
    return this.users.setAvatar(user.sub, storageKey, publicUrl);
  }

  /** Submit a feedback / bug report from the app. */
  @Post('report')
  @HttpCode(201)
  @ApiOperation({ summary: 'Submit a user feedback / bug report' })
  async submitReport(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateReportDto,
  ) {
    const report = this.reports.create({
      user_id: user.sub,
      type: dto.type ?? 'feedback',
      content: dto.content,
      platform: dto.platform ?? null,
      app_version: dto.app_version ?? null,
    });
    await this.reports.save(report);
    return { ok: true };
  }
}
