import 'dart:async';
import 'dart:io';
import 'package:campus_sarathi/data/local/academic_database.dart';
import 'package:campus_sarathi/features/auth/account_workspaces.dart';
import 'package:campus_sarathi/features/auth/auth_api.dart';
import 'package:campus_sarathi/features/auth/auth_models.dart';
import 'package:campus_sarathi/features/auth/google_identity.dart';
import 'package:campus_sarathi/features/auth/session_controller.dart';
import 'package:campus_sarathi/features/auth/session_gate.dart';
import 'package:campus_sarathi/features/auth/session_vault.dart';
import 'package:campus_sarathi/features/profile/student_profile.dart';
import 'package:campus_sarathi/main.dart';
import 'package:campus_sarathi/repositories/academic_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const firstAccount = StudentAccount(
  id: '11111111-1111-4111-8111-111111111111',
  email: 'first@cb.students.amrita.edu',
  displayName: 'First student',
);
const secondAccount = StudentAccount(
  id: '22222222-2222-4222-8222-222222222222',
  email: 'second@cb.students.amrita.edu',
  displayName: 'Second student',
);

class GateVault implements SessionVault {
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

class GateIdentity implements StudentIdentityProvider {
  @override
  Future<String?> authenticate() async => 'explicit-widget-fixture';
  @override
  Future<void> signOut() async {}
}

// Widget fixtures only. File-backed workspace tests below exercise actual
// SQLite independently; these fixtures do not establish live OAuth/backend.
class GateApi implements AuthApi {
  StudentAccount nextAccount = firstAccount;
  bool revoked = false;
  @override
  Future<SavedSession> exchange(String idToken) async => SavedSession(
    account: nextAccount,
    tokens: SessionTokens(
      accessToken: 'a.b.c',
      refreshToken: 'r'.padRight(43, 'r'),
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      refreshExpiresAt: DateTime.now().add(const Duration(days: 30)),
    ),
  );
  @override
  Future<StudentAccount> me(String token) async {
    if (revoked) {
      throw const AuthFailure(AuthFailureKind.unauthorized, 'Session revoked.');
    }
    return nextAccount;
  }

