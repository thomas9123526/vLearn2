import { ApiProperty } from '@nestjs/swagger';
import {
  IsIn,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';

export class SignUpDto {
  @ApiProperty({
    example: 'A1234567',
    description: 'National ID / citizen ID (max 10 chars)',
  })
  @IsString()
  @MaxLength(10)
  cid!: string;

  @ApiProperty({
    example: 'alex_kr',
    description: 'Login username (max 12 chars)',
  })
  @IsString()
  @MinLength(2)
  @MaxLength(50)
  cidUsername!: string;

  // Single constraint per product spec: length >= 6. No upper/lower/digit/
  // symbol classes. MaxLength stays as defense-in-depth against accidental
  // megabyte payloads from a buggy client.
  @ApiProperty({ example: 'mypass1' })
  @IsString()
  @MinLength(6)
  @MaxLength(128)
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
  @ApiProperty({
    example: 'alex_kr',
    description: 'Login username (cid_username)',
  })
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
