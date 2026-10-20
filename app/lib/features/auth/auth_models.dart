enum AuthFailureKind {
  network,
  unauthorized,
  forbidden,
  unavailable,
  malformed,
  storage,
}

class AuthFailure implements Exception {
  const AuthFailure(this.kind, this.message);
  final AuthFailureKind kind;
  final String message;
  @override
  String toString() => message;
}

Map<String, dynamic> authObject(dynamic value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Invalid authentication response.');
  }
  return value;
}

class StudentAccount {
  const StudentAccount({
    required this.id,
    required this.email,
    required this.displayName,
  });
  final String id;
  final String email;
  final String displayName;

  factory StudentAccount.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final email = json['email'];
    final name = json['displayName'];
    if (id is! String ||
        !RegExp(
          r'^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$',
        ).hasMatch(id) ||
        email is! String ||
        !RegExp(r'^[^@\s]+@cb\.students\.amrita\.edu$').hasMatch(email) ||
        name is! String ||
        name.trim().isEmpty ||
        name.length > 200) {
      throw const FormatException('Invalid student account.');
    }
    return StudentAccount(id: id, email: email, displayName: name);
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'displayName': displayName,
  };
}

class SessionTokens {
  const SessionTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.refreshExpiresAt,
  });
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final DateTime refreshExpiresAt;

  factory SessionTokens.fromResponse(Map<String, dynamic> json, DateTime now) {
    final expires = json['expiresIn'];
    if (expires is! int ||
        expires < 1 ||
        expires > 900 ||
        json['tokenType'] != 'Bearer') {
      throw const FormatException('Invalid session expiry.');
    }
    return SessionTokens.fromJson({
      ...json,
      'expiresAt': now
          .add(Duration(seconds: expires))
          .toUtc()
          .toIso8601String(),
    });
  }

  factory SessionTokens.fromJson(Map<String, dynamic> json) {
    final access = json['accessToken'];
    final refresh = json['refreshToken'];
    final expiry = DateTime.tryParse(
      json['expiresAt'] is String ? json['expiresAt'] as String : '',
    );
    final refreshExpiry = DateTime.tryParse(
      json['refreshExpiresAt'] is String
          ? json['refreshExpiresAt'] as String
          : '',
    );
    if (access is! String ||
        access.length > 4096 ||
        !RegExp(
          r'^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$',
        ).hasMatch(access) ||
        refresh is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(refresh) ||
        expiry == null ||
        refreshExpiry == null ||
        expiry.isAfter(refreshExpiry)) {
      throw const FormatException('Invalid saved session.');
    }
    return SessionTokens(
      accessToken: access,
      refreshToken: refresh,
      expiresAt: expiry.toUtc(),
      refreshExpiresAt: refreshExpiry.toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt.toIso8601String(),
    'refreshExpiresAt': refreshExpiresAt.toIso8601String(),
  };
}

class SavedSession {
  const SavedSession({
    required this.account,
    this.tokens,
    this.localAccessAllowed = true,
  });
  final StudentAccount account;
  // Null marks an interrupted/ambiguous refresh. Cached identity may be used
  // for its own offline workspace, but this state grants NO server access.
  final SessionTokens? tokens;
  final bool localAccessAllowed;
  Map<String, dynamic> toJson() => {
    'version': 1,
    'account': account.toJson(),
    'tokens': tokens?.toJson(),
    'localAccessAllowed': localAccessAllowed,
  };
  factory SavedSession.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported saved session.');
    }
    if (json['localAccessAllowed'] != null &&
        json['localAccessAllowed'] is! bool) {
      throw const FormatException('Invalid local access state.');
    }
    return SavedSession(
      account: StudentAccount.fromJson(authObject(json['account'])),
      tokens: json['tokens'] == null
          ? null
          : SessionTokens.fromJson(authObject(json['tokens'])),
      localAccessAllowed: json['localAccessAllowed'] as bool? ?? true,
    );
  }
}
