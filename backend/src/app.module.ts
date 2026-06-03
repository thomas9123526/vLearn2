import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { TypeOrmModule } from '@nestjs/typeorm';
import { APP_GUARD } from '@nestjs/core';
import { HealthController } from './health.controller';
import { typeormConfigFactory } from './database/typeorm-config.factory';
import { AuthModule } from './auth/auth.module';
import { JwtAuthGuard } from './auth/guards/jwt-auth.guard';
import { UsersModule } from './users/users.module';
import { PersonasModule } from './personas/personas.module';
import { ScenariosModule } from './scenarios/scenarios.module';
import { CategoriesModule } from './categories/categories.module';
import { CoursesModule } from './courses/courses.module';
import { ConversationsModule } from './conversations/conversations.module';
import { ProgressModule } from './progress/progress.module';
import { AchievementsModule } from './achievements/achievements.module';
import { AiModule } from './ai/ai.module';
import { GuardModule } from './guard/guard.module';
import { AdminModule } from './admin/admin.module';
import { AppConfigModule } from './app-config/app-config.module';
import { LicenseModule } from './license/license.module';
import { NewsModule } from './news/news.module';
import { NetworkStatsModule } from './network-stats/network-stats.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, cache: true }),
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: typeormConfigFactory,
    }),
    ThrottlerModule.forRootAsync({
      useFactory: () => ({
        throttlers: [
          {
            ttl: parseInt(process.env.THROTTLE_TTL_SECONDS ?? '60', 10) * 1000,
            limit: parseInt(process.env.THROTTLE_LIMIT ?? '120', 10),
          },
        ],
      }),
    }),
    // Feature modules
    AuthModule,
    UsersModule,
    PersonasModule,
    ScenariosModule,
    CategoriesModule,
    CoursesModule,
    ConversationsModule,
    ProgressModule,
    AchievementsModule,
    AiModule,
    GuardModule,
    AdminModule,
    AppConfigModule,
    LicenseModule,
    NewsModule,
    NetworkStatsModule,
  ],
  controllers: [HealthController],
  providers: [
    // Global JWT auth — endpoints opt out via @Public()
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    // Throttler runs after auth
    { provide: APP_GUARD, useClass: ThrottlerGuard },
  ],
})
export class AppModule {}
