import { Body, Controller, HttpCode, Post, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiProperty,
  ApiTags,
} from '@nestjs/swagger';
import {
  IsEmail,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
  Matches,
} from 'class-validator';
import { Public } from '../../auth/decorators/public.decorator';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import type { JwtPayload } from '../../auth/strategies/jwt.strategy';
import { AdminAuthService } from './admin-auth.service';

class AdminSignupDto {
  @ApiProperty({ example: 'founder@example.com' })
  @IsEmail()
  email!: string;

  @ApiProperty()
  @IsString()
  @MinLength(12)
  @MaxLength(128)
  @Matches(/[a-z]/)
  @Matches(/[A-Z]/)
  @Matches(/[0-9]/)
  password!: string;

  @ApiProperty()
  @IsString()
  @MinLength(2)
  @MaxLength(100)
  displayName!: string;
}

class AdminSignInDto {
  @ApiProperty() @IsEmail() email!: string;
  @ApiProperty() @IsString() password!: string;
}

class AdminRefreshDto {
  @ApiProperty() @IsString() refreshToken!: string;
}

class AdminSignOutDto {
  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  refreshToken?: string;
}

@ApiTags('Admin / Auth')
@Controller('admin/auth')
export class AdminAuthController {
  constructor(private readonly auth: AdminAuthService) {}

  /**
   * Public admin signup. First account → superadmin, rest → admin.
   * Stays open by design for the dev flow; gate (auto-close, invite codes,
   * IP allow-list) before any public deploy.
   */
  @Public()
  @Post('signup')
  @HttpCode(201)
  @ApiOperation({
    summary:
      'Sign up as an admin. First signup = superadmin, subsequent = admin.',
  })
  signup(@Body() dto: AdminSignupDto) {
    return this.auth.signUp(dto.email, dto.password, dto.displayName);
  }

  @Public()
  @Post('signin')
  @HttpCode(200)
  @ApiOperation({ summary: 'Sign in as an admin' })
  signin(@Body() dto: AdminSignInDto) {
    return this.auth.signIn(dto.email, dto.password);
  }

  @Public()
  @Post('refresh')
  @HttpCode(200)
  @ApiOperation({ summary: 'Rotate the admin refresh token' })
  refresh(@Body() dto: AdminRefreshDto) {
    return this.auth.refresh(dto.refreshToken);
  }

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Post('signout')
  @HttpCode(204)
  @ApiOperation({ summary: 'Revoke admin refresh token(s)' })
  async signout(
    @CurrentUser() user: JwtPayload,
    @Body() body: AdminSignOutDto,
  ): Promise<void> {
    await this.auth.signOut(user.sub, body.refreshToken);
  }
}
