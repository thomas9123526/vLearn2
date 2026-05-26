import { ApiProperty } from '@nestjs/swagger';
import {
  IsIn,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';

export class UserProfileDto {
  @ApiProperty() id!: string;
  @ApiProperty({ nullable: true }) email!: string | null;
  @ApiProperty() displayName!: string;
  @ApiProperty() avatarEmoji!: string;
  /// Public URL to the user-uploaded photo, or null if they're still
  /// using the emoji fallback. Path is `/uploads/avatars/<id>.<ext>`.
  @ApiProperty({ nullable: true }) avatarUrl!: string | null;
  @ApiProperty() gender!: string;
  @ApiProperty() nativeLanguage!: string;
  @ApiProperty() uiLanguage!: string;
  @ApiProperty() currentLevel!: number;
  @ApiProperty() xpTotal!: number;
  @ApiProperty() streakDays!: number;
  @ApiProperty() activePersonaId!: string | null;
  @ApiProperty() activeTheme!: string;
  @ApiProperty() onboardingDone!: boolean;
  @ApiProperty() role!: string;
  @ApiProperty() status!: string;
}

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(100)
  @ApiProperty({ required: false })
  displayName?: string;

  @IsOptional()
  @IsString()
  @MaxLength(10)
  @ApiProperty({ required: false })
  avatarEmoji?: string;

  @IsOptional()
  @IsIn(['male', 'female', 'nonbinary', 'unspecified'])
  @ApiProperty({
    required: false,
    enum: ['male', 'female', 'nonbinary', 'unspecified'],
  })
  gender?: string;

  @IsOptional()
  @IsIn(['en', 'ko', 'zh'])
  @ApiProperty({ required: false, enum: ['en', 'ko', 'zh'] })
  uiLanguage?: string;

  @IsOptional()
  @IsIn(['apricot', 'sage', 'iris', 'obsidian'])
  @ApiProperty({ required: false })
  activeTheme?: string;

  @IsOptional()
  @IsString()
  @ApiProperty({ required: false })
  activePersonaId?: string;

  @IsOptional()
  @ApiProperty({ required: false })
  onboardingDone?: boolean;

  /// Plain-text new password. Server hashes it before storing.
  /// Validated against the current password for safety. Length-only
  /// constraint per product spec (no upper/lower/digit/symbol classes).
  @IsOptional()
  @IsString()
  @MinLength(6)
  @MaxLength(128)
  @ApiProperty({ required: false })
  newPassword?: string;

  /// Required when `newPassword` is set — proves the caller controls the
  /// account, not just the access token (which a stolen device could have).
  @IsOptional()
  @IsString()
  @ApiProperty({ required: false })
  currentPassword?: string;
}
