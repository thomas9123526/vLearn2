import 'package:drift/drift.dart';

class ProgressCache extends Table {
  TextColumn get userId => text()();
  IntColumn get sessionsTotal => integer().withDefault(const Constant(0))();
  IntColumn get minutesSpokenTotal => integer().withDefault(const Constant(0))();
  IntColumn get wordsSpokenTotal => integer().withDefault(const Constant(0))();
  IntColumn get scenariosCompleted => integer().withDefault(const Constant(0))();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  TextColumn get skillJson => text().nullable()(); // latest skill snapshot
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}
