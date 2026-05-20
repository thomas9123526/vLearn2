import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { EntityManager, Repository } from 'typeorm';
import { AdminAuditLogEntity } from '../../database/entities/admin-audit-log.entity';

export interface AuditLogEntry {
  actorId: string;
  action: string;
  targetType: string;
  targetId: string;
  oldValue?: Record<string, unknown> | null;
  newValue?: Record<string, unknown> | null;
  metadata?: Record<string, unknown> | null;
}

export interface AuditLogListFilters {
  actor?: string;
  action?: string;
  targetType?: string;
  targetId?: string;
  since?: Date;
  until?: Date;
  page: number;
  limit: number;
}

export interface AuditLogListItem {
  id: string;
  user_id: string | null;
  actor_email: string | null;
  actor_display_name: string | null;
  action: string;
  target_type: string;
  target_id: string;
  old_value: unknown;
  new_value: unknown;
  metadata: unknown;
  created_at: Date;
}

/**
 * Records and queries admin-audit-log rows.
 *
 * `record(entry, em)` accepts an optional EntityManager so callers can pin
 * the audit insert to their mutation's transaction — if the mutation
 * rolls back, the audit row goes with it.
 */
@Injectable()
export class AdminAuditLogService {
  constructor(
    @InjectRepository(AdminAuditLogEntity)
    private readonly repo: Repository<AdminAuditLogEntity>,
  ) {}

  async record(entry: AuditLogEntry, em?: EntityManager): Promise<void> {
    const row = {
      user_id: entry.actorId,
      action: entry.action,
      target_type: entry.targetType,
      target_id: entry.targetId,
      old_value: entry.oldValue ?? null,
      new_value: entry.newValue ?? null,
      metadata: entry.metadata ?? null,
    };
    const r = em ? em.getRepository(AdminAuditLogEntity) : this.repo;
    await r.save(row);
  }

  async list(filters: AuditLogListFilters): Promise<{
    items: AuditLogListItem[];
    total: number;
    page: number;
    limit: number;
  }> {
    const base = this.repo
      .createQueryBuilder('a')
      .leftJoin('vl_admins', 'actor', 'actor.id = a.user_id');

    if (filters.actor) base.andWhere('a.user_id = :actor', { actor: filters.actor });
    if (filters.action) base.andWhere('a.action = :action', { action: filters.action });
    if (filters.targetType) base.andWhere('a.target_type = :tt', { tt: filters.targetType });
    if (filters.targetId) base.andWhere('a.target_id = :tid', { tid: filters.targetId });
    if (filters.since) base.andWhere('a.created_at >= :since', { since: filters.since });
    if (filters.until) base.andWhere('a.created_at < :until', { until: filters.until });

    const total = await base.clone().getCount();

    const rows = await base
      .select([
        'a.id AS id',
        'a.user_id AS user_id',
        'actor.email AS actor_email',
        'actor.display_name AS actor_display_name',
        'a.action AS action',
        'a.target_type AS target_type',
        'a.target_id AS target_id',
        'a.old_value AS old_value',
        'a.new_value AS new_value',
        'a.metadata AS metadata',
        'a.created_at AS created_at',
      ])
      .orderBy('a.created_at', 'DESC')
      .offset((filters.page - 1) * filters.limit)
      .limit(filters.limit)
      .getRawMany();

    return {
      items: rows.map((r) => ({
        id: r.id,
        user_id: r.user_id,
        actor_email: r.actor_email,
        actor_display_name: r.actor_display_name,
        action: r.action,
        target_type: r.target_type,
        target_id: r.target_id,
        old_value: r.old_value,
        new_value: r.new_value,
        metadata: r.metadata,
        created_at: r.created_at,
      })),
      total,
      page: filters.page,
      limit: filters.limit,
    };
  }
}
