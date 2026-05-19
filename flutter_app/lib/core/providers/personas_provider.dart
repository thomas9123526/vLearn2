import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/app_apis.dart';
import '../models/models.dart';
import 'auth_provider.dart';

/// Fetches one tutor persona by id. Shared by settings, scenario brief,
/// and conversation tutor mode.
final personaByIdProvider =
    FutureProvider.family<Persona?, String>((ref, personaId) async {
  final raw = await ref.read(personasApiProvider).get(personaId);
  return Persona.fromJson(raw);
});

final personasListProvider = FutureProvider<List<Persona>>((ref) async {
  final raw = await ref.read(personasApiProvider).list();
  return raw.map(Persona.fromJson).toList();
});

/// Persona shown in tutor mode: user's chosen default tutor when set,
/// otherwise the persona locked on the conversation session.
final tutorDisplayPersonaIdProvider = Provider.family<String, String>(
  (ref, sessionPersonaId) {
    final activePersonaId =
        ref.watch(authProvider.select((s) => s.user?.activePersonaId));
    if (activePersonaId != null && activePersonaId.isNotEmpty) {
      return activePersonaId;
    }
    return sessionPersonaId;
  },
);
