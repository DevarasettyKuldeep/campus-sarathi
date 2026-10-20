import 'dart:async';
import 'dart:convert';
import 'package:campus_sarathi/features/auth/auth_api.dart';
import 'package:campus_sarathi/features/auth/auth_configuration.dart';
import 'package:campus_sarathi/features/auth/auth_models.dart';
import 'package:campus_sarathi/features/auth/google_identity.dart';
import 'package:campus_sarathi/features/auth/session_controller.dart';
import 'package:campus_sarathi/features/auth/session_vault.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const student = StudentAccount(
  id: '11111111-1111-4111-8111-111111111111',
  email: 'student@cb.students.amrita.edu',
  displayName: 'Student',
);
final now = DateTime.utc(2030, 1, 1);
SessionTokens tokens({bool expired = false, String refresh = 'r'}) =>
    SessionTokens(
      accessToken: 'fixture.header.signature',
      refreshToken: refresh.padRight(43, refresh),
      expiresAt: now.add(Duration(minutes: expired ? -1 : 15)),
      refreshExpiresAt: now.add(const Duration(days: 30)),
    );
Map<String, dynamic> responseTokens() => {
  'accessToken': 'fixture.header.signature',
  'refreshToken': 'r'.padRight(43, 'r'),
  'expiresIn': 900,
  'refreshExpiresAt': now.add(const Duration(days: 30)).toIso8601String(),
  'tokenType': 'Bearer',
};

// Explicit test doubles for state transitions. No fixture identity, memory
// vault or HTTP client replaces a production adapter.
class MemoryVault implements SessionVault {
  SavedSession? saved;
  bool failWrites = false;
  bool malformedRead = false;
  final List<SavedSession> writes = [];
  @override
  Future<SavedSession?> read() async {
    if (malformedRead) throw const FormatException('fixture corrupt entry');
    return saved;
  }

  @override
  Future<void> write(SavedSession session) async {
    if (failWrites) throw StateError('fixture secure storage failure');
    saved = SavedSession.fromJson(session.toJson());
    writes.add(saved!);
  }

  @override
  Future<void> clear() async {
    saved = null;
  }
}

class FixtureIdentity implements StudentIdentityProvider {
  String? idToken = 'fixtureGoogleToken';
  int signOuts = 0;
  @override
  Future<String?> authenticate() async => idToken;
  @override
  Future<void> signOut() async {
    signOuts++;
  }
}

class FixtureApi implements AuthApi {
  int exchanges = 0, refreshes = 0, meCalls = 0, logouts = 0;
  AuthFailure? refreshFailure, meFailure, logoutFailure;
  Future<void> Function()? beforeRefresh;
  StudentAccount returnedAccount = student;
  @override
  Future<SavedSession> exchange(String idToken) async {
    exchanges++;
    return SavedSession(account: student, tokens: tokens());
  }

  @override
  Future<SessionTokens> refresh(String refreshToken) async {
    refreshes++;
    await beforeRefresh?.call();
    if (refreshFailure != null) throw refreshFailure!;
    return tokens(refresh: 'n');
  }

  @override
  Future<StudentAccount> me(String accessToken) async {
    meCalls++;
    if (meFailure != null) throw meFailure!;
    return returnedAccount;
  }

  @override
  Future<void> logout(String accessToken) async {
    logouts++;
    if (logoutFailure != null) throw logoutFailure!;
  }

  int deleteAccountCalls = 0;
  AuthFailure? deleteAccountFailure;
  @override
  Future<void> deleteAccount(String accessToken) async {
    deleteAccountCalls++;
    if (deleteAccountFailure != null) throw deleteAccountFailure!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'configuration rejects partial settings and isolates canonical server namespaces',
    () {
      expect(
        AuthConfiguration.fromValues(apiUrl: '', serverClientId: ''),
        isNull,
      );
      expect(
        () => AuthConfiguration.fromValues(
          apiUrl: 'https://example.com/api/v1',
          serverClientId: '',
        ),
        throwsFormatException,
      );
      final first = AuthConfiguration.fromValues(
        apiUrl: 'https://example.com/api/v1',
        serverClientId: '123-fixture.apps.googleusercontent.com',
      )!;
      final same = AuthConfiguration.fromValues(
        apiUrl: 'https://example.com/api/v1/',
        serverClientId: '123-fixture.apps.googleusercontent.com',
      )!;
      final other = AuthConfiguration.fromValues(
        apiUrl: 'https://staging.example.com/api/v1',
        serverClientId: '123-fixture.apps.googleusercontent.com',
      )!;
      expect(first.storageNamespace, same.storageNamespace);
      expect(first.storageNamespace, isNot(other.storageNamespace));
    },
  );

