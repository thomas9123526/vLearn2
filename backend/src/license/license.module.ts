import { createPublicKey, X509Certificate } from 'node:crypto';
import { Pool } from 'pg';

import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Module,
  Post,
  Injectable,
  BadRequestException,
  UnprocessableEntityException,
  OnModuleInit,
  Logger,
} from '@nestjs/common';
import {
  ApiBody,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { InjectRepository } from '@nestjs/typeorm';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { Public } from '../auth/decorators/public.decorator';
import { AppConfigEntity } from '../database/entities/app-config.entity';
import { UserInfoEntity } from '../database/entities/user-info.entity';

// ─── DTOs ────────────────────────────────────────────────────────────────────

class VerifyLicenseDto {
  @ApiProperty({ description: 'Base64-encoded DER cert bytes (≤ ~1500 bytes).' })
  @IsString()
  @MinLength(4)
  @MaxLength(4096)
  licenseContent!: string;

  @ApiProperty({ description: 'Opaque device fingerprint from native lib.' })
  @IsString()
  @MinLength(1)
  @MaxLength(256)
  machineId!: string;

  @ApiProperty({ required: false, description: 'App user UUID to bind the license to.' })
  @IsOptional()
  @IsString()
  userId?: string;

  /**
   * Platform the device is on, as reported by the client. The values
   * mirror Flutter's `defaultTargetPlatform`. Persisted on the user
   * row and `verify_log` so the admin panel can show what kind of
   * device each user activated from. Trust-on-write — not used for
   * any auth/authz decision.
   */
  @ApiProperty({
    required: false,
    enum: ['android', 'windows', 'ios', 'macos', 'linux', 'fuchsia', 'web'],
    description: 'Client-reported platform tag (mirrors Flutter defaultTargetPlatform).',
  })
  @IsOptional()
  @IsIn(['android', 'windows', 'ios', 'macos', 'linux', 'fuchsia', 'web'])
  platform?: string;
}

class VerifyLicenseResponseDto {
  @ApiProperty() valid!: boolean;
  @ApiProperty({ required: false, type: String, format: 'date-time' }) expiresAt?: string;
  @ApiProperty({ required: false, enum: ['period', 'permanent'] }) mode?: 'period' | 'permanent';
  @ApiProperty({ required: false }) daysRemaining?: number;
  @ApiProperty({ required: false }) reason?: string;
}

// ─── DER / ASN.1 helpers ─────────────────────────────────────────────────────

function readTlv(buf: Buffer, off: number) {
  if (off >= buf.length) return null;
  const tag = buf[off++];
  if (off >= buf.length) return null;
  const firstLen = buf[off++];
  let len: number;
  if (firstLen & 0x80) {
    const numBytes = firstLen & 0x7f;
    len = 0;
    for (let i = 0; i < numBytes; i++) len = (len << 8) | buf[off++];
  } else {
    len = firstLen;
  }
  const end = off + len;
  return { tag, value: buf.slice(off, end), end };
}

/** Encode a dotted-decimal OID string into raw OID content bytes (no tag/length). */
function encodeOidBytes(oid: string): Buffer {
  const parts = oid.split('.').map(Number);
  const bytes: number[] = [40 * parts[0] + parts[1]];
  for (let i = 2; i < parts.length; i++) {
    let val = parts[i];
    const chunk: number[] = [val & 0x7f];
    val >>>= 7;
    while (val > 0) {
      chunk.unshift((val & 0x7f) | 0x80);
      val >>>= 7;
    }
    bytes.push(...chunk);
  }
  return Buffer.from(bytes);
}

/**
 * Walk the X.509 extensions in raw DER and return the UTF-8 string value of
 * the extension whose OID matches `oid`.
 *
 * KeyGenerator encodes each custom extension value as:
 *   extnValue = OCTET STRING { DER(UTF8String "<value>") }
 */
function extractCustomOid(certDer: Buffer, oid: string): string | null {
  const oidBytes = encodeOidBytes(oid);
  try {
    const certTlv = readTlv(certDer, 0); // SEQUENCE Certificate
    if (!certTlv || certTlv.tag !== 0x30) return null;
    const tbsTlv = readTlv(certTlv.value, 0); // SEQUENCE TBSCertificate
    if (!tbsTlv || tbsTlv.tag !== 0x30) return null;

    // Scan TBSCertificate fields for context [3] EXPLICIT extensions
    let off = 0;
    while (off < tbsTlv.value.length) {
      const field = readTlv(tbsTlv.value, off);
      if (!field) break;
      if (field.tag === 0xa3) {
        const extListTlv = readTlv(field.value, 0); // SEQUENCE OF Extension
        if (!extListTlv || extListTlv.tag !== 0x30) break;
        let extOff = 0;
        while (extOff < extListTlv.value.length) {
          const ext = readTlv(extListTlv.value, extOff);
          if (!ext || ext.tag !== 0x30) break;
          const oidTlv = readTlv(ext.value, 0);
          if (oidTlv && oidTlv.tag === 0x06 && oidTlv.value.equals(oidBytes)) {
            let next = readTlv(ext.value, oidTlv.end);
            if (!next) { extOff = ext.end; continue; }
            if (next.tag === 0x01) next = readTlv(ext.value, next.end) ?? null; // skip BOOLEAN critical
            if (!next || next.tag !== 0x04) { extOff = ext.end; continue; } // OCTET STRING
            const inner = readTlv(next.value, 0); // DER UTF8String inside
            if (!inner || inner.tag !== 0x0c) { extOff = ext.end; continue; }
            return inner.value.toString('utf8');
          }
          extOff = ext.end;
        }
        break;
      }
      off = field.end;
    }
  } catch { /* fall through */ }
  return null;
}

const DAY_MS = 86_400_000;

// ─── Service ─────────────────────────────────────────────────────────────────

@Injectable()
class LicenseService implements OnModuleInit {
  private readonly log = new Logger(LicenseService.name);
  private licensePool: Pool | null = null;

  constructor(
    @InjectRepository(AppConfigEntity)
    private readonly configRepo: Repository<AppConfigEntity>,
    @InjectRepository(UserInfoEntity)
    private readonly userInfoRepo: Repository<UserInfoEntity>,
  ) {}

  onModuleInit() {
    const url = process.env.LICENSE_DB_URL;
    if (url) {
      this.licensePool = new Pool({ connectionString: url });
      this.licensePool.on('error', (err) =>
        this.log.warn(`vLearnLicense pool error: ${err.message}`),
      );
    } else {
      this.log.warn('LICENSE_DB_URL not set — verify_log inserts will be skipped');
    }
  }

  async verify(dto: VerifyLicenseDto): Promise<VerifyLicenseResponseDto> {
    // 1. Decode the DER cert from base64
    let certDer: Buffer;
    try {
      certDer = Buffer.from(dto.licenseContent, 'base64');
      if (certDer.length < 64) throw new Error('too short');
    } catch {
      throw new BadRequestException({ i18nKey: 'license.malformed' });
    }

    // 2. Load the Leaf CA public PEM from vl_app_config
    const pemRow = await this.configRepo.findOne({ where: { key: 'license.public_pem' } });
    const publicPem = typeof pemRow?.value === 'string' ? pemRow.value.trim() : '';
    if (!publicPem) {
      throw new UnprocessableEntityException({
        i18nKey: 'license.not_configured',
        message: 'license.public_pem is not set in the admin panel',
      });
    }

    // 3. Parse cert and verify signature against the Leaf CA public key
    let cert: X509Certificate;
    try {
      cert = new X509Certificate(certDer);
      const leafCaKey = createPublicKey(publicPem);
      if (!cert.verify(leafCaKey)) {
        return this.reject(certDer, dto, 'forged', 'signature mismatch');
      }
    } catch (e: unknown) {
      return this.reject(certDer, dto, 'forged', (e as Error).message ?? 'parse error');
    }

    // 4. Check expiry using server clock
    const notAfter = new Date(cert.validTo);
    if (notAfter < new Date()) {
      return this.reject(certDer, dto, 'expired', 'certificate has expired');
    }

    // 5. Verify machine ID binding (OID 1.3.6.1.4.1.99999.1)
    const certMachineId = extractCustomOid(certDer, '1.3.6.1.4.1.99999.1');
    if (!certMachineId || certMachineId !== dto.machineId) {
      return this.reject(certDer, dto, 'mismatch', 'machineId does not match cert');
    }

    // 6. Read mode from OID 1.3.6.1.4.1.99999.2
    const rawMode = extractCustomOid(certDer, '1.3.6.1.4.1.99999.2');
    const mode: 'permanent' | 'period' = rawMode === 'permanent' ? 'permanent' : 'period';

    const serial = cert.serialNumber;

    // 7. Update license columns on vl_user_info (users table columns are kept
    //    for cross-system compatibility but this app writes here exclusively).
    if (dto.userId) {
      try {
        await this.userInfoRepo
          .createQueryBuilder()
          .update()
          .set({
            license_valid_until: notAfter,
            license_machine_id: dto.machineId,
            license_serial: serial,
            // Only overwrite the platform tag when the client sent
            // one; leaves the previous value intact for older clients
            // that haven't been updated yet.
            ...(dto.platform ? { license_platform: dto.platform } : {}),
          } as object)
          .where('user_id = :id', { id: dto.userId })
          .execute();
      } catch (e: unknown) {
        this.log.warn(`Failed to update user license: ${(e as Error).message}`);
      }
    }

    // 8. Log to vLearnLicense.verify_log
    const notBefore = new Date(cert.validFrom);
    await this.logVerify(serial, dto.machineId, dto.userId ?? null, 'valid', dto.platform ?? null, {
      certDer,
      mode,
      notBefore,
      notAfter,
    });

    const daysRemaining = Math.max(0, Math.ceil((notAfter.getTime() - Date.now()) / DAY_MS));

    return { valid: true, expiresAt: notAfter.toISOString(), mode, daysRemaining };
  }

  private async reject(
    certDer: Buffer,
    dto: VerifyLicenseDto,
    result: 'expired' | 'mismatch' | 'forged' | 'invalid',
    reason: string,
  ): Promise<VerifyLicenseResponseDto> {
    let serial = 'unknown';
    try { serial = new X509Certificate(certDer).serialNumber; } catch { /* ok */ }
    await this.logVerify(serial, dto.machineId, dto.userId ?? null, result, dto.platform ?? null);
    return { valid: false, reason };
  }

  private async logVerify(
    serial: string,
    machineId: string,
    userId: string | null,
    result: string,
    platform: string | null,
    // Provided only on the valid path; used to auto-register unknown serials.
    certContext?: { certDer: Buffer; mode: string; notBefore: Date; notAfter: Date },
  ): Promise<void> {
    if (!this.licensePool) return;

    const insertVerifyLog = async (withPlatform: boolean): Promise<void> => {
      if (withPlatform) {
        await this.licensePool!.query(
          `INSERT INTO verify_log (serial, machine_id, user_id, result, platform)
           VALUES ($1, $2, $3, $4, $5)`,
          [serial, machineId, userId, result, platform],
        );
      } else {
        await this.licensePool!.query(
          `INSERT INTO verify_log (serial, machine_id, user_id, result)
           VALUES ($1, $2, $3, $4)`,
          [serial, machineId, userId, result],
        );
      }
    };

    // Auto-register a cert serial that pre-dates the generate_log table.
    // ON CONFLICT DO NOTHING is safe — if it was already registered by a
    // concurrent request, we just skip.
    const ensureGenerateLog = async (): Promise<void> => {
      if (!certContext) return;
      const days = Math.max(0, Math.round(
        (certContext.notAfter.getTime() - certContext.notBefore.getTime()) / DAY_MS,
      ));
      await this.licensePool!.query(
        `INSERT INTO generate_log
           (serial, machine_id, mode, days, not_before, not_after, operator, cert_der)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         ON CONFLICT (serial) DO NOTHING`,
        [serial, machineId, certContext.mode, days,
         certContext.notBefore, certContext.notAfter,
         'auto-registered', certContext.certDer],
      );
    };

    const isFkViolation = (e: unknown) => (e as any)?.code === '23503';
    const isMissingColumn = (e: unknown) => ((e as Error)?.message ?? '').includes('column "platform"');

    try {
      await insertVerifyLog(platform !== null);
    } catch (e1: unknown) {
      if (isMissingColumn(e1)) {
        // verify_log.platform column not yet added — try without it
        try {
          await insertVerifyLog(false);
        } catch (e2: unknown) {
          if (isFkViolation(e2)) {
            await ensureGenerateLog();
            try { await insertVerifyLog(false); } catch { /* give up */ }
          } else {
            this.log.warn(`verify_log fallback insert failed: ${(e2 as Error).message}`);
          }
        }
      } else if (isFkViolation(e1)) {
        // Serial not yet in generate_log (cert pre-dates the log table).
        // Auto-register it, then retry.
        await ensureGenerateLog();
        try {
          await insertVerifyLog(platform !== null);
        } catch { /* give up — audit logging is non-critical */ }
      } else {
        this.log.warn(`verify_log insert failed: ${(e1 as Error).message}`);
      }
    }
  }
}

// ─── Controller ──────────────────────────────────────────────────────────────

@ApiTags('License')
@Controller('license')
class LicenseController {
  constructor(private readonly svc: LicenseService) {}

  @Public()
  @Post('verify')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Verify a license cert blob against the configured Leaf CA.' })
  @ApiBody({ type: VerifyLicenseDto })
  @ApiOkResponse({ type: VerifyLicenseResponseDto })
  verify(@Body() dto: VerifyLicenseDto): Promise<VerifyLicenseResponseDto> {
    return this.svc.verify(dto);
  }
}

// ─── Module ──────────────────────────────────────────────────────────────────

@Module({
  imports: [TypeOrmModule.forFeature([AppConfigEntity, UserInfoEntity])],
  providers: [LicenseService],
  controllers: [LicenseController],
})
export class LicenseModule {}
