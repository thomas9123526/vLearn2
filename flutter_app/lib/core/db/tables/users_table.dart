import 'package:drift/drift.dart';

/// Local cache of the authenticated user's profile. Single row (the
/// currently-signed-in user). Cleared on sign-out.
class LocalUsers extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get displayName => text()();
  TextColumn get avatarEmoji => text().withDefault(const Constant('🐣'))();
  TextColumn get nativeLanguage => text().withDefault(const Constant('en'))();
  TextColumn get uiLanguage => text().withDefault(const Constant('en'))();
  IntColumn get currentLevel => integer().withDefault(const Constant(1))();
  IntColumn get xpTotal => integer().withDefault(const Constant(0))();
  IntColumn get streakDays => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastActiveDate => dateTime().nullable()();
  TextColumn get activePersonaId => text().nullable()();
  TextColumn get activeTheme => text().withDefault(const Constant('apricot'))();
  BoolColumn get onboardingDone => boolean().withDefault(const Constant(false))();
  TextColumn get role => text().withDefault(const Constant('user'))();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
