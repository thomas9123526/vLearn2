import { Body, Controller, ForbiddenException, HttpCode, Post } from '@nestjs/common';
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
   * Bootstrap endpoint: PUBLIC only while zero admins exist. First successful
   * call creates the superadmin and auto-closes the endpoint.
   */
  @Public()
  @Post('signup')
  @HttpCode(201)
  @ApiOperation({ summary: 'Bootstrap the first superadmin (auto-closes after first signup)' })
  async signup(@Body() dto: AdminSignupDto) {
    const adminCount = await this.users.count({
      where: [{ role: 'admin' }, { role: 'superadmin' }],
    });
    if (adminCount > 0) {
      throw new ForbiddenException({
        i18nKey: 'admin.signup_closed',
        message: 'Admin sign-up is closed; ask your superadmin to invite you.',
      });
    }

    const hash = await bcrypt.hash(dto.password, 10);
    const user = await this.users.save(
      this.users.create({
        email: dto.email,
        password_hash: hash,
        display_name: dto.displayName,
        role: 'superadmin',
      }),
    );

    // Re-use the regular sign-in flow to issue tokens. The simplest way is
    // to call the auth service's internal token issuance — but since that's
    // private, we just call signIn with the plaintext we just hashed.
    return this.authService.signIn({ email: dto.email, password: dto.password });
  }
}
