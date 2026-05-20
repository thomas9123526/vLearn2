import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { EntityManager, Repository } from 'typeorm';
import { AdminPermissionEntity } from '../../database/entities/admin-permission.entity';

@Injectable()
export class AdminPermissionsService {
  private cache = new Map<string, { perms: Set<string>; at: number }>();
  private readonly ttlMs = 30_000;

  constructor(
    @InjectRepository(AdminPermissionEntity)
    private readonly repo: Repository<AdminPermissionEntity>,
  ) {}

  private repoFor(em?: EntityManager): Repository<AdminPermissionEntity> {
    return em ? em.getRepository(AdminPermissionEntity) : this.repo;
  }

  async getForUser(userId: string, em?: EntityManager): Promise<Set<string>> {
    if (!em) {
      const hit = this.cache.get(userId);
      if (hit && Date.now() - hit.at < this.ttlMs) return hit.perms;
    }

    const rows = await this.repoFor(em).findBy({ user_id: userId });
    const perms = new Set(rows.map((r) => r.permission));
    if (!em) this.cache.set(userId, { perms, at: Date.now() });
    return perms;
  }

  async grant(
    userId: string,
    permissions: string[],
    grantedBy: string,
    em?: EntityManager,
  ): Promise<void> {
    const r = this.repoFor(em);
    for (const p of permissions) {
      await r.upsert(
        { user_id: userId, permission: p, granted_by: grantedBy },
        ['user_id', 'permission'],
      );
    }
    this.invalidate(userId);
  }

  async revoke(userId: string, permissions: string[], em?: EntityManager): Promise<void> {
    if (permissions.length === 0) return;
    await this.repoFor(em)
      .createQueryBuilder()
      .delete()
      .where('user_id = :uid AND permission IN (:...perms)', { uid: userId, perms: permissions })
      .execute();
    this.invalidate(userId);
  }

  async replaceAll(
    userId: string,
    permissions: string[],
    grantedBy: string,
    em?: EntityManager,
  ): Promise<void> {
    const r = this.repoFor(em);
    await r.delete({ user_id: userId });
    if (permissions.length > 0) {
      await r.save(
        permissions.map((p) =>
          r.create({ user_id: userId, permission: p, granted_by: grantedBy }),
        ),
      );
    }
    this.invalidate(userId);
  }

  invalidate(userId: string): void {
    this.cache.delete(userId);
  }
}