  @override
  Future<SessionTokens> refresh(String token) async =>
      throw const AuthFailure(AuthFailureKind.unauthorized, 'Sign in again.');
  @override
  Future<void> logout(String token) async {}
  @override
  Future<void> deleteAccount(String token) async {}
}

class DelayedStore extends AcademicStore {
  DelayedStore(this.barrier)
    : super(database: AcademicDatabase(NativeDatabase.memory()));
  final Future<void> barrier;
  @override
  Future<void> initialize() async {
    await barrier;
    await super.initialize();
  }
}

Widget gateApp(SessionController controller, AccountWorkspaces workspaces) =>
    MaterialApp(
      home: SessionGate(
        controller: controller,
        workspaces: workspaces,
        homeBuilder: (context, store, account, session) => CampusHome(
          key: ValueKey(account.id),
          store: store,
          session: session,
        ),
      ),
    );

Future<void> signInAndConsent(WidgetTester tester) async {
  await tester.tap(find.text('Continue with student Google account'));
  await tester.pumpAndSettle();
  expect(
    tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
    isFalse,
  );
  await tester.tap(find.byType(CheckboxListTile));
  await tester.pump();
  await tester.tap(find.text('Continue with local records'));
  await tester.pumpAndSettle();
}

void main() {
  test(
    'workspace switching waits for writes; erasure affects only its active account',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'sarathi-workspace-lifecycle-',
      );
      final namespace = 'a'.padRight(64, 'a');
      final workspaces = AccountWorkspaces(
        createStore: (id) => AcademicStore(
          database: AcademicDatabase(
            NativeDatabase(
              AcademicDatabase.accountFile(directory, id, namespace),
            ),
          ),
        ),
      );
      try {
        final first = await workspaces.open(firstAccount.id);
        await first.grantLocalConsent();
        await first.saveProfile(
          StudentProfile(
            programme: 'First private programme',
            semesterNumber: 3,
            semesterStart: '2026-07-20',
            semesterEnd: '2026-12-10',
            updatedAt: DateTime.now().toUtc(),
          ),
        );
        final pendingSave = first.addAssignment(
          title: 'Write before switching',
          subject: 'Networks',
          dueDate: DateTime(2030),
        );
        final switching = workspaces.open(secondAccount.id);
        await pendingSave;
        final second = await switching;
        expect(
          first.assignments,
          isEmpty,
          reason: 'Closed account references must not retain exposed records.',
        );
        await expectLater(
          first.addAssignment(
            title: 'Late write',
            subject: 'Networks',
            dueDate: DateTime(2030),
          ),
          throwsStateError,
        );
        expect(second.assignments, isEmpty);
        expect(first.profile, isNull);
        expect(second.profile, isNull);
        expect(second.hasConsent, isFalse);
        await second.grantLocalConsent();
        await second.addAssignment(
          title: 'Second private task',
          subject: 'Networks',
          dueDate: DateTime(2030),
        );
        await expectLater(workspaces.erase(firstAccount.id), throwsStateError);
        expect(second.assignments.single.title, 'Second private task');
        await workspaces.erase(secondAccount.id);
        final restoredFirst = await workspaces.open(firstAccount.id);
        expect(restoredFirst.profile!.programme, 'First private programme');
        expect(
          restoredFirst.assignments.single.title,
          'Write before switching',
        );
        await workspaces.erase(firstAccount.id);
        final erased = await workspaces.open(firstAccount.id);
        expect(erased.hasConsent, isFalse);
        expect(erased.profile, isNull);
        await erased.grantLocalConsent();
        expect(erased.assignments, isEmpty);
      } finally {
        await workspaces.close();
        await directory.delete(recursive: true);
      }
    },
  );

  testWidgets(
    'release authentication guard cannot fall back to an injected local workspace',
    (tester) async {
      final store = AcademicStore(
        database: AcademicDatabase(NativeDatabase.memory()),
      );
      await store.initialize();
      await store.grantLocalConsent();
      addTearDown(() async {
        await store.close();
        store.dispose();
      });
      await tester.pumpWidget(
        CampusSarathiApp(store: store, requireAuthentication: true),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Sign-in is not configured'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(CheckboxListTile), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'sign-in, per-account consent, academic entry and confirmed logout form a working journey',
    (tester) async {
      final api = GateApi();
      final vault = GateVault();
      final workspaces = AccountWorkspaces(
        createStore: (_) =>
            AcademicStore(database: AcademicDatabase(NativeDatabase.memory())),
      );
      final controller = SessionController(
        api: api,
        vault: vault,
        identity: GateIdentity(),
        eraseAccountWorkspace: workspaces.erase,
      );
      addTearDown(() async {
        controller.dispose();
        final closing = workspaces.close();
        await tester.pumpAndSettle();
        await closing;
      });
      await tester.pumpWidget(gateApp(controller, workspaces));
      await tester.pumpAndSettle();

      await tester.tap(find.text('How sign-in data is used'));
      await tester.pumpAndSettle();
      expect(find.text('Sign-in privacy notice'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await signInAndConsent(tester);

      await tester.tap(find.text('Academic'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Assignment'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Networks');
      await tester.enterText(fields.at(1), 'Private assignment');
      await tester.tap(find.text('Save record'));
      await tester.pumpAndSettle();

      expect(find.text('Private assignment'), findsOneWidget);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.textContaining(firstAccount.email), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Sign out'), 100);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep account open'));
      await tester.pumpAndSettle();
      expect(controller.account!.id, firstAccount.id);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Sign out'),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.account, isNull);

      expect(vault.saved, isNull);
      expect(find.text('Continue with student Google account'), findsOneWidget);
      expect(find.text('Private assignment'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'academic consent can be declined without granting it or opening private screens',
    (tester) async {
      final vault = GateVault();
      final stores = <AcademicStore>[];
      final workspaces = AccountWorkspaces(
        createStore: (_) {
          final store = AcademicStore(
            database: AcademicDatabase(NativeDatabase.memory()),
          );
          stores.add(store);
          return store;
        },
      );
      final controller = SessionController(
        api: GateApi(),
        vault: vault,
        identity: GateIdentity(),
        eraseAccountWorkspace: workspaces.erase,
      );
      addTearDown(() async {
        controller.dispose();
        final closing = workspaces.close();
        await tester.pumpAndSettle();
        await closing;
      });
      await tester.pumpWidget(gateApp(controller, workspaces));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue with student Google account'));
      await tester.pumpAndSettle();
      expect(stores.single.hasConsent, isFalse);
      expect(find.byType(NavigationBar), findsNothing);
      await tester.tap(find.text('Decline and sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep reviewing'));
      await tester.pumpAndSettle();
      expect(controller.account, isNotNull);
      expect(stores.single.hasConsent, isFalse);
      await tester.tap(find.text('Decline and sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out and erase local records'));
      await tester.pumpAndSettle();
      expect(controller.account, isNull);
      expect(vault.saved, isNull);
      expect(stores.every((store) => !store.hasConsent), isTrue);
      expect(find.text('Continue with student Google account'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'revoked session closes an open academic editor instead of leaving private routes visible',
    (tester) async {
      final api = GateApi();
      final workspaces = AccountWorkspaces(
        createStore: (_) =>
            AcademicStore(database: AcademicDatabase(NativeDatabase.memory())),
      );
      final controller = SessionController(
        api: api,
        vault: GateVault(),
        identity: GateIdentity(),
        eraseAccountWorkspace: workspaces.erase,
      );
      addTearDown(() async {
        controller.dispose();
        final closing = workspaces.close();
        await tester.pumpAndSettle();
        await closing;
      });
      await tester.pumpWidget(gateApp(controller, workspaces));
      await tester.pumpAndSettle();
      await signInAndConsent(tester);
      await tester.tap(find.text('Academic'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Assignment'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Unsaved private text',
      );
      api.revoked = true;
      await controller.validate();
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Unsaved private text'), findsNothing);
      expect(find.text('Continue with student Google account'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'revocation removes an unsaved profile editor without a discard dialog blocking cleanup',
    (tester) async {
      final api = GateApi();
      final workspaces = AccountWorkspaces(
        createStore: (_) =>
            AcademicStore(database: AcademicDatabase(NativeDatabase.memory())),
      );
      final controller = SessionController(
        api: api,
        vault: GateVault(),
        identity: GateIdentity(),
        eraseAccountWorkspace: workspaces.erase,
      );
      addTearDown(() async {
        controller.dispose();
        final closing = workspaces.close();
        await tester.pumpAndSettle();
        await closing;
      });
      await tester.pumpWidget(gateApp(controller, workspaces));
      await tester.pumpAndSettle();
      await signInAndConsent(tester);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Add semester profile'));
      await tester.tap(find.text('Add semester profile'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Private profile draft',
      );
      api.revoked = true;
      await controller.validate();
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Discard profile changes?'), findsNothing);
      expect(find.text('Continue with student Google account'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'slow account switch cannot render the previous account snapshot or consent',
    (tester) async {
      final barrier = Completer<void>();
      final api = GateApi();
      final workspaces = AccountWorkspaces(
        createStore: (id) => id == secondAccount.id
            ? DelayedStore(barrier.future)
            : AcademicStore(
                database: AcademicDatabase(NativeDatabase.memory()),
              ),
      );
      final controller = SessionController(
        api: api,
        vault: GateVault(),
        identity: GateIdentity(),
        eraseAccountWorkspace: workspaces.erase,
      );
      addTearDown(() async {
        if (!barrier.isCompleted) barrier.complete();
        controller.dispose();
        final closing = workspaces.close();
        await tester.pumpAndSettle();
        await closing;
      });
      await tester.pumpWidget(gateApp(controller, workspaces));
      await tester.pumpAndSettle();
      await signInAndConsent(tester);
      final first = await workspaces.open(firstAccount.id);
      await first.addAssignment(
        title: 'First account secret',
        subject: 'Networks',
        dueDate: DateTime(2030),
      );
      await tester.pumpAndSettle();
      expect(find.text('First account secret'), findsOneWidget);
      api.nextAccount = secondAccount;
      await controller.signIn();
      await tester.pump();
      expect(find.text('First account secret'), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      barrier.complete();
      await tester.pumpAndSettle();
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isFalse,
      );
      expect(find.text('First account secret'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
