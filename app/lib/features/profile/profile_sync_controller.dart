import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/academic_database.dart';
import '../../repositories/academic_store.dart';
import '../auth/session_controller.dart';
import 'profile_api.dart';
import 'student_profile.dart';

enum SyncStatus {
  idle,
  syncing,
  synced,
  consentRequired,
  conflict,
  error,
}

class ProfileSyncController extends ChangeNotifier {
  ProfileSyncController({
    required AcademicDatabase database,
    required AcademicStore store,
    required ProfileApi api,
    required SessionController session,
  })  : _database = database,
        _store = store,
        _api = api,
        _session = session;

  final AcademicDatabase _database;
  final AcademicStore _store;
  final ProfileApi _api;
  final SessionController _session;
  AcademicStore get store => _store;
  static const _uuid = Uuid();

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  CloudConsentState? _cloudConsent;
  CloudConsentState? get cloudConsent => _cloudConsent;

  ServerNotice? _serverNotice;
  ServerNotice? get serverNotice => _serverNotice;

  String? _lastError;
  String? get lastError => _lastError;

  int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  bool _busy = false;
  bool get busy => _busy;
  bool _syncing = false;
  bool get isSyncing => _syncing;

  Future<void> initialize() async {
    await refreshPendingCount();
    if (_session.account != null) {
      unawaited(fetchServerStatus());
    }
  }

  Future<void> refreshPendingCount() async {
    final pending = await (_database.select(_database.localSyncOutbox)
          ..where((row) => row.status.equals('pending')))
        .get();
    _pendingCount = pending.length;
    notifyListeners();
  }

  Future<void> fetchServerStatus() async {
    final tokens = _session.tokens;
    if (tokens == null) return;
    try {
      _serverNotice = await _api.getNotice();
      _cloudConsent = await _api.getConsent(tokens.accessToken);
      notifyListeners();
    } catch (_) {
      // Offline or server not ready
    }
  }

  Future<void> grantCloudConsent() async {
    final tokens = _session.tokens;
    if (tokens == null) throw StateError('Not signed in.');
    _busy = true;
    notifyListeners();
    try {
      final notice = _serverNotice ?? await _api.getNotice();
      _serverNotice = notice;
      _cloudConsent = await _api.setConsent(
        tokens.accessToken,
        granted: true,
        noticeVersion: notice.version,
        expectedSequence: _cloudConsent?.sequence,
      );
      _status = SyncStatus.idle;
      _lastError = null;
    } on ProfileFailure catch (e) {
      _lastError = e.message;
      _status = SyncStatus.error;
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
    await syncPending();
  }

  Future<void> withdrawCloudConsent() async {
    final tokens = _session.tokens;
    if (tokens == null) throw StateError('Not signed in.');
    _busy = true;
    notifyListeners();
    try {
      final notice = _serverNotice ?? await _api.getNotice();
      _cloudConsent = await _api.setConsent(
        tokens.accessToken,
        granted: false,
        noticeVersion: notice.version,
        expectedSequence: _cloudConsent?.sequence,
      );
      _status = SyncStatus.consentRequired;
    } on ProfileFailure catch (e) {
      _lastError = e.message;
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Atomically queues a profile sync operation into SQLite outbox.
  Future<void> enqueueProfileSync(StudentProfile profile, {int expectedRevision = 0}) async {
    final opId = _uuid.v4();
    final payload = jsonEncode({
      'profile': {
        'programme': profile.programme,
        'semesterNumber': profile.semesterNumber,
        'semesterStart': profile.semesterStart,
        'semesterEnd': profile.semesterEnd,
        'timezone': 'Asia/Kolkata',
        'expectedRevision': expectedRevision,
      },
      'expectedRevision': expectedRevision,
    });

    await _database.into(_database.localSyncOutbox).insertOnConflictUpdate(
          LocalSyncOutboxCompanion.insert(
            operationId: opId,
            entityType: 'profile',
            payloadJson: payload,
            createdAt: DateTime.now().toUtc(),
            status: const Value('pending'),
          ),
        );

    await refreshPendingCount();
    await syncPending();
  }

  /// Process pending outbox queue
  Future<void> syncPending() async {
    if (_syncing) return;
    final tokens = _session.tokens;
    if (tokens == null) return;

    if (_cloudConsent == null) {
      await fetchServerStatus();
    }

    if (_cloudConsent?.granted != true) {
      _status = SyncStatus.consentRequired;
      notifyListeners();
      return;
    }

    final consentSeq = _cloudConsent?.sequence;
    if (consentSeq == null) return;

    _syncing = true;
    _status = SyncStatus.syncing;
    notifyListeners();

    try {
      final pendingOps = await (_database.select(_database.localSyncOutbox)
            ..where((row) => row.status.equals('pending'))
            ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
          .get();

      for (final op in pendingOps) {
        if (op.entityType == 'profile') {
          try {
            final data = jsonDecode(op.payloadJson) as Map<String, dynamic>;
            final profileMap = data['profile'] as Map<String, dynamic>;
            final expectedRev = (data['expectedRevision'] as num?)?.toInt() ?? 0;

            final studentProfile = StudentProfile(
              programme: profileMap['programme'] as String,
              semesterNumber: profileMap['semesterNumber'] as int,
              semesterStart: profileMap['semesterStart'] as String,
              semesterEnd: profileMap['semesterEnd'] as String,
              updatedAt: DateTime.now().toUtc(),
            );

            await _api.syncProfile(
              tokens.accessToken,
              operationId: op.operationId,
              consentSequence: consentSeq,
              profile: studentProfile,
              expectedRevision: expectedRev,
            );

            // Operation succeeded: remove from outbox
            await (_database.delete(_database.localSyncOutbox)
                  ..where((row) => row.operationId.equals(op.operationId)))
                .go();
          } on ProfileFailure catch (err) {
            if (err.kind == ProfileFailureKind.conflict) {
              await (_database.update(_database.localSyncOutbox)
                    ..where((row) => row.operationId.equals(op.operationId)))
                  .write(
                LocalSyncOutboxCompanion(
                  status: const Value('conflict'),
                  lastError: Value(err.message),
                  lastAttemptAt: Value(DateTime.now().toUtc()),
                ),
              );
              _status = SyncStatus.conflict;
              _lastError = err.message;
              break;
            } else if (err.kind == ProfileFailureKind.consentRequired) {
              _status = SyncStatus.consentRequired;
              _lastError = err.message;
              break;
            } else {
              await (_database.update(_database.localSyncOutbox)
                    ..where((row) => row.operationId.equals(op.operationId)))
                  .write(
                LocalSyncOutboxCompanion(
                  attempts: Value(op.attempts + 1),
                  lastError: Value(err.message),
                  lastAttemptAt: Value(DateTime.now().toUtc()),
                ),
              );
              _status = SyncStatus.error;
              _lastError = err.message;
            }
          }
        }
      }

      await refreshPendingCount();
      if (_status != SyncStatus.conflict && _status != SyncStatus.consentRequired) {
        _status = _pendingCount == 0 ? SyncStatus.synced : SyncStatus.idle;
      }
    } catch (e) {
      _status = SyncStatus.error;
      _lastError = e.toString();
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }
}
