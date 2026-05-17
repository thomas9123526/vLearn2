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
import { Repository, In } from 'typeorm';
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
import type { I18nText } from '../database/entities/scenario.entity';
import { PermissionGuard, RequirePermission } from '../admin/permissions/permission.guard';

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
      `INSERT INTO news_read_status (user_id, news_post_id)
         SELECT $1, p.id FROM news_posts p
          WHERE p.status = 'published'
       ON CONFLICT DO NOTHING`,
      [userId],
    );
    return { ok: true };
  }

  async unreadCount(userId: string): Promise<{ count: number }> {
    const row = await this.reads.query(
      `SELECT COUNT(*)::int AS count
         FROM news_posts p
         LEFT JOIN news_read_status r
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
    const existing = await this.posts.findOne({ where: { slug: dto.slug } });
    if (existing) throw new BadRequestException({ i18nKey: 'news.slug_taken' });
    const post = this.posts.create({
      slug: dto.slug,
      title: dto.title,
      body: dto.body,
      summary: dto.summary ?? null,
      pinned: dto.pinned ?? false,
      author_id: authorId,
      status: 'draft',
    });
    return this.posts.save(post);
  }

  async update(id: string, dto: UpdateNewsDto) {
    const post = await this.adminGet(id);
    if (dto.slug && dto.slug !== post.slug) {
      const collision = await this.posts.findOne({ where: { slug: dto.slug } });
      if (collision) throw new BadRequestException({ i18nKey: 'news.slug_taken' });
      post.slug = dto.slug;
    }
    if (dto.title) post.title = dto.title;
    if (dto.body) post.body = dto.body;
    if (dto.summary !== undefined) post.summary = dto.summary ?? null;
    if (dto.pinned !== undefined) post.pinned = dto.pinned;
    return this.posts.save(post);
  }

  async publish(id: string) {
    const post = await this.adminGet(id);
    post.status = 'published';
    if (!post.published_at) post.published_at = new Date();
    return this.posts.save(post);
  }

  async archive(id: string) {
    const post = await this.adminGet(id);
    post.status = 'archived';
    return this.posts.save(post);
  }

  async remove(id: string) {
    const result = await this.posts.delete({ id });
    if (result.affected === 0) {
      throw new NotFoundException({ i18nKey: 'news.not_found' });
    }
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
  update(@Param('id') id: string, @Body() dto: UpdateNewsDto) {
    return this.svc.update(id, dto);
  }

  @Post(':id/publish')
  @RequirePermission('news.edit')
  publish(@Param('id') id: string) {
    return this.svc.publish(id);
  }

  @Post(':id/archive')
  @RequirePermission('news.edit')
  archive(@Param('id') id: string) {
    return this.svc.archive(id);
  }

  @Delete(':id')
  @RequirePermission('news.delete')
  remove(@Param('id') id: string) {
    return this.svc.remove(id);
  }
}

@Module({
  imports: [TypeOrmModule.forFeature([NewsPostEntity, NewsReadStatusEntity])],
  controllers: [NewsController, AdminNewsController],
  providers: [NewsService],
  exports: [NewsService],
})
export class NewsModule {}
