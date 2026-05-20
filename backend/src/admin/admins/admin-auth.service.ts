import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, MoreThan, Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { createHash, randomBytes } from 'crypto';
import { AdminEntity } from '../../database/entities/admin.entity';
import { AdminRefreshTokenEntity } from '../../database/entities/admin-refresh-token.entity';
import { AdminPermissionEntity } from '../../database/entities/admin-permission.entity';
import type { JwtPayload } from '../../auth/strategies/jwt.strategy';
import { AdminAuditLogService } from '../audit/admin-audit-log.service';

const BCRYPT_ROUNDS = 10;

export interface AdminTokenPair {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export interface AdminAuthResponse extends AdminTokenPair {
  adminId: string;
  email: string;
  displayName: string;
  role: 'admin' | 'superadmin';
}

/**
 * Admin-side auth. Mirrors the shape of {@link AuthService} but operates on
 * the `admins` + `admin_refresh_tokens` tables and stamps the JWT with
 * `actor: 'admin'` so guards can tell admin and user sessions apart.
 */
@Injectable()
export class AdminAuthService {
  constructor(
    @InjectRepository(AdminEntity)
    private readonly admins: Repository<AdminEntity>,
    @InjectRepository(AdminRefreshTokenEntity)
    private readonly refreshTokens: Repository<AdminRefreshTokenEntity>,
    @InjectRepository(AdminPermissionEntity)
    private readonly permissions: Repository<AdminPermissionEntity>,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    private readonly audit: AdminAuditLogService,
    private readonly dataSource: DataSource,
  ) {}

  async signUp(
    email: string,
    password: string,
    displayName: string,
  ): Promise<AdminAuthResponse> {
    const hash = await bcrypt.hash(password, BCRYPT_ROUNDS);

    // Create the admin row and the audit row in one transaction so a
    // failed audit insert rolls the new admin back. issue() runs after the
    // commit — its refresh-token write should not be rolled back if the
    // session-issue step itself fails.
    const admin = await this.dataSource.transaction(async (em) => {
      const adminRepo = em.getRepository(AdminEntity);
      const existing = await adminRepo.findOne({ where: { email } });
      if (existing) {
        throw new ConflictException({ i18nKey: 'auth.email_taken' });
      }
      const adminCount = await adminRepo.count();
      const role: 'admin' | 'superadmin' =
        adminCount === 0 ? 'superadmin' : 'admin';
      const created = await adminRepo.save(
        adminRepo.create({
          email,
          password_hash: hash,
          display_name: displayName,
          role,
        }),
      );
      await this.audit.record(
        {
          actorId: created.id,
          action: 'admin.signup',
          targetType: 'admin',
          targetId: created.id,
          newValue: { email, display_name: displayName, role },
        },
        em,
      );
      return created;
    });

    return this.issue(admin);
  }

  async signIn(email: string, password: string): Promise<AdminAuthResponse> {
    const admin = await this.admins.findOne({
      where: { email },
      select: [
        'id',
        'email',
        'password_hash',
        'display_name',
        'role',
        'status',
      ],
    });
    if (!admin) {
      throw new UnauthorizedException({ i18nKey: 'auth.invalid_credentials' });
    }
    if (admin.status !== 'active') {
      throw new UnauthorizedException({ i18nKey: 'admin.account_inactive' });
    }
    const ok = await bcrypt.compare(password, admin.password_hash);
    if (!ok) {
      throw new UnauthorizedException({ i18nKey: 'auth.invalid_credentials' });
    }
    await this.admins.update({ id: admin.id }, { last_login_at: new Date() });
    return this.issue(admin);
  }

  async refresh(refreshToken: string): Promise<AdminTokenPair> {
    const tokenHash = this.hashToken(refreshToken);
    const stored = await this.refreshTokens.findOne({
      where: { token_hash: tokenHash, expires_at: MoreThan(new Date()) },
    });
    if (!stored) {
      throw new UnauthorizedException({ i18nKey: 'auth.invalid_refresh' });
    }
    const admin = await this.admins.findOne({ where: { id: stored.admin_id } });
    if (!admin) throw new UnauthorizedException();

    // Rotation: delete the used refresh token and issue a new pair.
    await this.refreshTokens.delete({ id: stored.id });
    const issued = await this.issue(admin);
    return {
      accessToken: issued.accessToken,
      refreshToken: issued.refreshToken,
      expiresIn: issued.expiresIn,
    };
  }

  async signOut(adminId: string, refreshToken?: string): Promise<void> {
    if (refreshToken) {
      await this.refreshTokens.delete({
        admin_id: adminId,
        token_hash: this.hashToken(refreshToken),
      });
    } else {
      await this.refreshTokens.delete({ admin_id: adminId });
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────
  private async issue(admin: AdminEntity): Promise<AdminAuthResponse> {
    const perms = await this.resolvePermissions(admin);
    const payload: JwtPayload = {
      sub: admin.id,
      email: admin.email,
      role: admin.role,
      permissions: perms,
      actor: 'admin',
    };
    const accessExpires =
      this.config.get<string>('JWT_ACCESS_EXPIRES') ?? '15m';
    const refreshExpires =
      this.config.get<string>('JWT_REFRESH_EXPIRES') ?? '7d';
    const accessToken = await this.jwt.signAsync(payload, {
      secret: this.config.get<string>('JWT_ACCESS_SECRET'),
      expiresIn: accessExpires as unknown as number,
    });
    const refreshRaw = randomBytes(48).toString('base64url');
    await this.refreshTokens.save(
      this.refreshTokens.create({
        admin_id: admin.id,
        token_hash: this.hashToken(refreshRaw),
        expires_at: this.addDuration(new Date(), refreshExpires),
      }),
    );
    return {
      accessToken,
      refreshToken: refreshRaw,
      expiresIn: this.parseSeconds(accessExpires),
      adminId: admin.id,
      email: admin.email,
      displayName: admin.display_name,
      role: admin.role,
    };
  }

  private async resolvePermissions(admin: AdminEntity): Promise<string[]> {
    if (admin.role === 'superadmin') return ['*'];
    const rows = await this.permissions.findBy({ user_id: admin.id });
    return rows.map((r) => r.permission);
  }

  private hashToken(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }

  private parseSeconds(s: string): number {
    const m = /^(\d+)([smhd])$/.exec(s);
    if (!m) return 900;
    const n = parseInt(m[1], 10);
    return n * ({ s: 1, m: 60, h: 3600, d: 86400 }[m[2]] ?? 1);
  }

  private addDuration(base: Date, s: string): Date {
    return new Date(base.getTime() + this.parseSeconds(s) * 1000);
  }
}
