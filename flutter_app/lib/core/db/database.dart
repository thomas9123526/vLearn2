import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'tables/users_table.dart';
import 'tables/scenarios_cache_table.dart';
import 'tables/local_sessions_table.dart';
import 'tables/progress_cache_table.dart';
import 'tables/settings_table.dart';
import 'tables/layout_config_table.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    LocalUsers,
    ScenariosCache,
    LocalSessions,
    LocalMessages,
    ProgressCache,
    AppSettings,
    LayoutConfigCache,
    LayoutConfigMeta,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Future schema migrations land here.
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'vlearn2.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
