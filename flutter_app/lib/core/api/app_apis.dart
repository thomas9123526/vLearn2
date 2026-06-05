import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

// ─── Users ──────────────────────────────────────────────────
class UsersApi {
  UsersApi(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> profile() async {
    final res = await _dio.get<Map<String, dynamic>>('/users/profile');
    return res.data!;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, Object?> patch) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/users/profile',
      data: patch..removeWhere((_, v) => v == null),
    );
    return res.data!;
  }

  /// Multipart upload of the user's avatar photo. Returns the
  /// updated profile (with avatarUrl populated).
  Future<Map<String, dynamic>> uploadAvatar({
    required String filePath,
    String? filename,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: filename),
    });
    final res = await _dio.post<Map<String, dynamic>>(
      '/users/avatar',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return res.data!;
  }

  /// Submit a feedback / bug report from the user.
  Future<void> sendReport({
    required String content,
    String type = 'feedback',
    String? platform,
    String? appVersion,
  }) async {
    await _dio.post<void>('/users/report', data: {
      'type': type,
      'content': content,
      'platform': platform,
      'app_version': appVersion,
    });
  }
}

// ─── Teachers (personas) ────────────────────────────────────
class PersonasApi {
  PersonasApi(this._dio);
  final Dio _dio;

  Future<List<Map<String, dynamic>>> list() async {
    final res = await _dio.get<List<dynamic>>('/teachers');
    return res.data!.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> get(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('/teachers/$id');
    return res.data!;
  }
}

// ─── Scenarios ──────────────────────────────────────────────
class ScenariosApi {
  ScenariosApi(this._dio);
  final Dio _dio;

  Future<List<Map<String, dynamic>>> list({
    String? category,
    int? cefrLevel,
    String? q,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/scenarios',
      queryParameters: <String, Object?>{
        'category': category,
        'cefr_level': cefrLevel,
        'q': q,
      }..removeWhere((_, v) => v == null),
    );
    return res.data!.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> get(String idOrSlug) async {
    final res = await _dio.get<Map<String, dynamic>>('/scenarios/$idOrSlug');
    return res.data!;
  }
}

// ─── Categories ─────────────────────────────────────────────
class CategoriesApi {
  CategoriesApi(this._dio);
  final Dio _dio;

  Future<List<Map<String, dynamic>>> list() async {
    final res = await _dio.get<List<dynamic>>('/categories');
    return res.data!.cast<Map<String, dynamic>>();
  }
}

// ─── Courses ────────────────────────────────────────────────
class CoursesApi {
  CoursesApi(this._dio);
  final Dio _dio;

