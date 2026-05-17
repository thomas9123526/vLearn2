import { Module, Global } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserEntity } from '../database/entities/user.entity';
import { AdminEntity } from '../database/entities/admin.entity';
import { AdminRefreshTokenEntity } from '../database/entities/admin-refresh-token.entity';
import { AdminPermissionEntity } from '../database/entities/admin-permission.entity';
import { ConversationSessionEntity } from '../database/entities/conversation.entity';
import { ScenarioEntity } from '../database/entities/scenario.entity';
import { AdminPermissionsService } from './permissions/admin-permissions.service';
import { PermissionGuard } from './permissions/permission.guard';
import { AdminAuthController } from './admins/admin-auth.controller';
import { AdminAuthService } from './admins/admin-auth.service';
import { AdminAdminsController } from './admins/admin-admins.controller';
import { AdminStatsController } from './stats/admin-stats.controller';
import { AuthModule } from '../auth/auth.module';

@Global()
@Module({
  imports: [
    TypeOrmModule.forFeature([
      UserEntity,
      AdminEntity,
      AdminRefreshTokenEntity,
      AdminPermissionEntity,
      ConversationSessionEntity,
      ScenarioEntity,
    ]),
    AuthModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>('JWT_ACCESS_SECRET'),
      }),
    }),
  ],
  providers: [AdminPermissionsService, PermissionGuard, AdminAuthService],
  controllers: [AdminAuthController, AdminAdminsController, AdminStatsController],
  exports: [AdminPermissionsService, PermissionGuard, AdminAuthService],
})
export class AdminModule {}
