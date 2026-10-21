import 'dart:io';
import 'package:campus_sarathi/data/local/academic_database.dart';
import 'package:campus_sarathi/features/profile/student_profile.dart';
import 'package:campus_sarathi/features/profile/profile_editor.dart';
import 'package:campus_sarathi/main.dart';
import 'package:campus_sarathi/repositories/academic_store.dart';
import 'package:drift/drift.dart' show MigrationStrategy;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

StudentProfile profile({
  String programme = 'B.Tech CSE',
  String start = '2026-07-20',
  String end = '2026-12-10',
  int semester = 3,
}) => StudentProfile(
  programme: programme,
  semesterNumber: semester,
  semesterStart: start,
  semesterEnd: end,
  updatedAt: DateTime.now().toUtc(),
);

// Frozen v1 schema fixture: the four original tables, no academic profile.
class LegacyAcademicDatabase extends AcademicDatabase {
  LegacyAcademicDatabase(super.executor);
  @override
  int get schemaVersion => 1;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createTable(localAssignments);
      await m.createTable(localClasses);
      await m.createTable(localAttendance);
      await m.createTable(localConsents);
    },
  );
}

void main() {
  test(
    'profile validates real calendar days, programme and semester without normalising impossible dates',
    () {
      profile().validate();
      profile(start: '2024-02-29', end: '2024-03-01').validate();
      for (final invalid in [
        profile(programme: ' '),
        profile(programme: 'Name\u0000'),
        profile(semester: 0),
        profile(semester: 31),
        profile(start: '2026-02-29'),
        profile(start: '2026-02-30'),
        profile(end: '2026-01-01'),
        profile(start: '1999-01-01'),
      ]) {
        expect(invalid.validate, throwsArgumentError);
      }
    },
  );

  test(
    'profile is consent-gated, persists on disk, updates and erases without resurrection',
    () async {
      final folder = await Directory.systemTemp.createTemp('sarathi-profile-');
      final file = File('${folder.path}/profile.sqlite');
      Future<void> withStore(
        Future<void> Function(AcademicStore) action,
      ) async {
        final store = AcademicStore(
          database: AcademicDatabase(NativeDatabase(file)),
        );
        try {
          await store.initialize();
          await action(store);
        } finally {
          await store.close();
          store.dispose();
        }
      }

      try {
        await withStore((store) async {
          await expectLater(store.saveProfile(profile()), throwsStateError);
          await store.grantLocalConsent();
          await store.saveProfile(profile(programme: '  My Programme  '));
          expect(store.profile!.programme, 'My Programme');
        });
        await withStore((store) async {
          expect(store.profile!.programme, 'My Programme');
          expect(store.profile!.semesterStart, '2026-07-20');
          expect(store.profile!.timezone, 'Asia/Kolkata');
          await store.saveProfile(profile(semester: 4));
        });
        await withStore((store) async {
          expect(store.profile!.semesterNumber, 4);
          await store.eraseLocalData();
          expect(store.profile, isNull);
        });
        await withStore((store) async {
          expect(store.hasConsent, isFalse);
          await store.grantLocalConsent();
          expect(store.profile, isNull);
        });
      } finally {
        await folder.delete(recursive: true);
      }
    },
  );

  test(
    'schema v1 upgrades to v3 without losing records and requires renewed profile notice',
    () async {
      final folder = await Directory.systemTemp.createTemp(
        'sarathi-profile-upgrade-',
      );
      final file = File('${folder.path}/old.sqlite');
      final legacy = LegacyAcademicDatabase(NativeDatabase(file));
      try {
        await legacy.customStatement(
          "INSERT INTO local_assignments(id,title,subject,due_date,recorded_at,updated_at) VALUES ('retained','Existing assignment','Networks',0,0,0)",
        );
        await legacy.customStatement(
          "INSERT INTO local_consents(id,notice_version,granted_at) VALUES (1,'local-academic-2',0)",
        );
        await legacy.close();
        final database = AcademicDatabase(NativeDatabase(file));
        final store = AcademicStore(database: database);
        try {
          await store.initialize();
          expect(store.hasConsent, isFalse);
          expect(
            store.assignments,
            isEmpty,
            reason: 'Old consent must not permit new processing.',
          );
          await store.grantLocalConsent();
          expect(store.assignments.single.id, 'retained');
          await store.saveProfile(profile());
          expect(store.profile!.programme, 'B.Tech CSE');
          expect(
            (await database.customSelect('PRAGMA user_version').getSingle())
                .read<int>('user_version'),
            3,
          );
        } finally {
          await store.close();
          store.dispose();
        }
      } finally {
        await legacy.close();
        await folder.delete(recursive: true);
      }
    },
  );

  test(
    'failed profile SQL writes preserve saved data and draft can be retried; SQL constraints are real',
    () async {
      final database = AcademicDatabase(NativeDatabase.memory());
      final store = AcademicStore(database: database);
      try {
        await store.initialize();
        await store.grantLocalConsent();
        await store.saveProfile(profile());
        await database.customStatement(
          "CREATE TRIGGER reject_profile BEFORE UPDATE ON local_academic_profiles BEGIN SELECT RAISE(ABORT, 'fixture failure'); END",
        );
        await expectLater(
          store.saveProfile(profile(semester: 4)),
          throwsA(anything),
        );
        expect(store.profile!.semesterNumber, 3);
        expect(store.busy, isFalse);
        await database.customStatement('DROP TRIGGER reject_profile');
        await store.saveProfile(profile(semester: 4));
        expect(store.profile!.semesterNumber, 4);
        for (final change in [
          "semester_number = 31",
          "semester_start = '2026-02-30'",
          "timezone = 'UTC'",
          "id = 2",
        ]) {
          await expectLater(
            database.customStatement(
              'UPDATE local_academic_profiles SET $change',
            ),
            throwsA(anything),
          );
        }
      } finally {
        await store.close();
        store.dispose();
      }
    },
  );

  testWidgets(
    'profile editor validates, preserves cancelled drafts and saves edits on a small keyboard layout',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 200);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final store = AcademicStore(
        database: AcademicDatabase(NativeDatabase.memory()),
      );
      await store.initialize();
      await store.grantLocalConsent();
      addTearDown(() async {
        await store.close();
        store.dispose();
      });
      await tester.pumpWidget(CampusSarathiApp(store: store));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Add semester profile'), 100);
      await tester.tap(find.text('Add semester profile'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save profile on device'));
      await tester.tap(find.text('Save profile on device'));
      await tester.pumpAndSettle();
      expect(
        find.text('Enter a programme name of 1–200 characters.'),
        findsOneWidget,
      );
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'My programme');
      await tester.enterText(fields.at(1), '3');
      await tester.enterText(fields.at(2), '2026-07-20');
      await tester.enterText(fields.at(3), '2026-12-10');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(store.profile, isNull);
      expect(
        find.widgetWithText(TextFormField, 'My programme'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Save profile on device'));
      await tester.tap(find.text('Save profile on device'));
      await tester.pumpAndSettle();
      expect(store.profile!.programme, 'My programme');
      expect(find.byType(ProfileEditor), findsNothing);
      await tester.ensureVisible(find.text('My programme'));
      await tester.tap(find.text('My programme'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Discard this draft',
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard changes'));
      await tester.pumpAndSettle();
      expect(store.profile!.programme, 'My programme');
      expect(find.byType(ProfileEditor), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
