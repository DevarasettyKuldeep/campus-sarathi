import 'package:campus_sarathi/main.dart';
import 'package:campus_sarathi/models/academic_models.dart';
import 'package:campus_sarathi/repositories/academic_store.dart';
import 'package:campus_sarathi/widgets/manual_editors.dart';
import 'package:flutter/material.dart';
import 'package:drift/native.dart';
import 'package:campus_sarathi/data/local/academic_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AcademicStore store;
  setUp(() async {
    store = AcademicStore(database: AcademicDatabase(NativeDatabase.memory()));
    await store.initialize();
    await store.grantLocalConsent();
  });
  tearDown(() async {
    await store.close();
    store.dispose();
  });

  test('invalid attendance does not mutate or notify', () async {
    var notifications = 0;
    store.addListener(() => notifications++);
    for (final counts in [(-1, 10), (11, 10), (1, -1), (1, 100001)]) {
      expect(
        () => store.saveAttendance(
          subject: 'Networks',
          attended: counts.$1,
          total: counts.$2,
        ),
        throwsArgumentError,
      );
    }
    expect(store.attendance, isEmpty);
    expect(notifications, 0);
  });

  test(
    'zero classes and absent policy never produce attendance advice',
    () async {
      await store.saveAttendance(subject: 'Networks', attended: 0, total: 0);
      expect(store.attendance.single.percentage, isNull);
      expect(store.attendance.single.isBelowMinimum, isNull);
      await store.saveAttendance(subject: 'Networks', attended: 7, total: 10);
      expect(store.attendance.single.percentage, 70);
      expect(store.attendance.single.isBelowMinimum, isNull);
    },
  );

  test(
    'student-entered policy compares exact values without rounding risk',
    () async {
      await store.saveAttendance(
        subject: 'Networks',
        attended: 749,
        total: 1000,
        minimumPercentage: 75,
      );
      final record = store.attendance.single;
      expect(record.isBelowMinimum, isTrue);
      expect(record.sourceLabel, 'Student-entered');
      expect(
        record.updatedAt.difference(DateTime.now()).inSeconds.abs(),
        lessThan(2),
      );
    },
  );

  test(
    'reject invalid policy and blank subjects at the repository boundary',
    () async {
      for (final value in [0.0, -1.0, 101.0, double.nan, double.infinity]) {
        expect(
          () => store.saveAttendance(
            subject: 'Networks',
            attended: 1,
            total: 1,
            minimumPercentage: value,
          ),
          throwsArgumentError,
        );
      }
      expect(
        () => store.saveAttendance(subject: ' ', attended: 1, total: 1),
        throwsArgumentError,
      );
    },
  );

  test(
    'case-insensitive manual attendance update replaces the same subject',
    () async {
      await store.saveAttendance(subject: ' Networks ', attended: 2, total: 3);
      await store.saveAttendance(subject: 'networks', attended: 3, total: 4);
      expect(store.attendance, hasLength(1));
      expect(store.attendance.single.attended, 3);
    },
  );

  ClassSession session(
    String id,
    int hour,
    int minute, {
    int day = 1,
    int endHour = 12,
  }) => ClassSession(
    id: id,
    subject: 'Networks',
    room: 'AB1',
    day: day,
    startTime: TimeOfDayValue(hour, minute),
    endTime: TimeOfDayValue(endHour, 0),
  );

  test(
    'recurring classes reject invalid day/time and reversed range',
    () async {
      for (final entry in [
        session('bad-day', 9, 0, day: 8),
        session('bad-minute', 9, 60),
        session('backward', 13, 0),
      ]) {
        expect(() => store.addClass(entry), throwsArgumentError);
      }
      expect(store.classes, isEmpty);
    },
  );

  test('class ordering respects weekday and minute precision', () async {
    await store.addClass(session('later', 9, 50));
    await store.addClass(session('next-day', 8, 0, day: 2));
    await store.addClass(session('earlier', 9, 5));
    expect(store.classes.map((item) => item.startTime.minute), [5, 50, 0]);
  });

  test(
    'assignment validation and completion preserve stored title/deadline',
    () async {
      final due = DateTime(2026, 10, 20);
      expect(
        () =>
            store.addAssignment(title: ' ', subject: 'Networks', dueDate: due),
        throwsArgumentError,
      );
      await store.addAssignment(
        title: ' Lab report ',
        subject: ' Networks ',
        dueDate: due,
      );
      final saved = store.assignments.single;
      await store.toggleAssignment(saved.id);
      expect(store.assignments.single.status, AssignmentStatus.complete);
      expect(store.assignments.single.title, 'Lab report');
      expect(store.assignments.single.dueDate, due);
    },
  );

  testWidgets(
    'attendance form gives field errors and saves valid manual data',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ManualEditor(store: store, type: ManualEntryType.attendance),
        ),
      );
      await tester.tap(find.text('Save record'));
      await tester.pump();
      expect(find.text('This field is required.'), findsOneWidget);
      final inputs = find.byType(TextFormField);
      await tester.enterText(inputs.at(0), 'Networks');
      await tester.enterText(inputs.at(1), '11');
      await tester.enterText(inputs.at(2), '10');
      await tester.tap(find.text('Save record'));
      await tester.pump();
      expect(
        find.text('Total cannot be less than attended classes.'),
        findsOneWidget,
      );
      expect(store.attendance, isEmpty);
      await tester.enterText(inputs.at(1), '7');
      await tester.tap(find.text('Save record'));
      await tester.pumpAndSettle();
      expect(store.attendance.single.percentage, 70);
      expect(store.attendance.single.minimumPercentage, isNull);
    },
  );

  testWidgets('capture editor scrolls on small screens with keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: ManualEditor(store: store, type: ManualEntryType.attendance),
      ),
    );
    await tester.tap(find.byType(TextFormField).first);
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Save record'),
      150,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'application starts empty and assistant has no fake chat response',
    (tester) async {
      await tester.pumpWidget(CampusSarathiApp(store: store));
      await tester.pumpAndSettle();
      expect(find.text('No classes saved for today.'), findsOneWidget);
      await tester.tap(find.text('Assistant'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.textContaining('not available yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
