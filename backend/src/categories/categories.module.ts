import { Controller, Get, Injectable, Module, UseGuards } from '@nestjs/common';
import { TypeOrmModule, InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CategoryEntity } from '../database/entities/category.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Injectable()
class CategoriesService {
  constructor(
    @InjectRepository(CategoryEntity)
    private readonly repo: Repository<CategoryEntity>,
  ) {}

  /** Active categories, ordered for stable display in clients. */
  listActive() {
    return this.repo.find({
      where: { is_active: true },
      order: { order_index: 'ASC', slug: 'ASC' },
    });
  }
}

@ApiTags('Categories')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('categories')
class CategoriesController {
  constructor(private readonly svc: CategoriesService) {}

  @Get()
  @ApiOperation({ summary: 'List active scenario categories' })
  list() {
    return this.svc.listActive();
  }
}

@Module({
  imports: [TypeOrmModule.forFeature([CategoryEntity])],
  providers: [CategoriesService],
  controllers: [CategoriesController],
  exports: [CategoriesService],
})
export class CategoriesModule {}
