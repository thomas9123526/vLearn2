import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
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
  SuggestCidUsernameDto,
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
  @Get('lookup-username')
  @ApiOperation({
    summary:
      'Resolve a registered CID to its login username (pre-signin convenience)',
  })
  @ApiQuery({ name: 'cid', required: true })
  @ApiOkResponse({ schema: { example: { cidUsername: 'kky1206' } } })
  @HttpCode(HttpStatus.OK)
  lookupUsername(
    @Query('cid') cid: string,
  ): Promise<{ cidUsername: string }> {
    return this.auth.lookupUsernameByCid(cid ?? '');
  }

  @Public()
  @Post('suggest-cid-username')
  @ApiOperation({ summary: 'Suggest available cid_usernames from display name + birthday' })
  @ApiOkResponse({ schema: { example: { suggestions: ['hlj94317', 'hlj317'] } } })
  @HttpCode(HttpStatus.OK)
  suggestCidUsername(
    @Body() dto: SuggestCidUsernameDto,
  ): Promise<{ suggestions: string[] }> {
    return this.auth.suggestCidUsernames(dto);
  }

  @Public()
  @Post('refresh')
  @ApiOperation({
    summary: 'Rotate refresh token for a new access/refresh pair',
  })
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
