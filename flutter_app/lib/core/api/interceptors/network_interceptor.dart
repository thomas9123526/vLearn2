import 'package:dio/dio.dart';
import '../../network/network_status.dart';
import 'error_interceptor.dart';

/// Short-circuits requests when [NetworkStatusService] reports
/// `offline`. Without this, every API call would wait the full
/// connectTimeout (~10s) before failing — so the user would see a
/// long spinner before the polite "no connection" banner.
///
/// Lives **before** [AuthInterceptor] in the chain so the auth header
/// work isn't done for a request we're about to reject anyway.
class NetworkInterceptor extends Interceptor {
  NetworkInterceptor(this._status);

  final NetworkStatusService _status;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_status.status == NetworkStatus.offline) {
      // i18nKey is read by `politeMessageFor` to render the
      // localized "you're offline" message. Status code 0 keeps
      // ApiException.isNetwork true for any callers that branch on it.
      final err = ApiException(
        statusCode: 0,
        i18nKey: 'network.offline',
        message: 'No internet connection.',
      );
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: err,
          message: err.message,
        ),
        true, // do not call subsequent interceptors
      );
      return;
    }
    handler.next(options);
  }
}
