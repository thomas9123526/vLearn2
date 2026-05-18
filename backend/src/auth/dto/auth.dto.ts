import { ApiProperty } from '@nestjs/swagger';
import {
  IsIn,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
  Matches,
} from 'class-validator';

export class SignUpDto {
  @ApiProperty({ example: 'A1234567', description: 'National ID / citizen ID (max 10 chars)' })
  @IsString()
  @MaxLength(10)
  cid!: string;

  @ApiProperty({ example: 'alex_kr', description: 'Login username (max 12 chars)' })
  @IsString()
  @MinLength(2)
  @MaxLength(12)
  cidUsername!: string;

  @ApiProperty({ example: 'StrongP@ssw0rd' })
  @IsString()
  @MinLength(8)
  @MaxLength(128)
  @Matches(/[a-z]/, { message: 'Password must contain a lowercase letter' })
  @Matches(/[A-Z]/, { message: 'Password must contain an uppercase letter' })
  @Matches(/[0-9]/, { message: 'Password must contain a digit' })
  password!: string;

  @ApiProperty({ example: 'Alex' })
  @IsString()
  @MinLength(2)
  @MaxLength(100)
  displayName!: string;

  @ApiProperty({ required: false, default: 'en', enum: ['en', 'ko', 'zh'] })
  @IsOptional()
  @IsIn(['en', 'ko', 'zh'])
  uiLanguage?: string;
}

export class SignInDto {
  @ApiProperty({ example: 'alex_kr', description: 'Login username (cid_username)' })
  @IsString()
  cidUsername!: string;

  @ApiProperty({ example: 'StrongP@ssw0rd' })
  @IsString()
  password!: string;
}

export class RefreshDto {
  @ApiProperty()
  @IsString()
  refreshToken!: string;
}

export class TokenPairDto {
  @ApiProperty()
  accessToken!: string;

  @ApiProperty()
  refreshToken!: string;

  @ApiProperty({ description: 'Access-token expiry in seconds from now' })
  expiresIn!: number;
}

export class AuthResponseDto extends TokenPairDto {
  @ApiProperty()
  userId!: string;

  @ApiProperty()
  cidUsername!: string;

  @ApiProperty()
  displayName!: string;

  @ApiProperty({ enum: ['user', 'admin', 'superadmin'] })
  role!: string;
}
