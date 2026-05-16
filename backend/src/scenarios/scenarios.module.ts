import { Module, Injectable, Controller, Get, Query, Param, NotFoundException, UseGuards } from '@nestjs/common';
import { TypeOrmModule, InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ApiBearerAuth, ApiOperation, ApiTags, ApiQuery } from '@nestjs/swagger';
import { ScenarioEntity } from '../database/entities/scenario.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Injectable()
class ScenariosService {
  constructor(
    @InjectRepository(ScenarioEntity)
    private readonly repo: Repository<ScenarioEntity>,
  ) {}

  list(filters: { category?: string; difficulty?: number; q?: string }) {
    const qb = this.repo
      .createQueryBuilder('s')
      .where("s.status = 'published'");
    if (filters.category) qb.andWhere('s.category = :c', { c: filters.category });
    if (filters.difficulty !== undefined) qb.andWhere('s.difficulty = :d', { d: filters.difficulty });
    if (filters.q) qb.andWhere(`s.title ->> 'en' ILIKE :q`, { q: `%${filters.q}%` });
    return qb.orderBy('s.order_index', 'ASC').getMany();
  }

  async get(idOrSlug: string) {
    const isUuid = /^[0-9a-f-]{36}$/i.test(idOrSlug);
    const s = await this.repo.findOne({
      where: isUuid ? { id: idOrSlug } : { slug: idOrSlug },
    });
    if (!s || s.status !== 'published') {
      throw new NotFoundException({ i18nKey: 'scenario.not_found' });
    }
    return s;
  }
}

@ApiTags('Scenarios')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('scenarios')
class ScenariosController {
  constructor(private readonly svc: ScenariosService) {}

  @Get()
  @ApiOperation({ summary: 'List published scenarios with optional filters' })
  @ApiQuery({ name: 'category', required: false })
  @ApiQuery({ name: 'difficulty', required: false, type: Number })
  @ApiQuery({ name: 'q', required: false })
  list(
    @Query('category') category?: string,
    @Query('difficulty') difficulty?: string,
    @Query('q') q?: string,
  ) {
    return this.svc.list({
      category,
      difficulty: difficulty ? parseInt(difficulty, 10) : undefined,
      q,
    });
  }

  @Get(':idOrSlug')
  @ApiOperation({ summary: 'Get scenario by id or slug' })
  get(@Param('idOrSlug') key: string) {
    return this.svc.get(key);
  }
}

@Module({
  imports: [TypeOrmModule.forFeature([ScenarioEntity])],
  providers: [ScenariosService],
  controllers: [ScenariosController],
  exports: [ScenariosService],
})
export class ScenariosModule {}
