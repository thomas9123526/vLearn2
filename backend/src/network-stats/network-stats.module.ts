import { Global, Module } from '@nestjs/common';
import { APP_INTERCEPTOR } from '@nestjs/core';
import { NetworkStatsService } from './network-stats.service';
import { NetworkStatsInterceptor } from './network-stats.interceptor';

/**
 * Global module — registers the interceptor app-wide via APP_INTERCEPTOR
 * so every route automatically participates in byte tracking without
 * needing per-module setup.
 */
@Global()
@Module({
  providers: [
    NetworkStatsService,
    {
      provide: APP_INTERCEPTOR,
      useClass: NetworkStatsInterceptor,
    },
  ],
  exports: [NetworkStatsService],
})
export class NetworkStatsModule {}
