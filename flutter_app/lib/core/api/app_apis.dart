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
}

// ─── Personas ───────────────────────────────────────────────
class PersonasApi {
  PersonasApi(this._dio);
  final Dio _dio;

  Future<List<Map<String, dynamic>>> list() async {
    final res = await _dio.get<List<dynamic>>('/personas');
    return res.data!.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> get(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('/personas/$id');
    return res.data!;
  }
}

// ─── Scenarios ──────────────────────────────────────────────
class ScenariosApi {
  ScenariosApi(this._dio);
  final Dio _dio;

  Future<List<Map<String, dynamic>>> list({
    String? category,
    int? difficulty,
    String? q,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/scenarios',
      queryParameters: <String, Object?>{
        'category': category,
        'difficulty': difficulty,
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
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/conversations/sessions',
      data: <String, Object?>{
        'personaId': personaId,
        'scenarioId': scenarioId,
        'mode': mode,
      }..removeWhere((_, v) => v == null),
    );
    return res.data!;
  }

  Future<List<Map<String, dynamic>>> listSessions({int? limit}) async {
    final res = await _dio.get<List<dynamic>>(
      '/conversations/sessions',
      queryParameters: limit == null ? null : {'limit': limit},
    );
    return res.data!.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getSession(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('/conversations/sessions/$id');
    return res.data!;
  }

  Future<Map<String, dynamic>> sendMessage(String sessionId, String content, {String? audioUrl}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/conversations/sessions/$sessionId/messages',
      data: <String, Object?>{
        'content': content,
        'audioUrl': audioUrl,
      }..removeWhere((_, v) => v == null),
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> endSession(String sessionId, {String status = 'completed'}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/conversations/sessions/$sessionId/end',
      data: {'status': status},
    );
    return res.data!;
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

// ─── Providers ──────────────────────────────────────────────
final usersApiProvider = Provider<UsersApi>((ref) => UsersApi(ref.watch(apiClientProvider)));
final personasApiProvider = Provider<PersonasApi>((ref) => PersonasApi(ref.watch(apiClientProvider)));
final scenariosApiProvider = Provider<ScenariosApi>((ref) => ScenariosApi(ref.watch(apiClientProvider)));
final coursesApiProvider = Provider<CoursesApi>((ref) => CoursesApi(ref.watch(apiClientProvider)));
final conversationsApiProvider = Provider<ConversationsApi>((ref) => ConversationsApi(ref.watch(apiClientProvider)));
final progressApiProvider = Provider<ProgressApi>((ref) => ProgressApi(ref.watch(apiClientProvider)));
final achievementsApiProvider = Provider<AchievementsApi>((ref) => AchievementsApi(ref.watch(apiClientProvider)));
final newsApiProvider = Provider<NewsApi>((ref) => NewsApi(ref.watch(apiClientProvider)));
