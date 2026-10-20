import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_models.dart';

abstract interface class SessionVault {
  Future<SavedSession?> read();
  Future<void> write(SavedSession session);
  Future<void> clear();
}

class SecureSessionVault implements SessionVault {
  SecureSessionVault({required Uri server, FlutterSecureStorage? storage})
    : _key =
          'sarathi-session-v1-${base64Url.encode(utf8.encode(server.toString()))}',
      _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  final String _key;
  @override
  Future<SavedSession?> read() async {
    final value = await _storage.read(key: _key);
    if (value == null) return null;
    return SavedSession.fromJson(authObject(jsonDecode(value)));
  }

  @override
  Future<void> write(SavedSession session) =>
      _storage.write(key: _key, value: jsonEncode(session.toJson()));
  @override
  Future<void> clear() => _storage.delete(key: _key);
}
