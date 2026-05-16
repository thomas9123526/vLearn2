import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class UserProfileDto {
  @ApiProperty() id!: string;
  @ApiProperty() email!: string;
  @ApiProperty() displayName!: string;
  @ApiProperty() avatarEmoji!: string;
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
  @IsOptional() @IsString() @MinLength(2) @MaxLength(100)
  @ApiProperty({ required: false })
  displayName?: string;

  @IsOptional() @IsString() @MaxLength(10)
  @ApiProperty({ required: false })
  avatarEmoji?: string;

  @IsOptional() @IsIn(['en', 'ko', 'zh'])
  @ApiProperty({ required: false, enum: ['en', 'ko', 'zh'] })
  uiLanguage?: string;

  @IsOptional() @IsIn(['apricot', 'sage', 'iris', 'obsidian'])
  @ApiProperty({ required: false })
  activeTheme?: string;

  @IsOptional() @IsString()
  @ApiProperty({ required: false })
  activePersonaId?: string;

  @IsOptional()
  @ApiProperty({ required: false })
  onboardingDone?: boolean;
}
