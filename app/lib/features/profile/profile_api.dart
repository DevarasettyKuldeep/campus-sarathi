import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'student_profile.dart';

enum ProfileFailureKind {
  unauthorized,
  consentRequired,
  conflict,
  validation,
  unavailable,
  network,
  malformed,
}

class ProfileFailure implements Exception {
  const ProfileFailure(this.kind, this.message);
  final ProfileFailureKind kind;
  final String message;
  @override
  String toString() => message;
}

class ServerNotice {
  const ServerNotice({
    required this.version,
    required this.developmentOnly,
    required this.text,
  });
  factory ServerNotice.fromJson(Map<String, dynamic> json) => ServerNotice(
    version: json['version'] as String,
    developmentOnly: json['developmentOnly'] == true,
    text: json['text'] as String,
  );
  final String version;
  final bool developmentOnly;
  final String text;
}

class CloudConsentState {
  const CloudConsentState({
    required this.purpose,
    required this.granted,
    this.sequence,
    this.noticeVersion,
    this.eventAt,
  });
  factory CloudConsentState.fromJson(Map<String, dynamic> json) {
    final event = json['event'] as Map<String, dynamic>?;
    return CloudConsentState(
      purpose: json['purpose'] as String? ?? 'ACADEMIC_PROCESSING',
      granted: json['granted'] == true,
      sequence: event?['sequence'] as String?,
      noticeVersion: event?['noticeVersion'] as String?,
      eventAt: event?['eventAt'] as String?,
    );
  }
  final String purpose;
  final bool granted;
  final String? sequence;
  final String? noticeVersion;
  final String? eventAt;
}

class CloudProfile {
  const CloudProfile({
    required this.programme,
    required this.semesterNumber,
    required this.semesterStart,
    required this.semesterEnd,
    required this.timezone,
    required this.revision,
    required this.updatedAt,
  });
  factory CloudProfile.fromJson(Map<String, dynamic> json) => CloudProfile(
    programme: json['programme'] as String,
    semesterNumber: json['semesterNumber'] as int,
    semesterStart: json['semesterStart'] as String,
    semesterEnd: json['semesterEnd'] as String,
    timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
    revision: json['revision'] as int,
    updatedAt: json['updatedAt'] as String,
  );
  final String programme;
  final int semesterNumber;
  final String semesterStart;
  final String semesterEnd;
  final String timezone;
  final int revision;
  final String updatedAt;

  StudentProfile toLocal() => StudentProfile(
    programme: programme,
    semesterNumber: semesterNumber,
    semesterStart: semesterStart,
    semesterEnd: semesterEnd,
    updatedAt: DateTime.tryParse(updatedAt) ?? DateTime.now().toUtc(),
  );
}

class ProfileSyncResult {
  const ProfileSyncResult({required this.operationId, required this.profile});
  factory ProfileSyncResult.fromJson(Map<String, dynamic> json) =>
      ProfileSyncResult(
        operationId: json['operationId'] as String,
        profile: CloudProfile.fromJson(json['profile'] as Map<String, dynamic>),
      );
  final String operationId;
  final CloudProfile profile;
}

abstract interface class ProfileApi {
  Future<ServerNotice> getNotice();
  Future<CloudConsentState> getConsent(String accessToken);
  Future<CloudConsentState> setConsent(
    String accessToken, {
    required bool granted,
    required String noticeVersion,
    String? expectedSequence,
  });
  Future<CloudProfile?> getProfile(String accessToken);
  Future<ProfileSyncResult> syncProfile(
    String accessToken, {
    required String operationId,
    required String consentSequence,
    required StudentProfile profile,
    required int expectedRevision,
  });
}

class HttpProfileApi implements ProfileApi {
  HttpProfileApi({
    required Uri baseUrl,
    http.Client Function()? clientFactory,
    Duration timeout = const Duration(seconds: 10),
  }) : _base = validateBase(baseUrl),
       _clientFactory = clientFactory ?? http.Client.new,
       _timeout = timeout;

  final Uri _base;
  final http.Client Function() _clientFactory;
  final Duration _timeout;

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
  Future<ServerNotice> getNotice() async {
    final data = await _request('GET', 'privacy/notice');
    return ServerNotice.fromJson(data);
  }

  @override
  Future<CloudConsentState> getConsent(String accessToken) async {
    final data = await _request(
      'GET',
      'privacy/consent',
      accessToken: accessToken,
    );
    return CloudConsentState.fromJson(data);
  }

  @override
  Future<CloudConsentState> setConsent(
    String accessToken, {
    required bool granted,
    required String noticeVersion,
    String? expectedSequence,
  }) async {
    final data = await _request(
      'POST',
      'privacy/consent',
      accessToken: accessToken,
      body: {
        'purpose': 'ACADEMIC_PROCESSING',
        'noticeVersion': noticeVersion,
        'granted': granted,
        'expectedSequence': expectedSequence,
      },
    );
    return CloudConsentState.fromJson(data);
  }

  @override
  Future<CloudProfile?> getProfile(String accessToken) async {
    final data = await _request(
      'GET',
      'users/me/profile',
      accessToken: accessToken,
    );
    if (data.isEmpty || data['programme'] == null) return null;
    return CloudProfile.fromJson(data);
  }

  @override
  Future<ProfileSyncResult> syncProfile(
    String accessToken, {
    required String operationId,
    required String consentSequence,
    required StudentProfile profile,
    required int expectedRevision,
  }) async {
    final data = await _request(
      'POST',
      'sync/profile',
      accessToken: accessToken,
      body: {
        'operationId': operationId,
        'consentSequence': consentSequence,
        'profile': {
          'programme': profile.programme,
          'semesterNumber': profile.semesterNumber,
          'semesterStart': profile.semesterStart,
          'semesterEnd': profile.semesterEnd,
          'timezone': 'Asia/Kolkata',
          'expectedRevision': expectedRevision,
        },
      },
    );
    return ProfileSyncResult.fromJson(data);
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

      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        throw const ProfileFailure(
          ProfileFailureKind.malformed,
          'Invalid JSON envelope.',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = decoded['error'] as Map<String, dynamic>?;
        final message = error?['message'] as String? ?? 'Request failed.';
        final status = response.statusCode;

        if (status == 401) {
          throw ProfileFailure(ProfileFailureKind.unauthorized, message);
        }
        if (status == 403) {
          throw ProfileFailure(ProfileFailureKind.consentRequired, message);
        }
        if (status == 409) {
          throw ProfileFailure(ProfileFailureKind.conflict, message);
        }
        if (status == 400) {
          throw ProfileFailure(ProfileFailureKind.validation, message);
        }
        if (status == 503) {
          throw ProfileFailure(ProfileFailureKind.unavailable, message);
        }
        throw ProfileFailure(ProfileFailureKind.unavailable, message);
      }

      final data = decoded['data'];
      if (data == null) return <String, dynamic>{};
      if (data is Map<String, dynamic>) return data;
      return {'value': data};
    } on ProfileFailure {
      rethrow;
    } on FormatException {
      throw const ProfileFailure(
        ProfileFailureKind.malformed,
        'Invalid response from server.',
      );
    } catch (_) {
      throw const ProfileFailure(
        ProfileFailureKind.network,
        'Could not reach server. Check your connection.',
      );
    } finally {
      timer.cancel();
      if (!abort.isCompleted) abort.complete();
      client.close();
    }
  }
}
