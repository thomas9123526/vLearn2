import 'package:drift/drift.dart';

/// Read-through cache of the scenarios list. Refreshed from the API
/// when reachable; otherwise the app falls back to whatever's here.
class ScenariosCache extends Table {
  TextColumn get id => text()();
  TextColumn get slug => text()();
  TextColumn get category => text()();
  IntColumn get cefrLevel => integer().nullable()();
  TextColumn get titleJson => text()();          // JSON-encoded I18nText
  TextColumn get descriptionJson => text()();
  TextColumn get sceneDescriptionJson => text()();
  TextColumn get userRoleJson => text()();
  TextColumn get tutorRoleJson => text()();
  TextColumn get objectivesJson => text()();      // JSON-encoded array
  TextColumn get keyPhrasesJson => text()();      // JSON-encoded array
  IntColumn get estimatedMinutes => integer().withDefault(const Constant(5))();
  IntColumn get xpReward => integer().withDefault(const Constant(50))();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get imageAltText => text().nullable()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
