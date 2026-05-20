import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Injectable,
  Module,
  NotFoundException,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { InjectRepository, TypeOrmModule } from '@nestjs/typeorm';
import { DataSource, Repository, In } from 'typeorm';
import { ApiBearerAuth, ApiOperation, ApiProperty, ApiQuery, ApiTags } from '@nestjs/swagger';
import {
  IsBoolean,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { JwtPayload } from '../auth/strategies/jwt.strategy';
import {
  NewsPostEntity,
  NewsReadStatusEntity,
} from '../database/entities/news.entity';
import type { NewsStatus } from '../database/entities/news.entity';
import { PermissionGuard, RequirePermission } from '../admin/permissions/permission.guard';
import { AdminAuditLogService } from '../admin/audit/admin-audit-log.service';

class I18nTextDto {
  @ApiProperty() @IsString() en!: string;
  @ApiProperty({ required: false }) @IsString() @IsOptional() ko?: string;
  @ApiProperty({ required: false }) @IsString() @IsOptional() zh?: string;
}

class CreateNewsDto {
  @ApiProperty() @IsString() slug!: string;
  @ApiProperty({ type: I18nTextDto }) @ValidateNested() @Type(() => I18nTextDto) title!: I18nTextDto;
  @ApiProperty({ type: I18nTextDto }) @ValidateNested() @Type(() => I18nTextDto) body!: I18nTextDto;
  @ApiProperty({ type: I18nTextDto, required: false }) @ValidateNested() @Type(() => I18nTextDto) @IsOptional() summary?: I18nTextDto;
  @ApiProperty({ required: false }) @IsBoolean() @IsOptional() pinned?: boolean;
}

class UpdateNewsDto {
  @ApiProperty({ required: false }) @IsString() @IsOptional() slug?: string;
  @ApiProperty({ type: I18nTextDto, required: false }) @ValidateNested() @Type(() => I18nTextDto) @IsOptional() title?: I18nTextDto;
  @ApiProperty({ type: I18nTextDto, required: false }) @ValidateNested() @Type(() => I18nTextDto) @IsOptional() body?: I18nTextDto;
  @ApiProperty({ type: I18nTextDto, required: false }) @ValidateNested() @Type(() => I18nTextDto) @IsOptional() summary?: I18nTextDto;
  @ApiProperty({ required: false }) @IsBoolean() @IsOptional() pinned?: boolean;
}

@Injectable()
export class NewsService {
  constructor(
    @InjectRepository(NewsPostEntity)
    private readonly posts: Repository<NewsPostEntity>,
    @InjectRepository(NewsReadStatusEntity)
    private readonly reads: Repository<NewsReadStatusEntity>,
    private readonly audit: AdminAuditLogService,
    private readonly dataSource: DataSource,
  ) {}

  /** List published posts for app users; annotates each with a `read` boolean. */
  async listForUser(userId: string, opts: { page: number; limit: number }) {
    const limit = Math.min(Math.max(opts.limit, 1), 50);
    const offset = Math.max(opts.page - 1, 0) * limit;

    const [rows, total] = await this.posts
      .createQueryBuilder('p')
      .where("p.status = 'published'")
      .orderBy('p.pinned', 'DESC')
      .addOrderBy('p.published_at', 'DESC')
      .skip(offset)
      .take(limit)
      .getManyAndCount();

    if (rows.length === 0) return { items: [], total, page: opts.page, limit };

    const reads = await this.reads.find({
      where: { user_id: userId, news_post_id: In(rows.map((r) => r.id)) },
    });
    const readSet = new Set(reads.map((r) => r.news_post_id));

    return {
      items: rows.map((r) => ({ ...r, read: readSet.has(r.id) })),
      total,
      page: opts.page,
      limit,
    };
  }

  async getForUser(userId: string, idOrSlug: string) {
    const post = await this.findByIdOrSlug(idOrSlug);
    if (!post || post.status !== 'published') {
      throw new NotFoundException({ i18nKey: 'news.not_found' });
    }
    await this.markRead(userId, post.id);
    return { ...post, read: true };
  }

  async markRead(userId: string, postId: string) {
    await this.reads
      .createQueryBuilder()
      .insert()
      .values({ user_id: userId, news_post_id: postId })
      .orIgnore()
      .execute();
    return { ok: true };
  }

  async markAllRead(userId: string) {
    // Insert read rows for every currently-published post the user hasn't read yet.
    await this.reads.query(
      `INSERT INTO vl_news_read_status (user_id, news_post_id)
         SELECT $1, p.id FROM vl_news_posts p
          WHERE p.status = 'published'
       ON CONFLICT DO NOTHING`,
      [userId],
    );
    return { ok: true };
  }

  async unreadCount(userId: string): Promise<{ count: number }> {
    const row: Array<{ count: number }> = await this.reads.query(
      `SELECT COUNT(*)::int AS count
         FROM vl_news_posts p
         LEFT JOIN vl_news_read_status r
           ON r.news_post_id = p.id AND r.user_id = $1
        WHERE p.status = 'published' AND r.user_id IS NULL`,
      [userId],
    );
    return { count: row[0]?.count ?? 0 };
  }

  // ─── Admin ──────────────────────────────────────────────

  /** Includes drafts and archived posts. */
  async adminList(opts: { status?: NewsStatus; page: number; limit: number }) {
    const limit = Math.min(Math.max(opts.limit, 1), 100);
    const offset = Math.max(opts.page - 1, 0) * limit;
    const qb = this.posts.createQueryBuilder('p');
    if (opts.status) qb.where('p.status = :s', { s: opts.status });
    qb.orderBy('p.pinned', 'DESC')
      .addOrderBy('p.created_at', 'DESC')
      .skip(offset)
      .take(limit);
    const [items, total] = await qb.getManyAndCount();
    return { items, total, page: opts.page, limit };
  }

  async adminGet(id: string) {
    const post = await this.posts.findOne({ where: { id } });
    if (!post) throw new NotFoundException({ i18nKey: 'news.not_found' });
    return post;
  }

  async create(dto: CreateNewsDto, authorId: string) {
    return this.dataSource.transaction(async (em) => {
      const repo = em.getRepository(NewsPostEntity);
      const existing = await repo.findOne({ where: { slug: dto.slug } });
      if (existing) throw new BadRequestException({ i18nKey: 'news.slug_taken' });
      const post = repo.create({
        slug: dto.slug,
        title: dto.title,
        body: dto.body,
        summary: dto.summary ?? null,
        pinned: dto.pinned ?? false,
        author_id: authorId,
        status: 'draft',
      });
      const saved = await repo.save(post);
      await this.audit.record(
        {
          actorId: authorId,
          action: 'news.create',
          targetType: 'news',
          targetId: saved.id,
          newValue: { slug: saved.slug, pinned: saved.pinned, status: saved.status },
        },
        em,
      );
      return saved;
    });
  }

  async update(id: string, dto: UpdateNewsDto, actorId: string) {
    return this.dataSource.transaction(async (em) => {
      const repo = em.getRepository(NewsPostEntity);
      const post = await repo.findOne({ where: { id } });
      if (!post) throw new NotFoundException({ i18nKey: 'news.not_found' });

      const before: Record<string, unknown> = {};
      const after: Record<string, unknown> = {};

      if (dto.slug && dto.slug !== post.slug) {
        const collision = await repo.findOne({ where: { slug: dto.slug } });
        if (collision) throw new BadRequestException({ i18nKey: 'news.slug_taken' });
        before.slug = post.slug;
        after.slug = dto.slug;
        post.slug = dto.slug;
      }
      if (dto.title) {
        before.title = post.title;
        after.title = dto.title;
        post.title = dto.title;
      }
      if (dto.body) {
        before.body = post.body;
        after.body = dto.body;
        post.body = dto.body;
      }
      if (dto.summary !== undefined) {
        const next = dto.summary ?? null;
        if (next !== post.summary) {
          before.summary = post.summary;
          after.summary = next;
          post.summary = next;
        }
      }
      if (dto.pinned !== undefined && dto.pinned !== post.pinned) {
        before.pinned = post.pinned;
        after.pinned = dto.pinned;
        post.pinned = dto.pinned;
      }

      const saved = await repo.save(post);
      if (Object.keys(after).length > 0) {
        await this.audit.record(
          {
            actorId,
            action: 'news.update',
            targetType: 'news',
            targetId: id,
            oldValue: before,
            newValue: after,
          },
          em,
        );
      }
      return saved;
    });
  }

  async publish(id: string, actorId: string) {
    return this.dataSource.transaction(async (em) => {
      const repo = em.getRepository(NewsPostEntity);
      const post = await repo.findOne({ where: { id } });
      if (!post) throw new NotFoundException({ i18nKey: 'news.not_found' });
      const oldStatus = post.status;
      post.status = 'published';
      if (!post.published_at) post.published_at = new Date();
      const saved = await repo.save(post);
      await this.audit.record(
        {
          actorId,
          action: 'news.publish',
          targetType: 'news',
          targetId: id,
          oldValue: { status: oldStatus },
          newValue: { status: 'published' },
        },
        em,
      );
      return saved;
    });
  }

  async archive(id: string, actorId: string) {
    return this.dataSource.transaction(async (em) => {
      const repo = em.getRepository(NewsPostEntity);
      const post = await repo.findOne({ where: { id } });
      if (!post) throw new NotFoundException({ i18nKey: 'news.not_found' });
      const oldStatus = post.status;
      post.status = 'archived';
      const saved = await repo.save(post);
      await this.audit.record(
        {
          actorId,
          action: 'news.archive',
          targetType: 'news',
          targetId: id,
          oldValue: { status: oldStatus },
          newValue: { status: 'archived' },
        },
        em,
      );
      return saved;
    });
  }

  async remove(id: string, actorId: string) {
    await this.dataSource.transaction(async (em) => {
      const repo = em.getRepository(NewsPostEntity);
      const post = await repo.findOne({ where: { id } });
      if (!post) throw new NotFoundException({ i18nKey: 'news.not_found' });
      await repo.delete({ id });
      await this.audit.record(
        {
          actorId,
          action: 'news.delete',
          targetType: 'news',
          targetId: id,
          oldValue: { slug: post.slug, status: post.status },
        },
        em,
      );
    });
    return { ok: true };
  }

  private async findByIdOrSlug(key: string) {
    const isUuid = /^[0-9a-f-]{36}$/i.test(key);
    return this.posts.findOne({
      where: isUuid ? { id: key } : { slug: key },
    });
  }
}

@ApiTags('News')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('news')
export class NewsController {
  constructor(private readonly svc: NewsService) {}

  @Get()
  @ApiOperation({ summary: 'List published news posts with per-user read flags' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  list(
    @CurrentUser() user: JwtPayload,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.svc.listForUser(user.sub, {
      page: page ? parseInt(page, 10) : 1,
      limit: limit ? parseInt(limit, 10) : 20,
    });
  }

  @Get('unread-count')
  @ApiOperation({ summary: 'Current unread count for the bell-icon badge' })
  unreadCount(@CurrentUser() user: JwtPayload) {
    return this.svc.unreadCount(user.sub);
  }

  @Post('read-all')
  @ApiOperation({ summary: 'Mark every currently-published post as read for this user' })
  readAll(@CurrentUser() user: JwtPayload) {
    return this.svc.markAllRead(user.sub);
  }

  @Post(':id/read')
  @ApiOperation({ summary: 'Idempotent mark-read for one post' })
  read(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.svc.markRead(user.sub, id);
  }

  @Get(':idOrSlug')
  @ApiOperation({ summary: 'Get a single published post; auto-marks read' })
  get(@CurrentUser() user: JwtPayload, @Param('idOrSlug') key: string) {
    return this.svc.getForUser(user.sub, key);
  }
}

@ApiTags('Admin / News')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionGuard)
@Controller('admin/news')
export class AdminNewsController {
  constructor(private readonly svc: NewsService) {}

  @Get()
  @RequirePermission('news.view')
  @ApiOperation({ summary: 'List all news posts (drafts included)' })
  list(
    @Query('status') status?: NewsStatus,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.svc.adminList({
      status,
      page: page ? parseInt(page, 10) : 1,
      limit: limit ? parseInt(limit, 10) : 20,
    });
  }

  @Get(':id')
  @RequirePermission('news.view')
  get(@Param('id') id: string) {
    return this.svc.adminGet(id);
  }

  @Post()
  @RequirePermission('news.edit')
  create(@CurrentUser() user: JwtPayload, @Body() dto: CreateNewsDto) {
    return this.svc.create(dto, user.sub);
  }

  @Patch(':id')
  @RequirePermission('news.edit')
  update(@CurrentUser() user: JwtPayload, @Param('id') id: string, @Body() dto: UpdateNewsDto) {
    return this.svc.update(id, dto, user.sub);
  }

  @Post(':id/publish')
  @RequirePermission('news.edit')
  publish(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.svc.publish(id, user.sub);
  }

  @Post(':id/archive')
  @RequirePermission('news.edit')
  archive(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.svc.archive(id, user.sub);
  }

  @Delete(':id')
  @RequirePermission('news.delete')
  remove(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.svc.remove(id, user.sub);
  }
}

@Module({
  imports: [TypeOrmModule.forFeature([NewsPostEntity, NewsReadStatusEntity])],
  controllers: [NewsController, AdminNewsController],
  providers: [NewsService],
  exports: [NewsService],
})
export class NewsModule {}
