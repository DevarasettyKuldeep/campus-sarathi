import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_sarathi/data/local/academic_database.dart';
import 'package:campus_sarathi/features/auth/auth_models.dart';
import 'package:campus_sarathi/features/auth/session_controller.dart';
import 'package:campus_sarathi/features/auth/session_vault.dart';
import 'package:campus_sarathi/features/auth/google_identity.dart';
import 'package:campus_sarathi/features/auth/auth_api.dart';
import 'package:campus_sarathi/features/profile/profile_api.dart';
import 'package:campus_sarathi/features/profile/profile_sync_controller.dart';
import 'package:campus_sarathi/features/profile/student_profile.dart';
import 'package:campus_sarathi/repositories/academic_store.dart';

class MockProfileApi implements ProfileApi {
  ServerNotice notice = const ServerNotice(
    version: 'server-academic-dev-1',
    developmentOnly: true,
    text: 'Test notice text',
  );
  CloudConsentState consent = const CloudConsentState(
    purpose: 'ACADEMIC_PROCESSING',
    granted: false,
    sequence: null,
  );
  int syncCalls = 0;
  ProfileFailure? syncFailure;
  String? lastOperationId;
  StudentProfile? lastSyncedProfile;

  @override
  Future<ServerNotice> getNotice() async => notice;

  @override
  Future<CloudConsentState> getConsent(String accessToken) async => consent;

  @override
  Future<CloudConsentState> setConsent(
    String accessToken, {
    required bool granted,
    required String noticeVersion,
    String? expectedSequence,
  }) async {
    consent = CloudConsentState(
      purpose: 'ACADEMIC_PROCESSING',
      granted: granted,
      noticeVersion: noticeVersion,
      sequence: (int.parse(expectedSequence ?? '0') + 1).toString(),
      eventAt: DateTime.now().toUtc().toIso8601String(),
    );
    return consent;
  }

  @override
  Future<CloudProfile?> getProfile(String accessToken) async => null;

  @override
  Future<ProfileSyncResult> syncProfile(
    String accessToken, {
    required String operationId,
    required String consentSequence,
    required StudentProfile profile,
    required int expectedRevision,
  }) async {
    syncCalls++;
    lastOperationId = operationId;
    lastSyncedProfile = profile;
    if (syncFailure != null) throw syncFailure!;
    return ProfileSyncResult(
      operationId: operationId,
      profile: CloudProfile(
        programme: profile.programme,
        semesterNumber: profile.semesterNumber,
        semesterStart: profile.semesterStart,
        semesterEnd: profile.semesterEnd,
        timezone: profile.timezone,
        revision: expectedRevision + 1,
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      ),
    );
  }
}

class MockAuthApi implements AuthApi {
  bool deleteCalled = false;
  @override
  Future<SavedSession> exchange(String idToken) async => throw UnimplementedError();
  @override
  Future<SessionTokens> refresh(String refreshToken) async => throw UnimplementedError();
  @override
  Future<StudentAccount> me(String accessToken) async => const StudentAccount(
        id: 'a0000000-0000-0000-0000-000000000001',
        email: 'student@cb.students.amrita.edu',
        displayName: 'Student',
      );
  @override
  Future<void> logout(String accessToken) async {}
  @override
  Future<void> deleteAccount(String accessToken) async {
    deleteCalled = true;
  }
}

class MemoryVault implements SessionVault {
  SavedSession? saved;
  @override
  Future<SavedSession?> read() async => saved;
  @override
  Future<void> write(SavedSession session) async {
    saved = session;
  }
  @override
  Future<void> clear() async {
    saved = null;
  }
}

