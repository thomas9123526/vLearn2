import 'package:drift/drift.dart';

/// Conversation sessions started locally. Synced to the server when
/// reachable; `synced=false` rows queue for retry.
class LocalSessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get scenarioId => text().nullable()();
  TextColumn get personaId => text()();
  TextColumn get mode => text()(); // chat / face
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get turnCount => integer().withDefault(const Constant(0))();
  IntColumn get wordCount => integer().withDefault(const Constant(0))();
  IntColumn get xpEarned => integer().withDefault(const Constant(0))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalMessages extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  TextColumn get role => text()(); // user / assistant
  TextColumn get content => text()();
  IntColumn get sequence => integer()();
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
