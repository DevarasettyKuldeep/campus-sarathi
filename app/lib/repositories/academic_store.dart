import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/local/academic_database.dart';
import '../models/academic_models.dart';
import '../features/profile/student_profile.dart';

typedef _Snapshot = ({
  List<Assignment> assignments,
  List<ClassSession> classes,
  List<AttendanceRecord> attendance,
  StudentProfile? profile,
});

/// Device-local academic records, never proof of an authenticated server session.
/// The configured shell supplies an account-scoped database. Guest records stay
/// separate; any future import or server upload needs its own explicit flow.
class AcademicStore extends ChangeNotifier {
  AcademicStore({required AcademicDatabase database}) : _database = database;
  static const noticeVersion = 'local-academic-3';
  final AcademicDatabase _database;
  static const _uuid = Uuid();
  bool _ready = false;
  bool _consented = false;
  bool _busy = false;
  bool _closing = false;
  bool _disposed = false;
  Completer<void>? _idle;
  Future<void>? _closeFuture;
  bool get hasConsent => _consented;
  bool get busy => _busy;
  final List<Assignment> _assignments = [];
  final List<ClassSession> _classes = [];
  final List<AttendanceRecord> _attendance = [];
  StudentProfile? _profile;
  StudentProfile? get profile => _profile;
  AcademicDatabase get database => _database;
  void Function(StudentProfile)? onProfileSaved;

  List<Assignment> get assignments => List.unmodifiable(_assignments);
  List<ClassSession> get classes => List.unmodifiable(_classes);
  List<AttendanceRecord> get attendance => List.unmodifiable(_attendance);

  Future<void> initialize() async {
    if (_ready) return;
    final consent = await (_database.select(
      _database.localConsents,
    )..where((row) => row.id.equals(1))).getSingleOrNull();
    _consented = consent?.noticeVersion == noticeVersion;
    if (_consented) await _reload();
    _ready = true;
  }

  Future<void> grantLocalConsent() async {
    if (!_ready || _busy || _closing) throw StateError('Storage is not ready.');
    _idle = Completer<void>();
    _busy = true;
    notifyListeners();
    try {
      final snapshot = await _database.transaction(() async {
        await _database
            .into(_database.localConsents)
            .insertOnConflictUpdate(
              LocalConsentsCompanion.insert(
                id: const Value(1),
                noticeVersion: noticeVersion,
                grantedAt: DateTime.now().toUtc(),
              ),
            );
        return _readSnapshot();
      });
      _publish(snapshot);
      _consented = true;
    } finally {
      _busy = false;
      _idle?.complete();
      _idle = null;
      notifyListeners();
    }
  }

  Future<void> eraseLocalData() async {
    if (!_ready || _busy || _closing) throw StateError('Storage is not ready.');
    _idle = Completer<void>();
    _busy = true;
    notifyListeners();
    try {
      await _database.eraseLocalData();
      _assignments.clear();
      _classes.clear();
      _attendance.clear();
      _profile = null;
      _consented = false;
    } finally {
      _busy = false;
      _idle?.complete();
      _idle = null;
      notifyListeners();
    }
  }

  Future<void> saveProfile(StudentProfile profile) {
    profile.validate();
    return _commit(() async {
      await _database
          .into(_database.localAcademicProfiles)
          .insertOnConflictUpdate(
            LocalAcademicProfilesCompanion.insert(
              id: const Value(1),
              programme: profile.programme.trim(),
              semesterNumber: profile.semesterNumber,
              semesterStart: profile.semesterStart,
              semesterEnd: profile.semesterEnd,
              updatedAt: DateTime.now().toUtc(),
            ),
          );
      onProfileSaved?.call(profile);
    });
  }

  Future<void> addAssignment({
    required String title,
    required String subject,
    required DateTime dueDate,
  }) {
    _requireText(title, 'Title');
    _requireText(subject, 'Subject');
    final now = DateTime.now().toUtc();
    return _commit(() async {
      await _database
          .into(_database.localAssignments)
          .insert(
            LocalAssignmentsCompanion.insert(
              id: _uuid.v4(),
              title: title.trim(),
              subject: subject.trim(),
              dueDate: dueDate,
              recordedAt: now,
              updatedAt: now,
            ),
          );
    });
  }