class TestIdentity implements StudentIdentityProvider {
  @override
  Future<String?> authenticate() async => 'test-id-token';
  @override
  Future<void> signOut() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HttpProfileApi', () {
    test('enforces HTTPS and /api/v1 base URL', () {
      expect(
        () => HttpProfileApi.validateBase(Uri.parse('http://example.com/api/v1')),
        throwsArgumentError,
      );
      expect(
        () => HttpProfileApi.validateBase(Uri.parse('https://example.com/api/v2')),
        throwsArgumentError,
      );
      final validated = HttpProfileApi.validateBase(Uri.parse('https://example.com/api/v1'));
      expect(validated.toString(), 'https://example.com/api/v1/');
    });
  });

  group('ProfileSyncController', () {
    late AcademicDatabase db;
    late AcademicStore store;
    late MockProfileApi api;
    late SessionController session;
    late MockAuthApi authApi;
    late MemoryVault vault;

    final student = const StudentAccount(
      id: 'a0000000-0000-0000-0000-000000000001',
      email: 'student@cb.students.amrita.edu',
      displayName: 'Student',
    );

    setUp(() async {
      db = AcademicDatabase(NativeDatabase.memory());
      store = AcademicStore(database: db);
      await store.initialize();
      await store.grantLocalConsent();

      api = MockProfileApi();
      authApi = MockAuthApi();
      vault = MemoryVault();
      session = SessionController(
        api: authApi,
        identity: TestIdentity(),
        vault: vault,
        eraseAccountWorkspace: (id) async {},
      );

      // Pre-seed an active session in controller
      final active = SavedSession(
        account: student,
        tokens: SessionTokens(
          accessToken: 'test-token',
          refreshToken: 'test-refresh-token'.padRight(43, '0'),
          expiresAt: DateTime.now().add(const Duration(minutes: 15)),
          refreshExpiresAt: DateTime.now().add(const Duration(days: 30)),
        ),
      );
      await vault.write(active);
      await session.initialize();
    });

    tearDown(() async {
      session.dispose();
      await store.close();
      store.dispose();
      await db.close();
    });

    test('enqueueProfileSync adds operation to local outbox', () async {
      final syncCtrl = ProfileSyncController(
        database: db,
        store: store,
        api: api,
        session: session,
      );
      await syncCtrl.initialize();

      final prof = StudentProfile(
        programme: 'B.Tech CSE',
        semesterNumber: 4,
        semesterStart: '2026-07-20',
        semesterEnd: '2026-11-30',
        updatedAt: DateTime.now().toUtc(),
      );

      await syncCtrl.enqueueProfileSync(prof);

      final outboxItems = await db.select(db.localSyncOutbox).get();
      expect(outboxItems.length, 1);
      expect(outboxItems.first.entityType, 'profile');
      expect(outboxItems.first.status, 'pending');
    });

    test('syncPending halts with consentRequired if cloud consent not granted', () async {
      final syncCtrl = ProfileSyncController(
        database: db,
        store: store,
        api: api,
        session: session,
      );
      await syncCtrl.initialize();

      final prof = StudentProfile(
        programme: 'B.Tech CSE',
        semesterNumber: 4,
        semesterStart: '2026-07-20',
        semesterEnd: '2026-11-30',
        updatedAt: DateTime.now().toUtc(),
      );

      await syncCtrl.enqueueProfileSync(prof);
      await syncCtrl.syncPending();

      expect(syncCtrl.status, SyncStatus.consentRequired);
      expect(api.syncCalls, 0);
    });

    test('granting cloud consent syncs pending outbox operations and deletes completed entries', () async {
      final syncCtrl = ProfileSyncController(
        database: db,
        store: store,
        api: api,
        session: session,
      );
      await syncCtrl.initialize();

      final prof = StudentProfile(
        programme: 'B.Tech CSE',
        semesterNumber: 4,
        semesterStart: '2026-07-20',
        semesterEnd: '2026-11-30',
        updatedAt: DateTime.now().toUtc(),
      );

      await syncCtrl.enqueueProfileSync(prof);
      expect(syncCtrl.pendingCount, 1);

      // Grant cloud consent -> triggers sync
      await syncCtrl.grantCloudConsent();

      expect(api.syncCalls, 1);
      expect(api.lastSyncedProfile?.programme, 'B.Tech CSE');
      expect(syncCtrl.status, SyncStatus.synced);
      expect(syncCtrl.pendingCount, 0);

      final outboxItems = await db.select(db.localSyncOutbox).get();
      expect(outboxItems, isEmpty);
    });

    test('conflict response marks outbox item as conflict and preserves local draft', () async {
      api.syncFailure = const ProfileFailure(
        ProfileFailureKind.conflict,
        'Your cloud profile changed.',
      );

      final syncCtrl = ProfileSyncController(
        database: db,
        store: store,
        api: api,
        session: session,
      );
      await syncCtrl.initialize();
      await syncCtrl.grantCloudConsent();

      final prof = StudentProfile(
        programme: 'B.Tech CSE',
        semesterNumber: 4,
        semesterStart: '2026-07-20',
        semesterEnd: '2026-11-30',
        updatedAt: DateTime.now().toUtc(),
      );

      await syncCtrl.enqueueProfileSync(prof);

      expect(syncCtrl.status, SyncStatus.conflict);
      expect(syncCtrl.lastError, 'Your cloud profile changed.');

      final outboxItems = await db.select(db.localSyncOutbox).get();
      expect(outboxItems.length, 1);
      expect(outboxItems.first.status, 'conflict');
    });

    test('SessionController deleteAccount calls AuthApi.deleteAccount and cleans up', () async {
      expect(session.account, isNotNull);
      final success = await session.deleteAccount();

      expect(success, isTrue);
      expect(authApi.deleteCalled, isTrue);
      expect(session.account, isNull);
      expect(vault.saved, isNull);
    });
  });
}
