import { Module, Injectable, Controller, Get, Param, NotFoundException, UseGuards } from '@nestjs/common';
import { TypeOrmModule, InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CourseEntity, CourseScenarioEntity } from '../database/entities/course.entity';
import { ScenarioEntity } from '../database/entities/scenario.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Injectable()
class CoursesService {
  constructor(
    @InjectRepository(CourseEntity)
    private readonly courses: Repository<CourseEntity>,
    @InjectRepository(CourseScenarioEntity)
    private readonly memberships: Repository<CourseScenarioEntity>,
    @InjectRepository(ScenarioEntity)
    private readonly scenarios: Repository<ScenarioEntity>,
  ) {}

  list() {
    return this.courses.find({
      where: { status: 'published' },
      order: { order_index: 'ASC' },
    });
  }

  async get(idOrSlug: string) {
    const isUuid = /^[0-9a-f-]{36}$/i.test(idOrSlug);
    const course = await this.courses.findOne({
      where: isUuid ? { id: idOrSlug } : { slug: idOrSlug },
    });
    if (!course || course.status !== 'published') {
      throw new NotFoundException({ i18nKey: 'course.not_found' });
    }
    const memberships = await this.memberships.find({
      where: { course_id: course.id },
      order: { order_index: 'ASC' },
    });
    const scenarioIds = memberships.map((m) => m.scenario_id);
    const scenarios = scenarioIds.length
      ? await this.scenarios.find({ where: { id: In(scenarioIds) } })
      : [];
    const orderedScenarios = memberships.map((m) =>
      scenarios.find((s) => s.id === m.scenario_id),
    ).filter(Boolean);
    return { ...course, scenarios: orderedScenarios };
  }
}

@ApiTags('Courses')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('courses')
class CoursesController {
  constructor(private readonly svc: CoursesService) {}

  @Get()
  @ApiOperation({ summary: 'List published courses' })
  list() {
    return this.svc.list();
  }

  @Get(':idOrSlug')
  @ApiOperation({ summary: 'Get course by id or slug, with ordered scenarios' })
  get(@Param('idOrSlug') key: string) {
    return this.svc.get(key);
  }
}

@Module({
  imports: [TypeOrmModule.forFeature([CourseEntity, CourseScenarioEntity, ScenarioEntity])],
  providers: [CoursesService],
  controllers: [CoursesController],
  exports: [CoursesService],
})
export class CoursesModule {}
