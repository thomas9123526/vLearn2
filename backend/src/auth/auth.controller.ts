import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiTags,
  ApiOkResponse,
  ApiCreatedResponse,
} from '@nestjs/swagger';
import { AuthService } from './auth.service';
import {
  SignUpDto,
  SignInDto,
  RefreshDto,
  AuthResponseDto,
  TokenPairDto,
} from './dto/auth.dto';
import { Public } from './decorators/public.decorator';
import { CurrentUser } from './decorators/current-user.decorator';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import type { JwtPayload } from './strategies/jwt.strategy';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Public()
  @Post('signup')
  @ApiOperation({ summary: 'Register a new user' })
  @ApiCreatedResponse({ type: AuthResponseDto })
  @HttpCode(HttpStatus.CREATED)
  signUp(@Body() dto: SignUpDto): Promise<AuthResponseDto> {
    return this.auth.signUp(dto);
  }

  @Public()
  @Post('signin')
  @ApiOperation({ summary: 'Authenticate and receive a JWT pair' })
  @ApiOkResponse({ type: AuthResponseDto })
  @HttpCode(HttpStatus.OK)
  signIn(@Body() dto: SignInDto): Promise<AuthResponseDto> {
    return this.auth.signIn(dto);
  }

  @Public()
  @Post('refresh')
  @ApiOperation({ summary: 'Rotate refresh token for a new access/refresh pair' })
  @ApiOkResponse({ type: TokenPairDto })
  @HttpCode(HttpStatus.OK)
  refresh(@Body() dto: RefreshDto): Promise<TokenPairDto> {
    return this.auth.refresh(dto.refreshToken);
  }

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Post('signout')
  @ApiOperation({ summary: 'Revoke the current (or all) refresh token(s)' })
  @HttpCode(HttpStatus.NO_CONTENT)
  async signOut(
    @CurrentUser() user: JwtPayload,
    @Body() body: Partial<RefreshDto>,
  ): Promise<void> {
    await this.auth.signOut(user.sub, body.refreshToken);
  }

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Get('me')
  @ApiOperation({ summary: 'Get the JWT-decoded user (without DB roundtrip)' })
  me(@CurrentUser() user: JwtPayload): JwtPayload {
    return user;
  }
}
