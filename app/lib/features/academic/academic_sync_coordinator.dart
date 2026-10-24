import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../models/academic_models.dart';
import '../../repositories/academic_store.dart';
import '../auth/session_controller.dart';
import '../profile/profile_sync_controller.dart';
import 'academic_api.dart';

class AcademicSyncCoordinator extends ChangeNotifier {
  AcademicSyncCoordinator({
    required AcademicStore store,
    required AcademicApi api,
    required SessionController session,
    ProfileSyncController? profileSync,
  })  : _store = store,
        _api = api,
        _session = session,
        _profileSync = profileSync;

  final AcademicStore _store;
  final AcademicApi _api;
  final SessionController _session;
  final ProfileSyncController? _profileSync;
  static const _uuid = Uuid();

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  DateTime? _lastSyncedAt;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  String? _lastError;
  String? get lastError => _lastError;

  final List<Announcement> _announcements = [];
  List<Announcement> get announcements => List.unmodifiable(_announcements);

  bool _busy = false;
  bool get busy => _busy;

  Future<void> syncNow() async {
    if (_busy) return;
    final tokens = _session.tokens;
    if (tokens == null) {
      _status = SyncStatus.idle;
      notifyListeners();
      return;
    }

    // Check cloud consent
    final consent = _profileSync?.cloudConsent;
    if (consent == null || !consent.granted || consent.sequence == null) {
      _status = SyncStatus.consentRequired;
      notifyListeners();
      return;
    }

    _busy = true;
    _status = SyncStatus.syncing;
    _lastError = null;
    notifyListeners();

    try {
      final assignmentsPayload = _store.assignments.map((a) => {
        'id': a.id,
        'subjectName': a.subject,
        'title': a.title,
        'dueAt': a.dueDate.toIso8601String(),
        'completed': a.status == AssignmentStatus.complete,
      }).toList();

      final classesPayload = _store.classes.map((c) => {
        'id': c.id,
        'subjectName': c.subject,
        'weekday': c.day,
        'startMinute': c.startTime.hour * 60 + c.startTime.minute,
        'endMinute': c.endTime.hour * 60 + c.endTime.minute,
        'room': c.room,
      }).toList();

      final attendancePayload = _store.attendance.map((att) => {
        'subjectKey': att.subject.toLowerCase(),
        'subjectName': att.subject,
        'attended': att.attended,
        'conducted': att.total,
        if (att.minimumPercentage != null) 'minimumPercentage': att.minimumPercentage,
      }).toList();

      final operationId = _uuid.v4();
      await _api.syncAcademic(
        tokens.accessToken,
        operationId: operationId,
        consentSequence: consent.sequence!,
        assignments: assignmentsPayload,
        classes: classesPayload,
        attendance: attendancePayload,
      );

      // Fetch latest official announcements
      try {
        final fetched = await _api.getAnnouncements(tokens.accessToken);
        _announcements.clear();
        _announcements.addAll(fetched);
        _store.setAnnouncements(fetched);
      } catch (_) {
        // Announcements failure is non-blocking for academic record sync
      }

      _lastSyncedAt = DateTime.now().toUtc();
      _status = SyncStatus.synced;
    } on AcademicApiFailure catch (e) {
      if (e.kind == AcademicApiFailureKind.consentRequired) {
        _status = SyncStatus.consentRequired;
      } else if (e.kind == AcademicApiFailureKind.conflict) {
        _status = SyncStatus.conflict;
      } else {
        _status = SyncStatus.error;
      }
      _lastError = e.message;
    } catch (e) {
      _status = SyncStatus.error;
      _lastError = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
