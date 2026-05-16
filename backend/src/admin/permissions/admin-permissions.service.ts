import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AdminPermissionEntity } from '../../database/entities/admin-permission.entity';

@Injectable()
export class AdminPermissionsService {
  private cache = new Map<string, { perms: Set<string>; at: number }>();
  private readonly ttlMs = 30_000;

  constructor(
    @InjectRepository(AdminPermissionEntity)
    private readonly repo: Repository<AdminPermissionEntity>,
  ) {}

  async getForUser(userId: string): Promise<Set<string>> {
    const hit = this.cache.get(userId);
    if (hit && Date.now() - hit.at < this.ttlMs) return hit.perms;

    const rows = await this.repo.findBy({ user_id: userId });
    const perms = new Set(rows.map((r) => r.permission));
    this.cache.set(userId, { perms, at: Date.now() });
    return perms;
  }

  async grant(userId: string, permissions: string[], grantedBy: string): Promise<void> {
    for (const p of permissions) {
      await this.repo.upsert(
        { user_id: userId, permission: p, granted_by: grantedBy },
        ['user_id', 'permission'],
      );
    }
    this.invalidate(userId);
  }

  async revoke(userId: string, permissions: string[]): Promise<void> {
    if (permissions.length === 0) return;
    await this.repo
      .createQueryBuilder()
      .delete()
      .where('user_id = :uid AND permission IN (:...perms)', { uid: userId, perms: permissions })
      .execute();
    this.invalidate(userId);
  }

  async replaceAll(userId: string, permissions: string[], grantedBy: string): Promise<void> {
    await this.repo.delete({ user_id: userId });
    if (permissions.length > 0) {
      await this.repo.save(
        permissions.map((p) =>
          this.repo.create({ user_id: userId, permission: p, granted_by: grantedBy }),
        ),
      );
    }
    this.invalidate(userId);
  }

  invalidate(userId: string): void {
    this.cache.delete(userId);
  }
}