  test(
    'HTTPS transport posts only the ID token and refuses insecure/credential URLs',
    () async {
      for (final url in [
        'http://localhost/api/v1',
        'https://user:secret@example.com/api/v1',
        'https://example.com/api/v1?key=secret',
        'https://example.com/other',
      ]) {
        expect(() => HttpAuthApi(baseUrl: Uri.parse(url)), throwsArgumentError);
      }
      final api = HttpAuthApi(
        baseUrl: Uri.parse('https://example.com/api/v1'),
        clock: () => now,
        clientFactory: () => MockClient((request) async {
          expect(request.url.path, '/api/v1/auth/google');
          expect(request.followRedirects, isFalse);
          expect(jsonDecode(request.body), {'idToken': 'fixture-token'});
          expect(request.headers['authorization'], isNull);
          return http.Response(
            jsonEncode({
              'data': {...responseTokens(), 'account': student.toJson()},
            }),
            200,
          );
        }),
      );
      final login = await api.exchange('fixture-token');
      expect(login.account.id, student.id);
      expect(login.tokens!.expiresAt, now.add(const Duration(minutes: 15)));
    },
  );

  test(
    'HTTP authorization uses the bearer header and cannot follow redirects',
    () async {
      var requests = 0;
      final api = HttpAuthApi(
        baseUrl: Uri.parse('https://example.com/api/v1/'),
        clientFactory: () => MockClient((request) async {
          requests++;
          expect(request.headers['authorization'], 'Bearer fixture-token');
          expect(request.url.query, isEmpty);
          expect(request.followRedirects, isFalse);
          return http.Response(
            'private upstream details',
            302,
            headers: {'location': 'https://attacker.example/'},
          );
        }),
      );
      await expectLater(api.me('fixture-token'), throwsA(isA<AuthFailure>()));
      expect(requests, 1);
    },
  );

  test(
    'malformed and oversized authentication responses do not echo secret data',
    () async {
      for (final body in [
        'private-token-not-json',
        jsonEncode({
          'data': {'accessToken': 'private-token'},
        }),
        'x'.padRight(70000, 'x'),
      ]) {
        final api = HttpAuthApi(
          baseUrl: Uri.parse('https://example.com/api/v1'),
          clientFactory: () =>
              MockClient((_) async => http.Response(body, 200)),
        );
        await expectLater(
          api.exchange('fixture'),
          throwsA(
            isA<AuthFailure>().having(
              (error) => error.toString().contains('private-token'),
              'redacted response',
              isFalse,
            ),
          ),
        );
      }
    },
  );

  test('HTTP timeout does not automatically replay a refresh', () async {
    var requests = 0;
    final api = HttpAuthApi(
      baseUrl: Uri.parse('https://example.com/api/v1'),
      timeout: const Duration(milliseconds: 5),
      clientFactory: () => MockClient((_) async {
        requests++;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return http.Response(jsonEncode({'data': responseTokens()}), 200);
      }),
    );
    await expectLater(
      api.refresh('r'.padRight(43, 'r')),
      throwsA(isA<AuthFailure>()),
    );
    await Future<void>.delayed(const Duration(milliseconds: 35));
    expect(requests, 1);
  });

  test(
    'secure-storage adapter namespaces servers and round-trips a single session envelope',
    () async {
      // Plugin mock verifies wrapper behaviour, NOT Android Keystore encryption.
      FlutterSecureStorage.setMockInitialValues({});
      final first = SecureSessionVault(
        server: Uri.parse('https://first.example/api/v1'),
      );
      final second = SecureSessionVault(
        server: Uri.parse('https://second.example/api/v1'),
      );
      await first.write(SavedSession(account: student, tokens: tokens()));
      expect((await first.read())!.account.id, student.id);
      expect(await second.read(), isNull);
      await first.clear();
      expect(await first.read(), isNull);
    },
  );

