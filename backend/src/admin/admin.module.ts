import { Module, Global } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserEntity } from '../database/entities/user.entity';
import { UserInfoEntity } from '../database/entities/user-info.entity';
import { AdminEntity } from '../database/entities/admin.entity';
import { AdminRefreshTokenEntity } from '../database/entities/admin-refresh-token.entity';
import { AdminPermissionEntity } from '../database/entities/admin-permission.entity';
import { AdminAuditLogEntity } from '../database/entities/admin-audit-log.entity';
import { ConversationSessionEntity } from '../database/entities/conversation.entity';
import { ScenarioEntity } from '../database/entities/scenario.entity';
import { PersonaEntity } from '../database/entities/persona.entity';
import { PromptTemplateEntity } from '../database/entities/prompt-template.entity';
import { AdminPermissionsService } from './permissions/admin-permissions.service';
import { PermissionGuard } from './permissions/permission.guard';
import { AdminAuditLogService } from './audit/admin-audit-log.service';
import { AdminAuditController } from './audit/admin-audit.controller';
import { AdminAuthController } from './admins/admin-auth.controller';
import { AdminAuthService } from './admins/admin-auth.service';
import { AdminAdminsController } from './admins/admin-admins.controller';
import { AdminStatsController } from './stats/admin-stats.controller';
import { AdminUsersController } from './admin-users.controller';
import { AdminScenariosController } from './admin-scenarios.controller';
import { AdminPersonasController } from './admin-personas.controller';
import { AdminLeaderboardController } from './admin-leaderboard.controller';
import { AdminPromptTemplatesController } from './admin-prompt-templates.controller';
import { AuthModule } from '../auth/auth.module';

@Global()
@Module({
  imports: [
    TypeOrmModule.forFeature([
      UserEntity,
      UserInfoEntity,
      AdminEntity,
      AdminRefreshTokenEntity,
      AdminPermissionEntity,
      AdminAuditLogEntity,
      ConversationSessionEntity,
      ScenarioEntity,
      PersonaEntity,
      PromptTemplateEntity,
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
  providers: [AdminPermissionsService, PermissionGuard, AdminAuthService, AdminAuditLogService],
  controllers: [
    AdminAuthController,
    AdminAdminsController,
    AdminStatsController,
    AdminUsersController,
    AdminScenariosController,
    AdminPersonasController,
    AdminLeaderboardController,
    AdminPromptTemplatesController,
    AdminAuditController,
  ],
  exports: [AdminPermissionsService, PermissionGuard, AdminAuthService, AdminAuditLogService],
})
export class AdminModule {}
