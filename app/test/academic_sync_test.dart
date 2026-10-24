import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_sarathi/data/local/academic_database.dart';
import 'package:campus_sarathi/features/academic/academic_api.dart';
import 'package:campus_sarathi/features/academic/academic_sync_coordinator.dart';
import 'package:campus_sarathi/features/auth/auth_api.dart';
import 'package:campus_sarathi/features/auth/auth_models.dart';
import 'package:campus_sarathi/features/auth/google_identity.dart';
import 'package:campus_sarathi/features/auth/session_controller.dart';
import 'package:campus_sarathi/features/auth/session_vault.dart';
import 'package:campus_sarathi/features/profile/profile_api.dart';
import 'package:campus_sarathi/features/profile/profile_sync_controller.dart';
import 'package:campus_sarathi/features/profile/student_profile.dart';
import 'package:campus_sarathi/main.dart';
import 'package:campus_sarathi/models/academic_models.dart';
import 'package:campus_sarathi/repositories/academic_store.dart';

class MockAcademicApi implements AcademicApi {
  bool syncCalled = false;
  Map<String, dynamic>? lastSyncPayload;
  List<Announcement> announcements = [
    Announcement(
      id: 'ann-1',
      scope: 'public',
      title: 'Lab Examination Notice',
      body: 'Labs start Monday.',
      publishedAt: DateTime.parse('2026-10-22T08:00:00.000Z'),
    ),
  ];

  @override
  Future<Map<String, dynamic>> syncAcademic(
    String accessToken, {
    required String operationId,
    required String consentSequence,
    List<Map<String, dynamic>> subjects = const [],
    List<Map<String, dynamic>> courses = const [],
    List<Map<String, dynamic>> classes = const [],
    List<Map<String, dynamic>> attendance = const [],
    List<Map<String, dynamic>> assignments = const [],
  }) async {
    syncCalled = true;
    lastSyncPayload = {
      'operationId': operationId,
      'consentSequence': consentSequence,
      'assignmentsCount': assignments.length,
      'classesCount': classes.length,
      'attendanceCount': attendance.length,
    };
    return lastSyncPayload!;
  }

  @override
  Future<List<Announcement>> getAnnouncements(String accessToken, {String? scope}) async {
    return announcements;
  }

  @override
  Future<List<AcademicSubject>> getSubjects(String accessToken) async => [];

  @override
  Future<AcademicSubject> createSubject(String accessToken, {required String code, required String name}) async =>
      AcademicSubject(id: 's-1', code: code, name: name);
}

class TestAuthApi implements AuthApi {
  final student = const StudentAccount(
    id: 'test-account-id',
    email: 'test@cb.students.amrita.edu',
    displayName: 'Test Student',
  );

  @override
  Future<SavedSession> exchange(String idToken) async => SavedSession(
        account: student,
        tokens: SessionTokens(
          accessToken: 'test.access.token',
          refreshToken: 'test.refresh.token',
          expiresAt: DateTime.now().add(const Duration(minutes: 15)),
          refreshExpiresAt: DateTime.now().add(const Duration(days: 30)),
        ),
      );

  @override
  Future<StudentAccount> me(String token) async => student;

  @override
  Future<SessionTokens> refresh(String token) async => SessionTokens(
        accessToken: 'test.refreshed.access',
        refreshToken: 'test.refreshed.refresh',
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        refreshExpiresAt: DateTime.now().add(const Duration(days: 30)),
      );

  @override
  Future<void> logout(String token) async {}

  @override
  Future<void> deleteAccount(String token) async {}
}

