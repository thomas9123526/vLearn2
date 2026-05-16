import 'package:drift/drift.dart';

/// Per-flag cache of the GET /app-config response (see todoList/12 §12.5).
class LayoutConfigCache extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();         // JSON-encoded
  TextColumn get valueType => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Single-row table tracking the server's last config version timestamp
/// so we can do If-Modified-Since style refreshes.
class LayoutConfigMeta extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get serverVersion => text().nullable()();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
