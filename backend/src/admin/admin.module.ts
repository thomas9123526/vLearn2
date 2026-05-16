import { Module, Global } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserEntity } from '../database/entities/user.entity';
import { AdminPermissionEntity } from '../database/entities/admin-permission.entity';
import { AdminPermissionsService } from './permissions/admin-permissions.service';
import { PermissionGuard } from './permissions/permission.guard';
import { AdminAuthController } from './admins/admin-auth.controller';
import { AdminAdminsController } from './admins/admin-admins.controller';
import { AuthModule } from '../auth/auth.module';

@Global()
@Module({
  imports: [
    TypeOrmModule.forFeature([UserEntity, AdminPermissionEntity]),
    AuthModule,
  ],
  providers: [AdminPermissionsService, PermissionGuard],
  controllers: [AdminAuthController, AdminAdminsController],
  exports: [AdminPermissionsService, PermissionGuard],
})
export class AdminModule {}