  Future<void> toggleAssignment(String id) => _commit(() async {
    final row = await (_database.select(
      _database.localAssignments,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (row == null) throw StateError('Assignment no longer exists.');
    await (_database.update(
      _database.localAssignments,
    )..where((row) => row.id.equals(id))).write(
      LocalAssignmentsCompanion(
        complete: Value(!row.complete),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  });

  Future<void> addClass(ClassSession session) {
    _requireText(session.subject, 'Subject');
    _requireText(session.room, 'Room');
    final start = session.startTime.hour * 60 + session.startTime.minute;
    final end = session.endTime.hour * 60 + session.endTime.minute;
    if (session.day < 1 ||
        session.day > 7 ||
        !_validTime(session.startTime) ||
        !_validTime(session.endTime) ||
        end <= start) {
      throw ArgumentError(
        'Choose a valid day and an end time after the start.',
      );
    }
    return _commit(() async {
      await _database
          .into(_database.localClasses)
          .insert(
            LocalClassesCompanion.insert(
              id: _uuid.v4(),
              subject: session.subject.trim(),
              room: session.room.trim(),
              weekday: session.day,
              startMinute: start,
              endMinute: end,
              recordedAt: DateTime.now().toUtc(),
            ),
          );
    });
  }

  Future<void> saveAttendance({
    required String subject,
    required int attended,
    required int total,
    double? minimumPercentage,
  }) {
    _requireText(subject, 'Subject');
    if (attended < 0 || total < 0 || attended > total || total > 100000) {
      throw ArgumentError(
        'Attendance must satisfy 0 ≤ attended ≤ total ≤ 100000.',
      );
    }
    if (minimumPercentage != null &&
        (!minimumPercentage.isFinite ||
            minimumPercentage <= 0 ||
            minimumPercentage > 100)) {
      throw ArgumentError(
        'Minimum percentage must be greater than 0 and at most 100.',
      );
    }
    return _commit(() async {
      await _database
          .into(_database.localAttendance)
          .insertOnConflictUpdate(
            LocalAttendanceCompanion.insert(
              subjectKey: subject.trim().toLowerCase(),
              subject: subject.trim(),
              attended: attended,
              conducted: total,
              minimumPercentage: Value(minimumPercentage),
              updatedAt: DateTime.now().toUtc(),
            ),
          );
    });
  }

  Future<void> _commit(Future<void> Function() action) async {
    if (!_ready || !_consented || _closing) {
      throw StateError('Academic processing consent is required.');
    }
    if (_busy) throw StateError('A save is already in progress.');
    _idle = Completer<void>();
    _busy = true;
    notifyListeners();
    try {
      final snapshot = await _database.transaction(() async {
        await action();
        return _readSnapshot();
      });
      _publish(snapshot);
    } finally {
      _busy = false;
      _idle?.complete();
      _idle = null;
      notifyListeners();
    }
  }

  Future<void> _reload() async => _publish(await _readSnapshot());

  Future<_Snapshot> _readSnapshot() => _database.transaction(() async {
    final profile = await _database
        .select(_database.localAcademicProfiles)
        .getSingleOrNull();
    final assignments = await (_database.select(
      _database.localAssignments,
    )..orderBy([(r) => OrderingTerm.asc(r.dueDate)])).get();
    final classes =
        await (_database.select(_database.localClasses)..orderBy([
              (r) => OrderingTerm.asc(r.weekday),
              (r) => OrderingTerm.asc(r.startMinute),
            ]))
            .get();
    final attendance = await (_database.select(
      _database.localAttendance,
    )..orderBy([(r) => OrderingTerm.asc(r.subjectKey)])).get();
    final nextAssignments = assignments
        .map(
          (r) => Assignment(
            id: r.id,
            title: r.title,
            subject: r.subject,
            dueDate: r.dueDate,
            status: r.complete
                ? AssignmentStatus.complete
                : AssignmentStatus.pending,
            recordedAt: r.recordedAt,
            updatedAt: r.updatedAt,
          ),
        )
        .toList();
    final nextClasses = classes
        .map(
          (r) => ClassSession(
            id: r.id,
            subject: r.subject,
            room: r.room,
            day: r.weekday,
            startTime: TimeOfDayValue(r.startMinute ~/ 60, r.startMinute % 60),
            endTime: TimeOfDayValue(r.endMinute ~/ 60, r.endMinute % 60),
            recordedAt: r.recordedAt,
          ),
        )
        .toList();
    final nextAttendance = attendance
        .map(
          (r) => AttendanceRecord(
            subject: r.subject,
            attended: r.attended,
            total: r.conducted,
            updatedAt: r.updatedAt,
            minimumPercentage: r.minimumPercentage,
          ),
        )
        .toList();
    return (
      assignments: nextAssignments,
      classes: nextClasses,
      attendance: nextAttendance,
      profile: profile == null
          ? null
          : StudentProfile(
              programme: profile.programme,
              semesterNumber: profile.semesterNumber,
              semesterStart: profile.semesterStart,
              semesterEnd: profile.semesterEnd,
              updatedAt: profile.updatedAt,
            ),
    );
  });

  // Publish only after the write AND reload transaction commits. Failed disk
  // writes must not appear saved or leave a persisted but unacknowledged insert.
  void _publish(_Snapshot snapshot) {
    _profile = snapshot.profile;
    _assignments
      ..clear()
      ..addAll(snapshot.assignments);
    _classes
      ..clear()
      ..addAll(snapshot.classes);
    _attendance
      ..clear()
      ..addAll(snapshot.attendance);
  }

  Future<void> close() => _closeFuture ??= _close();

  Future<void> _close() async {
    _closing = true;
    await (_idle?.future ?? Future<void>.value());
    await _database.close();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _assignments.clear();
    _classes.clear();
    _attendance.clear();
    _profile = null;
    super.dispose();
  }

  void _requireText(String value, String label) {
    if (value.trim().isEmpty || value.trim().length > 200) {
      throw ArgumentError('$label must contain 1–200 characters.');
    }
  }

  bool _validTime(TimeOfDayValue time) =>
      time.hour >= 0 && time.hour < 24 && time.minute >= 0 && time.minute < 60;
}
