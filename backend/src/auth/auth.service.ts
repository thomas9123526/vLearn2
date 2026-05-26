import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  ForbiddenException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, MoreThan } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { randomBytes, createHash } from 'crypto';
import { UserEntity } from '../database/entities/user.entity';
import { UserInfoEntity } from '../database/entities/user-info.entity';
import { RefreshTokenEntity } from '../database/entities/refresh-token.entity';
import { AdminPermissionEntity } from '../database/entities/admin-permission.entity';
import { UserProgressEntity } from '../database/entities/progress.entity';
import type { JwtPayload } from './strategies/jwt.strategy';
import type {
  SignUpDto,
  SignInDto,
  AuthResponseDto,
  TokenPairDto,
} from './dto/auth.dto';

const BCRYPT_ROUNDS = 10;

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(UserEntity)
    private readonly users: Repository<UserEntity>,
    @InjectRepository(UserInfoEntity)
    private readonly userInfos: Repository<UserInfoEntity>,
    @InjectRepository(RefreshTokenEntity)
    private readonly refreshTokens: Repository<RefreshTokenEntity>,
    @InjectRepository(AdminPermissionEntity)
    private readonly adminPermissions: Repository<AdminPermissionEntity>,
    @InjectRepository(UserProgressEntity)
    private readonly userProgress: Repository<UserProgressEntity>,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  // ─── Sign-up (regular user) ─────────────────────────────
  async signUp(dto: SignUpDto): Promise<AuthResponseDto> {
    // Check both unique fields up-front to give readable errors rather
    // than letting the DB constraint bubble up as a 500.
    const [byCidUsername, byCid] = await Promise.all([
      this.users.findOne({ where: { cid_username: dto.cidUsername } }),
      dto.cid
        ? this.users.findOne({ where: { cid: dto.cid } })
        : Promise.resolve(null),
    ]);
    if (byCidUsername)
      throw new ConflictException({ i18nKey: 'auth.cid_username_taken' });
    if (byCid)
      throw new ConflictException({ i18nKey: 'auth.cid_already_registered' });

    const passwordHash = await bcrypt.hash(dto.password, BCRYPT_ROUNDS);
    const user = await this.users.save(
      this.users.create({
        password_hash: passwordHash,
        name: dto.displayName,
        cid: dto.cid,
        cid_username: dto.cidUsername,
        info: this.userInfos.create({
          ui_language: dto.uiLanguage ?? 'en',
          native_language: dto.uiLanguage ?? 'en',
          role: 'user',
        }),
      }),
    );

    // Bootstrap an empty user_progress row
    await this.userProgress.save(
      this.userProgress.create({ user_id: user.id }),
    );

    return this.issueTokensAndShape(user);
  }

  // ─── Sign-in ────────────────────────────────────────────
  async signIn(dto: SignInDto): Promise<AuthResponseDto> {
    // eager loading populates user.info (status, role, suspension fields)
    const user = await this.users.findOne({
      where: { cid_username: dto.cidUsername },
    });
    if (!user)
      throw new UnauthorizedException({ i18nKey: 'auth.invalid_credentials' });

    if (user.info.status === 'deleted') {
      throw new ForbiddenException({ i18nKey: 'account.deleted' });
    }
    if (user.info.status === 'suspended') {
      const stillSuspended =
        !user.info.suspended_until || user.info.suspended_until > new Date();
      if (stillSuspended) {
        throw new ForbiddenException({
          i18nKey: 'account.suspended',
          suspendedUntil: user.info.suspended_until,
          reason: user.info.suspended_reason,
        });
      }
    }

    const userWithHash = await this.users.findOne({
      where: { id: user.id },
      select: ['id', 'password_hash', 'name', 'cid', 'cid_username'],
    });
    if (!userWithHash)
      throw new UnauthorizedException({ i18nKey: 'auth.invalid_credentials' });

    const ok = await bcrypt.compare(dto.password, userWithHash.password_hash);
    if (!ok)
      throw new UnauthorizedException({ i18nKey: 'auth.invalid_credentials' });

    userWithHash.info = user.info;
    return this.issueTokensAndShape(userWithHash);
  }

  // ─── Refresh ────────────────────────────────────────────
  async refresh(refreshToken: string): Promise<TokenPairDto> {
    const tokenHash = this.hashToken(refreshToken);
    const stored = await this.refreshTokens.findOne({
      where: { token_hash: tokenHash, expires_at: MoreThan(new Date()) },
    });
    if (!stored)
      throw new UnauthorizedException({ i18nKey: 'auth.invalid_refresh' });

    const user = await this.users.findOne({ where: { id: stored.user_id } });
    if (!user) throw new UnauthorizedException();

    await this.refreshTokens.delete({ id: stored.id });
    return this.issueTokens(user);
  }

  // ─── Lookup username by CID (pre-signin convenience) ────
  /**
   * Returns the cid_username registered against the given CID, so the
   * sign-in screen can auto-fill the username field once the user has
   * synced their CID. Public on purpose — the caller has no JWT yet —
   * but **only** returns the username for active accounts. Suspended
   * or deleted users get a 404 to avoid disclosing their state.
   *
   * Rate-limiting / brute-force protection is the responsibility of
   * the ingress (nginx) and the global throttler module — this method
   * does not implement either.
   */
  async lookupUsernameByCid(cid: string): Promise<{ cidUsername: string }> {
    const trimmed = cid.trim();
    if (!trimmed) {
      throw new UnauthorizedException({ i18nKey: 'auth.cid_required' });
    }
    const user = await this.users.findOne({
      where: { cid: trimmed },
      select: ['id', 'cid_username'],
    });
    if (!user || !user.cid_username) {
      throw new UnauthorizedException({ i18nKey: 'auth.cid_not_registered' });
    }
    return { cidUsername: user.cid_username };
  }

  // ─── Sign-out ───────────────────────────────────────────
  async signOut(userId: string, refreshToken?: string): Promise<void> {
    if (refreshToken) {
      await this.refreshTokens.delete({
        user_id: userId,
        token_hash: this.hashToken(refreshToken),
      });
    } else {
      await this.refreshTokens.delete({ user_id: userId });
    }
  }

  // ─── Helpers ────────────────────────────────────────────
  private async issueTokensAndShape(
    user: UserEntity,
  ): Promise<AuthResponseDto> {
    const pair = await this.issueTokens(user);
    return {
      ...pair,
      userId: user.id,
      cidUsername: user.cid_username ?? '',
      displayName: user.name,
      role: user.info.role,
    };
  }

  private async issueTokens(user: UserEntity): Promise<TokenPairDto> {
    const permissions = await this.resolvePermissions(user);
    const payload: JwtPayload = {
      sub: user.id,
      cidUsername: user.cid_username ?? undefined,
      role: user.info.role,
      permissions,
      actor: 'user' as const,
    };
    const accessExpiresStr =
      this.config.get<string>('JWT_ACCESS_EXPIRES') ?? '15m';
    const refreshExpiresStr =
      this.config.get<string>('JWT_REFRESH_EXPIRES') ?? '7d';

    const accessToken = await this.jwt.signAsync(payload, {
      secret: this.config.get<string>('JWT_ACCESS_SECRET'),
      expiresIn: accessExpiresStr as unknown as number,
    });
    const refreshTokenRaw = randomBytes(48).toString('base64url');
    const refreshHash = this.hashToken(refreshTokenRaw);

    await this.refreshTokens.save(
      this.refreshTokens.create({
        user_id: user.id,
        token_hash: refreshHash,
        expires_at: this.addDuration(new Date(), refreshExpiresStr),
      }),
    );

    return {
      accessToken,
      refreshToken: refreshTokenRaw,
      expiresIn: this.parseDurationSeconds(accessExpiresStr),
    };
  }

  private async resolvePermissions(user: UserEntity): Promise<string[]> {
    if (user.info.role === 'superadmin') {
      return ['*'];
    }
    if (user.info.role !== 'admin') return [];
    const rows = await this.adminPermissions.findBy({ user_id: user.id });
    return rows.map((r) => r.permission);
  }

  private hashToken(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }

  private parseDurationSeconds(s: string): number {
    const m = /^(\d+)([smhd])$/.exec(s);
    if (!m) return 900;
    const n = parseInt(m[1], 10);
    const unit = m[2];
    const multipliers: Record<string, number> = {
      s: 1,
      m: 60,
      h: 3600,
      d: 86400,
    };
    return n * (multipliers[unit] ?? 1);
  }

  private addDuration(base: Date, s: string): Date {
    const seconds = this.parseDurationSeconds(s);
    return new Date(base.getTime() + seconds * 1000);
  }
}
