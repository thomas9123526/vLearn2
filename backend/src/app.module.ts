import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';
import { HealthController } from './health.controller';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      cache: true,
    }),
    ThrottlerModule.forRootAsync({
      useFactory: () => ({
        throttlers: [
          {
            ttl:
              parseInt(process.env.THROTTLE_TTL_SECONDS ?? '60', 10) * 1000,
            limit: parseInt(process.env.THROTTLE_LIMIT ?? '120', 10),
          },
        ],
      }),
    }),
    // Feature modules land here in subsequent commits:
    //   AuthModule, UsersModule, PersonasModule, ScenariosModule,
    //   ConversationsModule, ProgressModule, AiModule, GuardModule,
    //   AppConfigModule, StorageModule, AdminAdminsModule, ...
  ],
  controllers: [HealthController],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
