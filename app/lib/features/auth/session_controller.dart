import 'package:flutter/foundation.dart';
import 'auth_api.dart';
import 'auth_models.dart';
import 'google_identity.dart';
import 'session_vault.dart';

enum SessionPhase {
  restoring,
  signedOut,
  ready,
  offline,
  working,
  storageError,
}

class SessionController extends ChangeNotifier {
  SessionController({
    required AuthApi api,
    required SessionVault vault,
    required StudentIdentityProvider identity,
    required Future<void> Function(String accountId) eraseAccountWorkspace,
    DateTime Function()? clock,
  }) : _api = api,
       _vault = vault,
       _identity = identity,
       _eraseAccountWorkspace = eraseAccountWorkspace,
       _clock = clock ?? DateTime.now;
  final AuthApi _api;
  final SessionVault _vault;
  final StudentIdentityProvider _identity;
  final Future<void> Function(String) _eraseAccountWorkspace;
  final DateTime Function() _clock;
  SavedSession? _session;
  SessionPhase _phase = SessionPhase.restoring;
  Future<void>? _rotation;
  bool _busy = false;
  bool _disposed = false;
  String? _message;
  SessionPhase get phase => _phase;
  String? get message => _message;
  bool get busy => _busy;
  StudentAccount? get account =>
      _phase == SessionPhase.storageError ||
          _session?.localAccessAllowed != true
      ? null
      : _session?.account;
  SessionTokens? get tokens =>
      _phase == SessionPhase.storageError ||
          _session?.localAccessAllowed != true
      ? null
      : _session?.tokens;

