import { ApiProperty } from '@nestjs/swagger';
import {
  IsIn,
  IsOptional,
  IsString,
  Matches,
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
    example: 'kky1206',
    description:
      'Login username. Letters + digits only, with at least 2 letters and ' +
      'at least 2 digits (e.g. kky1206, ks10, ksg19970890).',
  })
  @IsString()
  // 2 letters + 2 digits = 4-char minimum. Upper bound stays at 50.
  @MinLength(4)
  @MaxLength(50)
  // Lookaheads enforce >=2 letters and >=2 digits; the trailing class
  // restricts the body to ASCII letters + digits only (no underscores,
  // no Unicode -- the cid_username has to round-trip through URLs and
  // analytics keys cleanly).
  @Matches(/^(?=(?:.*[a-zA-Z]){2,})(?=(?:.*\d){2,})[a-zA-Z0-9]+$/, {
    message:
      'cidUsername must be letters + digits only, with at least 2 letters and at least 2 digits (e.g. kky1206)',
  })
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
    example: 'kky1206',
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

export class SuggestCidUsernameDto {
  @ApiProperty({ example: 'Hong Li Jun', description: 'Display name to derive initials from' })
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  displayName!: string;

  @ApiProperty({ example: '1994-03-17', description: 'Birthday in YYYY-MM-DD format' })
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'birthday must be YYYY-MM-DD' })
  birthday!: string;
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
