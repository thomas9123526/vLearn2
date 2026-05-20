import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  SetMetadata,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AdminPermissionsService } from './admin-permissions.service';

export const PERMISSIONS_METADATA_KEY = 'permissions';

export const RequirePermission = (...permissions: string[]) =>
  SetMetadata(PERMISSIONS_METADATA_KEY, permissions);

@Injectable()
export class PermissionGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly permissions: AdminPermissionsService,
  ) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    const required = this.reflector.getAllAndOverride<string[]>(
      PERMISSIONS_METADATA_KEY,
      [ctx.getHandler(), ctx.getClass()],
    ) ?? [];
    if (required.length === 0) return true;

    const req = ctx.switchToHttp().getRequest<{ user?: { sub: string; role: string } }>();
    const user = req.user;
    if (!user) throw new UnauthorizedException();

    if (user.role === 'superadmin') return true;
    if (user.role !== 'admin') {
      throw new ForbiddenException({ i18nKey: 'admin.not_admin', missing: required });
    }

    const granted = await this.permissions.getForUser(user.sub);
    const missing = required.filter((p) => !granted.has(p));
    if (missing.length > 0) {
      throw new ForbiddenException({ i18nKey: 'admin.missing_permission', missing });
    }
    return true;
  }
}