  void _publish(SessionPhase phase, [String? message]) {
    _phase = phase;
    _message = message;
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    if (_busy) return;
    _busy = true;
    try {
      try {
        _session = await _vault.read();
      } on FormatException {
        await _vault.clear();
        _session = null;
      }
      if (_session == null) {
        _publish(SessionPhase.signedOut);
        return;
      }
      if (!_session!.localAccessAllowed) {
        await _eraseAccountWorkspace(_session!.account.id);
        await _vault.clear();
        _session = null;
        _publish(SessionPhase.signedOut);
        return;
      }
      if (_session!.tokens == null) {
        _publish(
          SessionPhase.offline,
          'Sign in again to reconnect. Your cached account is available only on this device.',
        );
        return;
      }
      await _validate();
    } catch (_) {
      _publish(
        SessionPhase.storageError,
        'Could not open protected sign-in storage. Please retry.',
      );
    } finally {
      _busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> signIn() async {
    if (_busy) return;
    _busy = true;
    _publish(SessionPhase.working);
    try {
      final idToken = await _identity.authenticate();
      if (idToken == null) {
        _publish(
          _session == null ? SessionPhase.signedOut : SessionPhase.offline,
        );
        return;
      }
      final session = await _api.exchange(idToken);
      // Save the new pair atomically before exposing a signed-in state.
      try {
        await _vault.write(session);
      } catch (_) {
        // Do not leave a newly created server session active if secure storage fails.
        try {
          await _api.logout(session.tokens!.accessToken);
        } catch (_) {
          /* Unconfirmed server cleanup; no tokens exposed. */
        }
        _publish(
          SessionPhase.storageError,
          'Could not securely save sign-in. Please retry.',
        );
        return;
      }
      _session = session;
      _publish(SessionPhase.ready);
    } on AuthFailure catch (error) {
      _publish(
        _session == null ? SessionPhase.signedOut : SessionPhase.offline,
        error.message,
      );
    } catch (_) {
      _publish(
        _session == null ? SessionPhase.signedOut : SessionPhase.offline,
        'Sign-in could not be completed. Please retry.',
      );
    } finally {
      _busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> validate() async {
    if (_busy || _session == null) return;
    _busy = true;
    try {
      await _validate();
    } catch (_) {
      _publish(
        SessionPhase.storageError,
        'Could not clear protected local access. Please retry.',
      );
    } finally {
      _busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _validate() async {
    try {
      var tokens = _session?.tokens;
      if (tokens == null) {
        _publish(SessionPhase.offline, 'Sign in again to reconnect.');
        return;
      }
      if (!tokens.expiresAt.isAfter(
        _clock().add(const Duration(seconds: 30)),
      )) {
        await _refresh();
        tokens = _session!.tokens!;
      }
      StudentAccount verified;
      try {
        verified = await _api.me(tokens.accessToken);
      } on AuthFailure catch (error) {
        if (error.kind != AuthFailureKind.unauthorized) rethrow;
        await _refresh();
        verified = await _api.me(_session!.tokens!.accessToken);
      }
      if (verified.id != _session!.account.id) {
        throw const AuthFailure(
          AuthFailureKind.unauthorized,
          'The saved account no longer matches this session.',
        );
      }
      _session = SavedSession(account: verified, tokens: _session!.tokens);
      await _vault.write(_session!);
      _publish(SessionPhase.ready);
    } on AuthFailure catch (error) {
      if (error.kind == AuthFailureKind.unauthorized ||
          error.kind == AuthFailureKind.forbidden) {
        await _clearLocalAccess();
        _publish(SessionPhase.signedOut, error.message);
      } else {
        _publish(SessionPhase.offline, error.message);
      }
    } catch (_) {
      _publish(
        SessionPhase.storageError,
        'Could not update protected sign-in storage. Please retry.',
      );
    }
  }

  Future<void> _refresh() =>
      _rotation ??= _rotate().whenComplete(() => _rotation = null);

  Future<void> _rotate() async {
    final old = _session!;
    final tokens = old.tokens;
    if (tokens == null || !tokens.refreshExpiresAt.isAfter(_clock())) {
      throw const AuthFailure(
        AuthFailureKind.unauthorized,
        'Sign in again to continue.',
      );
    }
    // Durable checkpoint BEFORE sending a single-use refresh token. If the app
    // crashes or the reply is lost, restart must never replay the old token.
    final checkpoint = SavedSession(account: old.account);
    await _vault.write(checkpoint);
    _session = checkpoint;
    final renewed = await _api.refresh(tokens.refreshToken);
    final next = SavedSession(account: old.account, tokens: renewed);
    await _vault.write(next);
    _session = next;
  }

  Future<void> _clearLocalAccess() async {
    final old = _session;
    if (old == null) return;
    final blocked = SavedSession(
      account: old.account,
      localAccessAllowed: false,
    );
    await _vault.write(blocked);
    _session = blocked;
    _publish(SessionPhase.working);
    await _eraseAccountWorkspace(old.account.id);
    await _vault.clear();
    _session = null;
  }

  /// Returns false when remote revocation was not confirmed. Local sign-out
  /// still removes access and its own workspace; it is never a fake server ack.
  Future<bool> signOut() async {
    if (_busy) return false;
    _busy = true;
    final tokens = _session?.tokens;
    _publish(SessionPhase.working);
    var remoteConfirmed = false;
    try {
      // Persist a denied-local-access marker before touching network or caches.
      if (_session != null) {
        final blocked = SavedSession(
          account: _session!.account,
          localAccessAllowed: false,
        );
        await _vault.write(blocked);
        _session = blocked;
      }
      if (tokens != null) {
        try {
          await _api.logout(tokens.accessToken);
          remoteConfirmed = true;
        } catch (_) {
          /* Offline/expired bearer: report unconfirmed remote revoke. */
        }
      }
      await _clearLocalAccess();
      try {
        await _identity.signOut();
      } catch (_) {
        /* App credentials are already erased. */
      }
      _publish(
        SessionPhase.signedOut,
        remoteConfirmed
            ? null
            : 'Signed out on this device. Server revocation could not be confirmed.',
      );
      return remoteConfirmed;
    } catch (_) {
      _publish(
        SessionPhase.storageError,
        'Could not finish clearing protected local access. Please retry sign-out.',
      );
      return false;
    } finally {
      _busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> deleteAccount() async {
    if (_busy) return false;
    _busy = true;
    final tokens = _session?.tokens;
    _publish(SessionPhase.working);
    var remoteConfirmed = false;
    try {
      if (_session != null) {
        final blocked = SavedSession(
          account: _session!.account,
          localAccessAllowed: false,
        );
        await _vault.write(blocked);
        _session = blocked;
      }
      if (tokens != null) {
        try {
          await _api.deleteAccount(tokens.accessToken);
          remoteConfirmed = true;
        } catch (_) {
          /* Server error or offline. */
        }
      }
      await _clearLocalAccess();
      try {
        await _identity.signOut();
      } catch (_) {
        /* App credentials are already erased. */
      }
      _publish(
        SessionPhase.signedOut,
        remoteConfirmed
            ? null
            : 'Local account records erased. Server account deletion could not be confirmed.',
      );
      return remoteConfirmed;
    } catch (_) {
      _publish(
        SessionPhase.storageError,
        'Could not finish account deletion. Please retry.',
      );
      return false;
    } finally {
      _busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
