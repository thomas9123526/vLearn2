import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { NetworkStatsService } from './network-stats.service';

/**
 * Counts request/response bytes for authenticated Flutter app calls and
 * accumulates them per user + platform in vl_user_network_stats.
 *
 * Only active when the request carries an X-Platform header (set by the
 * Flutter Dio client). Admin-panel calls (no header) are skipped.
 *
 * Upload  = Content-Length of the incoming request body.
 * Download = byte length of the serialised JSON response body.
 *
 * Both are approximations at the application layer (not counting HTTP
 * framing or TLS overhead) but are consistent and useful for relative
 * comparisons across users.
 */
@Injectable()
export class NetworkStatsInterceptor implements NestInterceptor {
  constructor(private readonly stats: NetworkStatsService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const req = context.switchToHttp().getRequest<{
      headers: Record<string, string | undefined>;
      user?: { sub?: string };
    }>();

    const platform = req.headers['x-platform']?.toLowerCase();
    const userId = req.user?.sub;

    // Skip if no platform header (admin panel, non-HTTP, unauthenticated)
    if (!platform || !userId) return next.handle();

    const uploadBytes =
      parseInt(req.headers['content-length'] ?? '0', 10) || 0;

    return next.handle().pipe(
      tap({
        next: (body: unknown) => {
          const downloadBytes = body
            ? Buffer.byteLength(JSON.stringify(body), 'utf8')
            : 0;
          this.stats
            .addBytes(userId, platform, uploadBytes, downloadBytes)
            .catch(() => {/* fire-and-forget */});
        },
      }),
    );
  }
}
