import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'auth_api.dart';

class AuthConfiguration {
  AuthConfiguration._(this.baseUrl, this.serverClientId);
  final Uri baseUrl;
  final String serverClientId;
  String get storageNamespace =>
      sha256.convert(utf8.encode(baseUrl.toString())).toString();

  static AuthConfiguration? fromDefines() => fromValues(
    apiUrl: const String.fromEnvironment('API_BASE_URL'),
    serverClientId: const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
  );

  static AuthConfiguration? fromValues({
    required String apiUrl,
    required String serverClientId,
  }) {
    if (apiUrl.isEmpty && serverClientId.isEmpty) return null;
    if (apiUrl.isEmpty ||
        !RegExp(
          r'^[A-Za-z0-9_-]+\.apps\.googleusercontent\.com$',
        ).hasMatch(serverClientId)) {
      throw const FormatException(
        'Configure both the HTTPS API URL and registered Google server client ID.',
      );
    }
    try {
      return AuthConfiguration._(
        HttpAuthApi.validateBase(Uri.parse(apiUrl)),
        serverClientId,
      );
    } catch (_) {
      throw const FormatException(
        'Configure an HTTPS API URL ending in /api/v1.',
      );
    }
  }
}
