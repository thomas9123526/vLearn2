import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';

export interface JwtPayload {
  sub: string;
  cidUsername?: string;
  email?: string; // legacy — present on admin tokens, absent on user tokens
  role: 'user' | 'admin' | 'superadmin';
  permissions: string[];
  /**
   * Discriminator so guards can tell which table the `sub` points to.
   * Missing on tokens issued before the admins-separate-table migration —
   * treat absent as `'user'` for backward compatibility.
   */
  actor?: 'user' | 'admin';
  iat?: number;
  exp?: number;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(config: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: config.get<string>('JWT_ACCESS_SECRET') ?? '',
    });
  }

  validate(payload: JwtPayload): JwtPayload {
    return payload;
  }
}
