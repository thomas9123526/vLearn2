import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Module,
  Post,
  Injectable,
  BadRequestException,
} from '@nestjs/common';
import {
  ApiBody,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { Public } from '../auth/decorators/public.decorator';

/**
 * Public license-verification endpoint. The full X.509 chain-validation
 * pipeline isn't wired yet — see
 * `docs/0525/17_license_plan.md` for the spec — so this endpoint
 * currently accepts the cert blob and returns a deterministic stub:
 * if `license.enabled` is false the app shouldn't be calling this at
 * all; when it is, the stub responds with a 100-year permanent
 * license so the Flutter side can be exercised end-to-end while the
 * real verifier is being built.
 *
 * The stub still validates basic shape and length so an obviously
 * malformed blob still 400s, which keeps the client error paths
 * honest while we wait for the real cert layer.
 */
class VerifyLicenseDto {
  @ApiProperty({
    description: 'Base64-encoded DER cert bytes (≤ ~1500 bytes).',
  })
  @IsString()
  @MinLength(4)
  @MaxLength(4096)
  licenseContent!: string;

  @ApiProperty({ description: 'Opaque device fingerprint from native lib.' })
  @IsString()
  @MinLength(1)
  @MaxLength(256)
  machineId!: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  userId?: string;
}

class VerifyLicenseResponseDto {
  @ApiProperty() valid!: boolean;
  @ApiProperty({ required: false, type: String, format: 'date-time' })
  expiresAt?: string;
  @ApiProperty({ required: false, enum: ['period', 'permanent'] })
  mode?: 'period' | 'permanent';
  @ApiProperty({ required: false }) daysRemaining?: number;
  @ApiProperty({ required: false }) reason?: string;
}

@Injectable()
class LicenseService {
  /**
   * Stub: returns a 100-year permanent license whenever the request
   * shape is valid. Replace with X.509 parse + chain verify per the
   * plan doc (`docs/0525/17_license_plan.md` section 3).
   */
  verify(dto: VerifyLicenseDto): VerifyLicenseResponseDto {
    if (!dto.licenseContent?.trim() || !dto.machineId?.trim()) {
      throw new BadRequestException({ i18nKey: 'license.malformed' });
    }
    const expiresAt = new Date();
    expiresAt.setFullYear(expiresAt.getFullYear() + 100);
    return {
      valid: true,
      expiresAt: expiresAt.toISOString(),
      mode: 'permanent',
      daysRemaining: Math.floor(
        (expiresAt.getTime() - Date.now()) / (1000 * 60 * 60 * 24),
      ),
    };
  }
}

@ApiTags('License')
@Controller('license')
class LicenseController {
  constructor(private readonly svc: LicenseService) {}

  @Public()
  @Post('verify')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Verify a license cert blob against the configured Leaf CA. STUB.',
  })
  @ApiBody({ type: VerifyLicenseDto })
  @ApiOkResponse({ type: VerifyLicenseResponseDto })
  verify(@Body() dto: VerifyLicenseDto): VerifyLicenseResponseDto {
    return this.svc.verify(dto);
  }
}

@Module({
  providers: [LicenseService],
  controllers: [LicenseController],
})
export class LicenseModule {}