  Future<List<Map<String, dynamic>>> list() async {
    final res = await _dio.get<List<dynamic>>('/courses');
    return res.data!.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> get(String idOrSlug) async {
    final res = await _dio.get<Map<String, dynamic>>('/courses/$idOrSlug');
    return res.data!;
  }
}

// ─── Conversations ──────────────────────────────────────────
class ConversationsApi {
  ConversationsApi(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> startSession({
    required String personaId,
    String? scenarioId,
    required String mode,
    int? cefrLevel,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/conversations/sessions',
      data: <String, Object?>{
        'personaId': personaId,
        'scenarioId': scenarioId,
        'mode': mode,
        'cefrLevel': cefrLevel,
      }..removeWhere((_, v) => v == null),
    );
    return res.data!;
  }

  Future<List<Map<String, dynamic>>> listSessions({
    int? limit,
    String? scenarioId,
    String? status,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/conversations/sessions',
      queryParameters: <String, Object?>{
        'limit': limit,
        'scenarioId': scenarioId,
        'status': status,
      }..removeWhere((_, v) => v == null),
    );
    return res.data!.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getSession(String id) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/conversations/sessions/$id',
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> sendMessage(
    String sessionId,
    String content, {
    String? audioUrl,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/conversations/sessions/$sessionId/messages',
      data: <String, Object?>{'content': content, 'audioUrl': audioUrl}
        ..removeWhere((_, v) => v == null),
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> endSession(
    String sessionId, {
    String status = 'completed',
    /// Average pronunciation score (0.0–1.0) aggregated from per-turn STT
    /// results. Null when the STT engine does not support pronunciation scoring
    /// (e.g. current sherpa-onnx). Backend stores null in that case.
    double? pronunciationScore,
  }) async {
    final body = <String, dynamic>{'status': status};
    if (pronunciationScore != null) {
      // Convert 0.0–1.0 → 0–100 to match the backend's smallint scale.
      body['pronunciationScore'] = (pronunciationScore * 100).round().clamp(0, 100);
    }
    final res = await _dio.post<Map<String, dynamic>>(
      '/conversations/sessions/$sessionId/end',
      data: body,
    );
    return res.data!;
  }

  /// Hard-deletes a session along with its messages and computed scores.
  /// Guard-violation rows are preserved server-side (their session_id is
  /// nulled). Throws on auth or 404; caller is responsible for the dialog.
  Future<void> deleteSession(String sessionId) async {
    await _dio.delete<void>('/conversations/sessions/$sessionId');
  }

  /// Deletes every session owned by the current user in one request.
  Future<void> deleteAllSessions() async {
    await _dio.delete<void>('/conversations/sessions');
  }

  /// Tutor-mode idle prompt. Returns a short sentence the user could say
  /// next, generated by the AI orchestrator on the backend. Used after the
  /// user has gone silent for ~20s in Face mode.
  Future<String?> suggestNextLine(String sessionId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/conversations/sessions/$sessionId/suggest',
      );
      return res.data?['suggestion'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Fetches the AI evaluation score for a completed session.
  /// Returns null if the evaluation is still running (backend returns 404 or
  /// empty body — poll until non-null).
  Future<Map<String, dynamic>?> getSessionScore(String sessionId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>?>(
        '/conversations/sessions/$sessionId/score',
      );
      return res.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}

// ─── Progress ───────────────────────────────────────────────
class ProgressApi {
  ProgressApi(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> myProgress() async {
    final res = await _dio.get<Map<String, dynamic>>('/progress');
    return res.data!;
  }

  Future<List<Map<String, dynamic>>> snapshots() async {
    final res = await _dio.get<List<dynamic>>('/progress/snapshots');
    return res.data!.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> completions() async {
    final res = await _dio.get<List<dynamic>>('/progress/completions');
    return res.data!.cast<Map<String, dynamic>>();
  }

  /// Submit (or refine) today's snapshot. The backend running-averages new
  /// scores into the existing row so values smooth out across sessions.
  Future<Map<String, dynamic>> submitSnapshot({
    int? pronunciation,
    int? fluency,
    int? vocabulary,
    int? grammar,
    int? listening,
    int? confidence,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/progress/snapshots',
      data: <String, Object?>{
        'pronunciation': pronunciation,
        'fluency': fluency,
        'vocabulary': vocabulary,
        'grammar': grammar,
        'listening': listening,
        'confidence': confidence,
      }..removeWhere((_, v) => v == null),
    );
    return res.data!;
  }
}

// ─── News ───────────────────────────────────────────────────
class NewsApi {
  NewsApi(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> list({int page = 1, int limit = 20}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/news',
      queryParameters: {'page': page, 'limit': limit},
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> get(String idOrSlug) async {
    final res = await _dio.get<Map<String, dynamic>>('/news/$idOrSlug');
    return res.data!;
  }

  Future<void> markRead(String id) async {
    await _dio.post<Map<String, dynamic>>('/news/$id/read');
  }

  Future<void> markAllRead() async {
    await _dio.post<Map<String, dynamic>>('/news/read-all');
  }

  Future<int> unreadCount() async {
    final res = await _dio.get<Map<String, dynamic>>('/news/unread-count');
    return (res.data!['count'] as num).toInt();
  }
}

// ─── Achievements ───────────────────────────────────────────
class AchievementsApi {
  AchievementsApi(this._dio);
  final Dio _dio;

  Future<List<Map<String, dynamic>>> catalog() async {
    final res = await _dio.get<List<dynamic>>('/achievements');
    return res.data!.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> mine() async {
    final res = await _dio.get<List<dynamic>>('/achievements/mine');
    return res.data!.cast<Map<String, dynamic>>();
  }
}

// ─── License ────────────────────────────────────────────────
class LicenseApi {
  LicenseApi(this._dio);
  final Dio _dio;

  /// POST /license/verify — validates a DER cert blob against the backend Leaf CA.
  /// [licenseContent] is the base64-encoded cert bytes (as returned from QR scan).
  /// [machineId] is the device fingerprint from the native machine-ID library.
  /// [userId] is the logged-in user's UUID; when provided the backend persists
  ///          the license to that user record.
  /// [platform] is the canonical Flutter platform name ('android', 'windows',
  ///          'ios', 'macos', 'linux', 'fuchsia', 'web') so the admin panel
  ///          can show what device each user activated from.
  Future<Map<String, dynamic>> verify({
    required String licenseContent,
    required String machineId,
    String? userId,
    String? platform,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/license/verify',
      data: <String, Object?>{
        'licenseContent': licenseContent,
        'machineId': machineId,
        'userId': userId,
        'platform': platform,
      }..removeWhere((_, v) => v == null),
    );
    return res.data!;
  }
}

// ─── Providers ──────────────────────────────────────────────
// AuthApi + authApiProvider live in auth_api.dart -- importing
// both files used to cause `authApiProvider` to be ambiguous.
final usersApiProvider = Provider<UsersApi>(
  (ref) => UsersApi(ref.watch(apiClientProvider)),
);
final personasApiProvider = Provider<PersonasApi>(
  (ref) => PersonasApi(ref.watch(apiClientProvider)),
);
final scenariosApiProvider = Provider<ScenariosApi>(
  (ref) => ScenariosApi(ref.watch(apiClientProvider)),
);
final categoriesApiProvider = Provider<CategoriesApi>(
  (ref) => CategoriesApi(ref.watch(apiClientProvider)),
);
final coursesApiProvider = Provider<CoursesApi>(
  (ref) => CoursesApi(ref.watch(apiClientProvider)),
);
final conversationsApiProvider = Provider<ConversationsApi>(
  (ref) => ConversationsApi(ref.watch(apiClientProvider)),
);
final progressApiProvider = Provider<ProgressApi>(
  (ref) => ProgressApi(ref.watch(apiClientProvider)),
);
final achievementsApiProvider = Provider<AchievementsApi>(
  (ref) => AchievementsApi(ref.watch(apiClientProvider)),
);
final newsApiProvider = Provider<NewsApi>(
  (ref) => NewsApi(ref.watch(apiClientProvider)),
);
final licenseApiProvider = Provider<LicenseApi>(
  (ref) => LicenseApi(ref.watch(apiClientProvider)),
);
