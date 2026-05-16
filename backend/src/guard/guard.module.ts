import { Module, Global } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ContentGuardService } from './content-guard.service';
import { GuardViolationEntity } from '../database/entities/guard-violation.entity';

@Global()
@Module({
  imports: [TypeOrmModule.forFeature([GuardViolationEntity])],
  providers: [ContentGuardService],
  exports: [ContentGuardService],
})
export class GuardModule {}