class TestSessionVault implements SessionVault {
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

class FakeProfileApi implements ProfileApi {
  @override
  Future<ServerNotice> getNotice() async => const ServerNotice(
        version: 'server-academic-dev-1',
        developmentOnly: true,
        text: 'Development notice',
      );
  @override
  Future<CloudConsentState> getConsent(String accessToken) async =>
      const CloudConsentState(purpose: 'ACADEMIC_PROCESSING', granted: true, sequence: '12');
  @override
  Future<CloudConsentState> setConsent(
    String accessToken, {
    required bool granted,
    required String noticeVersion,
    String? expectedSequence,
  }) async =>
      const CloudConsentState(purpose: 'ACADEMIC_PROCESSING', granted: true, sequence: '12');
  @override
  Future<CloudProfile?> getProfile(String accessToken) async => null;
  @override
  Future<ProfileSyncResult> syncProfile(
    String accessToken, {
    required String operationId,
    required String consentSequence,
    required StudentProfile profile,
    required int expectedRevision,
  }) async =>
      ProfileSyncResult(
        operationId: operationId,
        profile: CloudProfile(
          programme: profile.programme,
          semesterNumber: profile.semesterNumber,
          semesterStart: profile.semesterStart,
          semesterEnd: profile.semesterEnd,
          timezone: 'Asia/Kolkata',
          revision: expectedRevision + 1,
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        ),
      );
}

void main() {
  group('AcademicSyncCoordinator and Academic UI', () {
    late AcademicDatabase db;
    late AcademicStore store;
    late SessionController session;
    late MockAcademicApi academicApi;
    late ProfileSyncController profileSync;
    late AcademicSyncCoordinator coordinator;

    setUp(() async {
      db = AcademicDatabase(NativeDatabase.memory());
      store = AcademicStore(database: db);
      await store.initialize();
      await store.grantLocalConsent();

      session = SessionController(
        api: TestAuthApi(),
        vault: TestSessionVault(),
        identity: TestIdentity(),
        eraseAccountWorkspace: (_) async {},
      );

      profileSync = ProfileSyncController(
        database: db,
        store: store,
        api: FakeProfileApi(),
        session: session,
      );

      academicApi = MockAcademicApi();
      coordinator = AcademicSyncCoordinator(
        store: store,
        api: academicApi,
        session: session,
        profileSync: profileSync,
      );
    });

    tearDown(() async {
      session.dispose();
      await store.close();
      await db.close();
    });

    test('AcademicSyncCoordinator updates state and pushes records to mock API', () async {
      // Add local items
      await store.addAssignment(
        title: 'Project Milestone 2',
        subject: 'Software Engineering',
        dueDate: DateTime.now().add(const Duration(days: 2)),
      );

      // Offline without tokens -> idle
      await coordinator.syncNow();
      expect(coordinator.status, SyncStatus.idle);

      // Sign in
      await session.signIn();
      expect(session.account != null, true);

      // Without cloud consent -> consentRequired
      await coordinator.syncNow();
      expect(coordinator.status, SyncStatus.consentRequired);

      // Now fetch cloud consent in profileSync
      await profileSync.fetchServerStatus();

      // Sync again -> synced and announcements populated
      await coordinator.syncNow();
      expect(coordinator.status, SyncStatus.synced);
      expect(academicApi.syncCalled, true);
      expect(store.announcements.length, 1);
      expect(store.announcements.first.title, 'Lab Examination Notice');
    });

    testWidgets('AcademicScreen renders 4 tabs including Announcements and switches tabs',
        (tester) async {
      store.setAnnouncements([
        Announcement(
          id: 'ann-test',
          scope: 'public',
          title: 'Campus Convocation 2026',
          body: 'Registration open until next Friday.',
          publishedAt: DateTime.parse('2026-10-23T09:00:00.000Z'),
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcademicScreen(store: store),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check all 4 tabs exist
      expect(find.text('Assignments'), findsOneWidget);
      expect(find.text('Timetable'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Announcements'), findsOneWidget);

      // Switch to Announcements tab
      await tester.tap(find.text('Announcements'));
      await tester.pumpAndSettle();

      // Announcement card should be visible
      expect(find.text('Campus Convocation 2026'), findsOneWidget);
      expect(find.text('Registration open until next Friday.'), findsOneWidget);
      expect(find.text('PUBLIC'), findsOneWidget);
    });
  });
}
