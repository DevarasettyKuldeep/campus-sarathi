import 'dart:io';

import 'package:campus_sarathi/data/local/academic_database.dart';
import 'package:campus_sarathi/main.dart';
import 'package:campus_sarathi/models/academic_models.dart';
import 'package:campus_sarathi/repositories/academic_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('account/server SQLite files cannot read or erase each other', () async {
    final folder = await Directory.systemTemp.createTemp(
      'sarathi-account-isolation-',
    );
    final namespace = 'a'.padRight(64, 'a');
    const firstId = '11111111-1111-4111-8111-111111111111';
    const secondId = '22222222-2222-4222-8222-222222222222';
    Future<void> withStore(
      String id,
      String space,
      Future<void> Function(AcademicStore) action,
    ) async {
      final store = AcademicStore(
        database: AcademicDatabase(
          NativeDatabase(AcademicDatabase.accountFile(folder, id, space)),
        ),
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
      await withStore(firstId, namespace, (store) async {
        await store.grantLocalConsent();
        await store.addAssignment(
          title: 'First account only',
          subject: 'Networks',
          dueDate: DateTime(2030),
        );
      });
      await withStore(secondId, namespace, (store) async {
        expect(store.hasConsent, isFalse);
        expect(store.assignments, isEmpty);
        await store.grantLocalConsent();
        await store.addAssignment(
          title: 'Second account only',
          subject: 'Networks',
          dueDate: DateTime(2030),
        );
      });
      await withStore(firstId, 'b'.padRight(64, 'b'), (store) async {
        expect(store.hasConsent, isFalse);
        expect(store.assignments, isEmpty);
      });
      await withStore(firstId, namespace, (store) async {
        expect(store.assignments.single.title, 'First account only');
        await store.eraseLocalData();
      });
      await withStore(secondId, namespace, (store) async {
        expect(store.assignments.single.title, 'Second account only');
      });
      expect(
        () => AcademicDatabase.accountFile(folder, '../escape', namespace),
        throwsArgumentError,
      );
      expect(
        () => AcademicDatabase.accountFile(folder, firstId, '../escape'),
        throwsArgumentError,
      );
    } finally {
      await folder.delete(recursive: true);
    }
  });

  test(
    'SQLite retains all manual records and consent across close/reopen',
    () async {
      final folder = await Directory.systemTemp.createTemp(
        'sarathi-persistence-',
      );
      final file = File(
        '${folder.path}${Platform.pathSeparator}academic.sqlite',
      );
      final first = AcademicStore(
        database: AcademicDatabase(NativeDatabase(file)),
      );
      try {
        await first.initialize();
        expect(first.hasConsent, isFalse);
        await expectLater(
          first.addAssignment(
            title: 'Blocked',
            subject: 'Networks',
            dueDate: DateTime(2026, 10, 21),
          ),
          throwsStateError,
        );
        await first.grantLocalConsent();
        final due = DateTime(2026, 10, 21, 17, 30);
        await first.addAssignment(
          title: 'Lab report',
          subject: 'Networks',
          dueDate: due,
        );
        final id = first.assignments.single.id;
        final recorded = first.assignments.single.recordedAt;
        await first.toggleAssignment(id);
        await first.addClass(
          const ClassSession(
            id: 'not-trusted-as-record-id',
            subject: 'Networks',
            room: 'AB1',
            day: 1,
            startTime: TimeOfDayValue(9, 15),
            endTime: TimeOfDayValue(10, 5),
          ),
        );
        await first.saveAttendance(
          subject: 'Networks',
          attended: 15,
          total: 20,
          minimumPercentage: 80,
        );
        await first.close();
        first.dispose();

        final second = AcademicStore(
          database: AcademicDatabase(NativeDatabase(file)),
        );
        try {
          await second.initialize();
          expect(second.hasConsent, isTrue);
          final saved = second.assignments.single;
          expect(saved.id, id);
          expect(saved.status, AssignmentStatus.complete);
          expect(saved.dueDate, due);
          expect(saved.recordedAt, recorded);
          expect(saved.sourceLabel, 'Student-entered');
          expect(second.classes.single.startTime.minute, 15);
          expect(second.classes.single.recordedAt, isNotNull);
          expect(second.attendance.single.minimumPercentage, 80);
          expect(second.attendance.single.isBelowMinimum, isTrue);
          await second.eraseLocalData();
          expect(second.hasConsent, isFalse);
          expect(second.assignments, isEmpty);
          await expectLater(
            second.saveAttendance(subject: 'Networks', attended: 1, total: 1),
            throwsStateError,
          );
        } finally {
          await second.close();
          second.dispose();
        }

        final third = AcademicStore(
          database: AcademicDatabase(NativeDatabase(file)),
        );
        try {
          await third.initialize();
          expect(third.hasConsent, isFalse);
          await third.grantLocalConsent();
          expect(third.assignments, isEmpty);
          expect(third.classes, isEmpty);
          expect(third.attendance, isEmpty);
        } finally {
          await third.close();
          third.dispose();
        }
      } finally {
        // This directory is exclusively created by this test.
        await folder.delete(recursive: true);
      }
    },
  );

  test(
    'SQLite constraints reject impossible records even outside repository',
    () async {
      final database = AcademicDatabase(NativeDatabase.memory());
      try {
        await expectLater(
          database.customStatement(
            "INSERT INTO local_attendance(subject_key,subject,attended,conducted,updated_at) VALUES ('networks','Networks',11,10,0)",
          ),
          throwsA(anything),
        );
        await expectLater(
          database.customStatement(
            "INSERT INTO local_classes(id,subject,room,weekday,start_minute,end_minute,recorded_at) VALUES ('bad','Networks','AB1',1,600,500,0)",
          ),
          throwsA(anything),
        );
        expect(await database.select(database.localAttendance).get(), isEmpty);
        expect(await database.select(database.localClasses).get(), isEmpty);
      } finally {
        await database.close();
      }
    },
  );

  test(
    'transaction failure rolls back earlier writes and does not erase data',
    () async {
      final database = AcademicDatabase(NativeDatabase.memory());
      final store = AcademicStore(database: database);
      try {
        await store.initialize();
        await store.grantLocalConsent();
        await store.saveAttendance(subject: 'Existing', attended: 1, total: 2);
        await expectLater(
          database.transaction(() async {
            await database.customStatement(
              "INSERT INTO local_attendance(subject_key,subject,attended,conducted,updated_at) VALUES ('new','New',1,2,0)",
            );
            await database.customStatement(
              "INSERT INTO local_attendance(subject_key,subject,attended,conducted,updated_at) VALUES ('bad','Bad',4,2,0)",
            );
          }),
          throwsA(anything),
        );
        final rows = await database.select(database.localAttendance).get();
        expect(rows, hasLength(1));
        expect(rows.single.subject, 'Existing');
      } finally {
        await store.close();
        store.dispose();
      }
    },
  );

  test(
    'failed SQLite save leaves no visible success and permits a safe retry',
    () async {
      final database = AcademicDatabase(NativeDatabase.memory());
      final store = AcademicStore(database: database);
      try {
        await store.initialize();
        await store.grantLocalConsent();
        await database.customStatement(
          "CREATE TRIGGER reject_assignment BEFORE INSERT ON local_assignments BEGIN SELECT RAISE(ABORT, 'test write failure'); END",
        );
        await expectLater(
          store.addAssignment(
            title: 'Lab',
            subject: 'Networks',
            dueDate: DateTime(2026, 10, 21),
          ),
          throwsA(anything),
        );
        expect(store.assignments, isEmpty);
        expect(store.busy, isFalse);
        expect(await database.select(database.localAssignments).get(), isEmpty);
        await database.customStatement('DROP TRIGGER reject_assignment');
        await store.addAssignment(
          title: 'Lab',
          subject: 'Networks',
          dueDate: DateTime(2026, 10, 21),
        );
        expect(store.assignments, hasLength(1));
      } finally {
        await store.close();
        store.dispose();
      }
    },
  );

  testWidgets('local consent starts unchecked and blocks academic screens', (
    tester,
  ) async {
    final store = AcademicStore(
      database: AcademicDatabase(NativeDatabase.memory()),
    );
    await store.initialize();
    addTearDown(() async {
      await store.close();
      store.dispose();
    });
    await tester.pumpWidget(CampusSarathiApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsNothing);
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isFalse,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Continue with local records'),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Read the local privacy notice'));
    await tester.pumpAndSettle();
    expect(find.text('Local privacy notice'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.text('Continue with local records'));
    await tester.pumpAndSettle();
    expect(store.hasConsent, isTrue);
    expect(find.byType(NavigationBar), findsOneWidget);
    await store.addAssignment(
      title: 'Local test',
      subject: 'Networks',
      dueDate: DateTime(2026, 10, 21),
    );
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Erase local records'), 100);
    await tester.tap(find.text('Erase local records'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep records'));
    await tester.pumpAndSettle();
    expect(store.assignments, hasLength(1));
    await tester.tap(find.text('Erase local records'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Erase records'));
    await tester.pumpAndSettle();
    expect(store.hasConsent, isFalse);
    expect(store.assignments, isEmpty);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
