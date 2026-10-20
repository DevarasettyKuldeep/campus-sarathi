import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_models.dart';

abstract interface class AuthApi {
  Future<SavedSession> exchange(String idToken);
  Future<SessionTokens> refresh(String refreshToken);
  Future<StudentAccount> me(String accessToken);
  Future<void> logout(String accessToken);
  Future<void> deleteAccount(String accessToken);
}

/// Credentials always use HTTPS, including development sign-in. A trusted
/// HTTPS tunnel may reach a local server; redirect following is disabled.
class HttpAuthApi implements AuthApi {
  HttpAuthApi({
    required Uri baseUrl,
    http.Client Function()? clientFactory,
    Duration timeout = const Duration(seconds: 10),
    DateTime Function()? clock,
  }) : _base = validateBase(baseUrl),
       _clientFactory = clientFactory ?? http.Client.new,
       _timeout = timeout,
       _clock = clock ?? DateTime.now;
  final Uri _base;
  final http.Client Function() _clientFactory;
  final Duration _timeout;
  final DateTime Function() _clock;

  static Uri validateBase(Uri url) {
    if (url.scheme != 'https' ||
        url.host.isEmpty ||
        url.userInfo.isNotEmpty ||
        url.hasQuery ||
        url.hasFragment ||
        !url.path.replaceFirst(RegExp(r'/$'), '').endsWith('/api/v1')) {
      throw ArgumentError(
        'Use an HTTPS API URL ending in /api/v1 without credentials, query or fragment.',
      );
    }
    return url.replace(path: '${url.path.replaceFirst(RegExp(r'/$'), '')}/');
  }

  @override
  Future<SavedSession> exchange(String idToken) async {
    final data = await _request(
      'POST',
      'auth/google',
      body: {'idToken': idToken},
    );
    return _parse(
      () => SavedSession(
        account: StudentAccount.fromJson(authObject(data['account'])),
        tokens: SessionTokens.fromResponse(data, _clock()),
      ),
    );
  }

  @override
  Future<SessionTokens> refresh(String refreshToken) async {
    final data = await _request(
      'POST',
      'auth/refresh',
      body: {'refreshToken': refreshToken},
    );
    return _parse(() => SessionTokens.fromResponse(data, _clock()));
  }

  @override
  Future<StudentAccount> me(String accessToken) async {
    final data = await _request('GET', 'users/me', accessToken: accessToken);
    return _parse(() => StudentAccount.fromJson(data));
  }

  @override
  Future<void> logout(String accessToken) async {
    final data = await _request(
      'POST',
      'auth/logout',
      accessToken: accessToken,
    );
    if (data['loggedOut'] != true) {
      throw const AuthFailure(
        AuthFailureKind.malformed,
        'Sign-out could not be confirmed.',
      );
    }
  }

  @override
  Future<void> deleteAccount(String accessToken) async {
    final data = await _request(
      'DELETE',
      'account',
      body: {'confirmation': 'DELETE_MY_ACCOUNT'},
      accessToken: accessToken,
    );
    if (data['deleted'] != true) {
      throw const AuthFailure(
        AuthFailureKind.malformed,
        'Account deletion could not be confirmed.',
      );
    }
  }

  T _parse<T>(T Function() parse) {
    try {
      return parse();
    } on FormatException {
      throw const AuthFailure(
        AuthFailureKind.malformed,
        'The server returned an invalid sign-in response.',
      );
    }
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? accessToken,
  }) async {
    final client = _clientFactory();
    final abort = Completer<void>();
    final timer = Timer(_timeout, () {
      if (!abort.isCompleted) abort.complete();
    });
    try {
      final request =
          http.AbortableRequest(
              method,
              _base.resolve(path),
              abortTrigger: abort.future,
            )
            ..followRedirects = false
            ..maxRedirects = 0
            ..headers['accept'] = 'application/json';
      if (body != null) {
        request.headers['content-type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      if (accessToken != null) {
        request.headers['authorization'] = 'Bearer $accessToken';
      }
      final response = await client.send(request).timeout(_timeout);
      final bytes = await response.stream
          .fold<List<int>>([], (buffer, chunk) {
            if (buffer.length + chunk.length > 65536) {
              throw const FormatException('Oversized response.');
            }
            buffer.addAll(chunk);
            return buffer;
          })
          .timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final status = response.statusCode;
        throw AuthFailure(
          status == 401
              ? AuthFailureKind.unauthorized
              : status == 403
              ? AuthFailureKind.forbidden
              : AuthFailureKind.unavailable,
          status == 401
              ? 'Sign in again to continue.'
              : status == 403
              ? 'Use an eligible university-managed student account.'
              : status == 429
              ? 'Too many attempts. Please wait before retrying.'
              : 'Sign-in is unavailable. Please retry later.',
        );
      }
      return _parse(
        () => authObject(authObject(jsonDecode(utf8.decode(bytes)))['data']),
      );
    } on AuthFailure {
      rethrow;
    } on FormatException {
      throw const AuthFailure(
        AuthFailureKind.malformed,
        'The server returned an invalid sign-in response.',
      );
    } catch (_) {
      throw const AuthFailure(
        AuthFailureKind.network,
        'Could not reach the server. Check your connection.',
      );
    } finally {
      timer.cancel();
      if (!abort.isCompleted) abort.complete();
      client.close();
    }
  }
}
