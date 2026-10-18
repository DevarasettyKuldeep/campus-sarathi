import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

part 'academic_database.g.dart';

class LocalAssignments extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get subject => text().withLength(min: 1, max: 200)();
  DateTimeColumn get dueDate => dateTime()();
  BoolColumn get complete => boolean().withDefault(const Constant(false))();
  DateTimeColumn get recordedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get source => text().withDefault(const Constant('student'))();
  @override
  Set<Column> get primaryKey => {id};
  @override
  List<String> get customConstraints => ["CHECK (source = 'student')"];
}

class LocalClasses extends Table {
  TextColumn get id => text()();
  TextColumn get subject => text().withLength(min: 1, max: 200)();
  TextColumn get room => text().withLength(min: 1, max: 200)();
  IntColumn get weekday => integer()();
  IntColumn get startMinute => integer()();
  IntColumn get endMinute => integer()();
  DateTimeColumn get recordedAt => dateTime()();
  TextColumn get source => text().withDefault(const Constant('student'))();
  @override
  Set<Column> get primaryKey => {id};
  @override
  List<String> get customConstraints => [
    'CHECK (weekday BETWEEN 1 AND 7)',
    'CHECK (start_minute >= 0 AND end_minute < 1440 AND end_minute > start_minute)',
    "CHECK (source = 'student')",
  ];
}

class LocalAttendance extends Table {
  TextColumn get subjectKey => text()();
  TextColumn get subject => text().withLength(min: 1, max: 200)();
  IntColumn get attended => integer()();
  IntColumn get conducted => integer()();
  RealColumn get minimumPercentage => real().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get source => text().withDefault(const Constant('student'))();
  @override
  Set<Column> get primaryKey => {subjectKey};
  @override
  List<String> get customConstraints => [
    'CHECK (attended >= 0 AND conducted >= attended AND conducted <= 100000)',
    'CHECK (minimum_percentage IS NULL OR (minimum_percentage > 0 AND minimum_percentage <= 100))',
    "CHECK (source = 'student')",
  ];
}

class LocalConsents extends Table {
  IntColumn get id => integer()();
  TextColumn get noticeVersion => text()();
  DateTimeColumn get grantedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class LocalAcademicProfiles extends Table {
  IntColumn get id => integer()();
  TextColumn get programme => text().withLength(min: 1, max: 200)();
  IntColumn get semesterNumber => integer()();
  TextColumn get semesterStart => text()();
  TextColumn get semesterEnd => text()();
  TextColumn get timezone =>
      text().withDefault(const Constant('Asia/Kolkata'))();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
  @override
  List<String> get customConstraints => [
    'CHECK (id = 1 AND semester_number BETWEEN 1 AND 30)',
    "CHECK (length(trim(programme)) BETWEEN 1 AND 200)",
    "CHECK (timezone = 'Asia/Kolkata')",
    "CHECK (length(semester_start) = 10 AND length(semester_end) = 10 AND semester_start >= '2000-01-01' AND semester_end <= '2100-12-31' AND semester_end >= semester_start)",
    "CHECK (date(semester_start, '+0 days') IS NOT NULL AND date(semester_start, '+0 days') = semester_start)",
    "CHECK (date(semester_end, '+0 days') IS NOT NULL AND date(semester_end, '+0 days') = semester_end)",
  ];
}

class LocalSyncOutbox extends Table {
  TextColumn get operationId => text()();
  TextColumn get entityType => text().withLength(min: 1, max: 50)();
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {operationId};
  @override
  List<String> get customConstraints => [
    "CHECK (status IN ('pending', 'conflict', 'completed'))",
  ];
}

@DriftDatabase(
  tables: [
    LocalAssignments,
    LocalClasses,
    LocalAttendance,
    LocalConsents,
    LocalAcademicProfiles,
    LocalSyncOutbox,
  ],
)
class AcademicDatabase extends _$AcademicDatabase {
  AcademicDatabase(super.executor);

  static File accountFile(
    Directory directory,
    String accountId,
    String namespace,
  ) {
    if (!RegExp(
          r'^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$',
        ).hasMatch(accountId) ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(namespace)) {
      throw ArgumentError(
        'Use a verified account ID and server storage namespace.',
      );
    }
    return File(
      '${directory.path}${Platform.pathSeparator}academic_${namespace}_${accountId.toLowerCase()}.sqlite',
    );
  }

  factory AcademicDatabase.forAccount(
    String accountId, {
    required String namespace,
  }) {
    accountFile(Directory('.'), accountId, namespace);
    return AcademicDatabase(
      LazyDatabase(() async {
        final directory = await getApplicationSupportDirectory();
        return NativeDatabase.createInBackground(
          accountFile(directory, accountId, namespace),
        );
      }),
    );
  }

  factory AcademicDatabase.onDevice() => AcademicDatabase(
    LazyDatabase(() async {
      final directory = await getApplicationSupportDirectory();
      return NativeDatabase.createInBackground(
        File(
          '${directory.path}${Platform.pathSeparator}academic_local_v1.sqlite',
        ),
      );
    }),
  );

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(localAcademicProfiles);
      if (from < 3) await m.createTable(localSyncOutbox);
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA secure_delete = ON');
    },
  );

  /// Erases app-owned local academic data and the active consent receipt.
  /// This does not claim deletion of OS backups or account/provider records.
  Future<void> eraseLocalData() => transaction(() async {
    await delete(localAssignments).go();
    await delete(localClasses).go();
    await delete(localAttendance).go();
    await delete(localConsents).go();
    await delete(localAcademicProfiles).go();
    await delete(localSyncOutbox).go();
  });
}