  test(
    'sign-in persists before ready; cancellation creates no backend session',
    () async {
      final vault = MemoryVault();
      final api = FixtureApi();
      final identity = FixtureIdentity();
      final controller = SessionController(
        api: api,
        vault: vault,
        identity: identity,
        clock: () => now,
        eraseAccountWorkspace: (_) async {},
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      identity.idToken = null;
      await controller.signIn();
      expect(api.exchanges, 0);
      expect(controller.phase, SessionPhase.signedOut);
      identity.idToken = 'fixture';
      var lastBusy = true;
      controller.addListener(() => lastBusy = controller.busy);
      await controller.signIn();
      expect(vault.saved!.tokens, isNotNull);
      expect(controller.phase, SessionPhase.ready);
      expect(lastBusy, isFalse);
    },
  );

  test(
    'secure-store failure never publishes a signed-in state and attempts server cleanup',
    () async {
      final vault = MemoryVault()..failWrites = true;
      final api = FixtureApi();
      final controller = SessionController(
        api: api,
        vault: vault,
        identity: FixtureIdentity(),
        clock: () => now,
        eraseAccountWorkspace: (_) async {},
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.signIn();
      expect(controller.phase, SessionPhase.storageError);
      expect(controller.account, isNull);
      expect(api.logouts, 1);
      expect(vault.saved, isNull);
    },
  );

  test(
    'ambiguous refresh persists a token-free checkpoint and restart cannot replay it',
    () async {
      final vault = MemoryVault()
        ..saved = SavedSession(account: student, tokens: tokens(expired: true));
      final api = FixtureApi()
        ..refreshFailure = const AuthFailure(
          AuthFailureKind.network,
          'fixture offline',
        );
      api.beforeRefresh = () async {
        expect(vault.saved!.tokens, isNull);
      };
      final controller = SessionController(
        api: api,
        vault: vault,
        identity: FixtureIdentity(),
        clock: () => now,
        eraseAccountWorkspace: (_) async {},
      );
      await controller.initialize();
      expect(controller.phase, SessionPhase.offline);
      expect(controller.account!.id, student.id);
      expect(vault.saved!.tokens, isNull);
      controller.dispose();
      final restarted = SessionController(
        api: api,
        vault: vault,
        identity: FixtureIdentity(),
        clock: () => now,
        eraseAccountWorkspace: (_) async {},
      );
      addTearDown(restarted.dispose);
      await restarted.initialize();
      expect(api.refreshes, 1);
      expect(api.meCalls, 0);
      expect(restarted.phase, SessionPhase.offline);
    },
  );

  test(
    'parallel validation refreshes once and publishes the new pair together',
    () async {
      final vault = MemoryVault()
        ..saved = SavedSession(account: student, tokens: tokens());
      final api = FixtureApi();
      final barrier = Completer<void>();
      final controller = SessionController(
        api: api,
        vault: vault,
        identity: FixtureIdentity(),
        clock: () => now,
        eraseAccountWorkspace: (_) async {},
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      // Force an expired persisted pair, then restore while another call arrives.
      vault.saved = SavedSession(
        account: student,
        tokens: tokens(expired: true),
      );
      api.beforeRefresh = () => barrier.future;
      final first = controller.initialize();
      await Future<void>.delayed(Duration.zero);
      final second = controller.validate();
      barrier.complete();
      await Future.wait([first, second]);
      expect(api.refreshes, 1);
      expect(vault.saved!.tokens!.refreshToken, 'n'.padRight(43, 'n'));
      expect(controller.phase, SessionPhase.ready);
    },
  );

  test(
    'revoked refresh clears only its own account workspace and denies offline access',
    () async {
      final vault = MemoryVault()
        ..saved = SavedSession(account: student, tokens: tokens(expired: true));
      final api = FixtureApi()
        ..refreshFailure = const AuthFailure(
          AuthFailureKind.unauthorized,
          'Sign in again.',
        );
      final erased = <String>[];
      final controller = SessionController(
        api: api,
        vault: vault,
        identity: FixtureIdentity(),
        clock: () => now,
        eraseAccountWorkspace: (id) async {
          erased.add(id);
        },
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      expect(erased, [student.id]);
      expect(vault.saved, isNull);
      expect(controller.phase, SessionPhase.signedOut);
    },
  );

  test(
    'logout reports unconfirmed server revoke while erasing local credentials and workspace',
    () async {
      final vault = MemoryVault()
        ..saved = SavedSession(account: student, tokens: tokens());
      final api = FixtureApi()
        ..logoutFailure = const AuthFailure(
          AuthFailureKind.network,
          'fixture offline',
        );
      final erased = <String>[];
      final controller = SessionController(
        api: api,
        vault: vault,
        identity: FixtureIdentity(),
        clock: () => now,
        eraseAccountWorkspace: (id) async {
          erased.add(id);
        },
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      expect(await controller.signOut(), isFalse);
      expect(vault.saved, isNull);
      expect(erased, [student.id]);
      expect(controller.phase, SessionPhase.signedOut);
      expect(controller.message, contains('could not be confirmed'));
    },
  );

  test(
    'interrupted local erasure leaves a denied-access marker for cleanup at restart',
    () async {
      final vault = MemoryVault()
        ..saved = SavedSession(account: student, tokens: tokens());
      final api = FixtureApi();
      final controller = SessionController(
        api: api,
        vault: vault,
        identity: FixtureIdentity(),
        clock: () => now,
        eraseAccountWorkspace: (_) async {
          throw StateError('fixture disk failure');
        },
      );
      await controller.initialize();
      await controller.signOut();
      expect(vault.saved!.localAccessAllowed, isFalse);
      expect(controller.account, isNull);
      controller.dispose();
      final erased = <String>[];
      final restarted = SessionController(
        api: api,
        vault: vault,
        identity: FixtureIdentity(),
        clock: () => now,
        eraseAccountWorkspace: (id) async {
          erased.add(id);
        },
      );
      addTearDown(restarted.dispose);
      await restarted.initialize();
      expect(erased, [student.id]);
      expect(vault.saved, isNull);
      expect(restarted.phase, SessionPhase.signedOut);
    },
  );
}
