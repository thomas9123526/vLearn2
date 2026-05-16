import 'package:drift/drift.dart';

/// Device-local settings (not synced). See todoList/02 Settings Keys table.
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
