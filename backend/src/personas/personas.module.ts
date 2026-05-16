import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Controller, Get, UseGuards } from '@nestjs/common';
import { Injectable, NotFoundException, Param } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ApiBearerAuth, ApiOkResponse, ApiOperation, ApiTags } from '@nestjs/swagger';
import { PersonaEntity } from '../database/entities/persona.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Injectable()
class PersonasService {
  constructor(
    @InjectRepository(PersonaEntity)
    private readonly repo: Repository<PersonaEntity>,
  ) {}

  list() {
    return this.repo.find({
      where: { is_active: true },
      order: { name: 'ASC' },
    });
  }

  async get(id: string) {
    const p = await this.repo.findOne({ where: { id } });
    if (!p || !p.is_active) throw new NotFoundException({ i18nKey: 'persona.not_found' });
    return p;
  }
}

@ApiTags('Personas')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('personas')
class PersonasController {
  constructor(private readonly svc: PersonasService) {}

  @Get()
  @ApiOperation({ summary: 'List active tutor personas' })
  @ApiOkResponse({ type: [Object] })
  list() {
    return this.svc.list();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get one persona by id' })
  get(@Param('id') id: string) {
    return this.svc.get(id);
  }
}

@Module({
  imports: [TypeOrmModule.forFeature([PersonaEntity])],
  providers: [PersonasService],
  controllers: [PersonasController],
  exports: [PersonasService],
})
export class PersonasModule {}
