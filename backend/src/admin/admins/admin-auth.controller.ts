import { Body, ConflictException, Controller, HttpCode, Post } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { IsEmail, IsString, MinLength, MaxLength, Matches } from 'class-validator';
import * as bcrypt from 'bcrypt';
import { ApiProperty } from '@nestjs/swagger';
import { UserEntity } from '../../database/entities/user.entity';
import { Public } from '../../auth/decorators/public.decorator';
import { AuthService } from '../../auth/auth.service';

class AdminSignupDto {
  @ApiProperty({ example: 'founder@example.com' })
  @IsEmail() email!: string;

  @ApiProperty()
  @IsString() @MinLength(12) @MaxLength(128)
  @Matches(/[a-z]/) @Matches(/[A-Z]/) @Matches(/[0-9]/)
  password!: string;

  @ApiProperty() @IsString() @MinLength(2) @MaxLength(100)
  displayName!: string;
}

@ApiTags('Admin / Auth')
@Controller('admin/auth')
export class AdminAuthController {
  constructor(
    @InjectRepository(UserEntity)
    private readonly users: Repository<UserEntity>,
    private readonly authService: AuthService,
  ) {}

  /**
   * Public admin signup. The first account to sign up becomes the superadmin;
   * every subsequent account becomes a regular admin ("subadmin"). The
   * endpoint stays open — invitations are NOT required.
   *
   * Note (operator): this is intentionally permissive for the development
   * flow. If you ever deploy this publicly, gate it (IP allow-list, invite
   * codes, or auto-close after first signup) before exposing.
   */
  @Public()
  @Post('signup')
  @HttpCode(201)
  @ApiOperation({
    summary:
      'Sign up as an admin. First signup = superadmin, subsequent = admin.',
  })
  async signup(@Body() dto: AdminSignupDto) {
    // Reject duplicates up-front so we return a clean 409 instead of letting
    // Postgres' unique-email constraint trip and surface as a generic 500.
    // This also catches the case where the email already exists as a regular
    // (non-admin) user — they need to be promoted via the Admins page rather
    // than re-signed-up here.
    const existing = await this.users.findOne({ where: { email: dto.email } });
    if (existing) {
      throw new ConflictException({ i18nKey: 'auth.email_taken' });
    }

    const adminCount = await this.users.count({
      where: [{ role: 'admin' }, { role: 'superadmin' }],
    });
    const role: 'superadmin' | 'admin' =
      adminCount === 0 ? 'superadmin' : 'admin';

    const hash = await bcrypt.hash(dto.password, 10);
    await this.users.save(
      this.users.create({
        email: dto.email,
        password_hash: hash,
        display_name: dto.displayName,
        role,
      }),
    );

    // Re-use the regular sign-in flow to issue tokens. The simplest way is
    // to call the auth service's internal token issuance — but since that's
    // private, we just call signIn with the plaintext we just hashed.
    return this.authService.signIn({ email: dto.email, password: dto.password });
  }
}
