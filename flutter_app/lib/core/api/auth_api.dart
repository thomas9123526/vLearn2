import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

class AuthApi {
  AuthApi(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> signUp({
    required String cid,
    required String cidUsername,
    required String password,
    required String displayName,
    String? uiLanguage,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/signup',
      data: <String, Object?>{
        'cid': cid,
        'cidUsername': cidUsername,
        'password': password,
        'displayName': displayName,
        'uiLanguage': uiLanguage,
      }..removeWhere((_, v) => v == null),
      options: Options(extra: const {'skipAuth': true}),
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> signIn({
    required String cidUsername,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/signin',
      data: {'cidUsername': cidUsername, 'password': password},
      options: Options(extra: const {'skipAuth': true}),
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> me() async {
    final res = await _dio.get<Map<String, dynamic>>('/auth/me');
    return res.data!;
  }

  Future<void> signOut({String? refreshToken}) async {
    await _dio.post<void>(
      '/auth/signout',
      data: refreshToken == null ? null : {'refreshToken': refreshToken},
    );
  }
}

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(apiClientProvider)));
