import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/academic_models.dart';

enum AcademicApiFailureKind {
  unauthorized,
  consentRequired,
  conflict,
  validation,
  unavailable,
  network,
  malformed,
}

class AcademicApiFailure implements Exception {
  const AcademicApiFailure(this.kind, this.message);
  final AcademicApiFailureKind kind;
  final String message;
  @override
  String toString() => message;
}

abstract class AcademicApi {
  Future<Map<String, dynamic>> syncAcademic(
    String accessToken, {
    required String operationId,
    required String consentSequence,
    List<Map<String, dynamic>> subjects = const [],
    List<Map<String, dynamic>> courses = const [],
    List<Map<String, dynamic>> classes = const [],
    List<Map<String, dynamic>> attendance = const [],
    List<Map<String, dynamic>> assignments = const [],
  });

  Future<List<Announcement>> getAnnouncements(String accessToken, {String? scope});
  Future<List<AcademicSubject>> getSubjects(String accessToken);
  Future<AcademicSubject> createSubject(String accessToken, {required String code, required String name});
}

class HttpAcademicApi implements AcademicApi {
  HttpAcademicApi({required Uri baseUrl, http.Client? client})
      : _baseUrl = baseUrl,
        _client = client ?? http.Client();

  final Uri _baseUrl;
  final http.Client _client;

  Uri _endpoint(String path, [Map<String, dynamic>? queryParameters]) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final basePath = _baseUrl.path.endsWith('/') ? _baseUrl.path : '${_baseUrl.path}/';
    return _baseUrl.replace(
      path: '$basePath$cleanPath',
      queryParameters: queryParameters,
    );
  }

  Map<String, String> _headers(String accessToken) => {
        'authorization': 'Bearer $accessToken',
        'content-type': 'application/json',
        'accept': 'application/json',
      };

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
    final uri = _endpoint('sync/academic');
    final payload = {
      'operationId': operationId,
      'consentSequence': consentSequence,
      'subjects': subjects,
      'courses': courses,
      'classes': classes,
      'attendance': attendance,
      'assignments': assignments,
    };

    final response = await _post(uri, accessToken, payload);
    return response as Map<String, dynamic>;
  }

  @override
  Future<List<Announcement>> getAnnouncements(String accessToken, {String? scope}) async {
    final query = scope != null ? {'scope': scope} : null;
    final uri = _endpoint('announcements', query);
    final data = await _get(uri, accessToken);
    if (data is! List) return [];
    return data.map((item) {
      final map = item as Map<String, dynamic>;
      return Announcement(
        id: map['id'] as String,
        scope: map['scope'] as String,
        title: map['title'] as String,
        body: map['body'] as String,
        originUrl: map['originUrl'] as String?,
        publishedAt: DateTime.parse(map['publishedAt'] as String),
      );
    }).toList();
  }

  @override
  Future<List<AcademicSubject>> getSubjects(String accessToken) async {
    final uri = _endpoint('subjects');
    final data = await _get(uri, accessToken);
    if (data is! List) return [];
    return data.map((item) {
      final map = item as Map<String, dynamic>;
      return AcademicSubject(
        id: map['id'] as String,
        code: map['code'] as String,
        name: map['name'] as String,
        revision: map['revision'] as int? ?? 1,
      );
    }).toList();
  }

  @override
  Future<AcademicSubject> createSubject(
    String accessToken, {
    required String code,
    required String name,
  }) async {
    final uri = _endpoint('subjects');
    final data = await _post(uri, accessToken, {'code': code, 'name': name});
    final map = data as Map<String, dynamic>;
    return AcademicSubject(
      id: map['id'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      revision: map['revision'] as int? ?? 1,
    );
  }

  Future<dynamic> _get(Uri uri, String accessToken) async {
    try {
      final res = await _client.get(uri, headers: _headers(accessToken)).timeout(const Duration(seconds: 15));
      return _unwrap(res);
    } on http.ClientException catch (e) {
      throw AcademicApiFailure(AcademicApiFailureKind.network, 'Network connection failed: ${e.message}');
    } on TimeoutException {
      throw const AcademicApiFailure(AcademicApiFailureKind.unavailable, 'Request timed out.');
    }
  }

  Future<dynamic> _post(Uri uri, String accessToken, Map<String, dynamic> body) async {
    try {
      final res = await _client
          .post(uri, headers: _headers(accessToken), body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      return _unwrap(res);
    } on http.ClientException catch (e) {
      throw AcademicApiFailure(AcademicApiFailureKind.network, 'Network connection failed: ${e.message}');
    } on TimeoutException {
      throw const AcademicApiFailure(AcademicApiFailureKind.unavailable, 'Request timed out.');
    }
  }

  dynamic _unwrap(http.Response response) {
    dynamic json;
    try {
      json = jsonDecode(response.body);
    } catch (_) {
      throw AcademicApiFailure(
        AcademicApiFailureKind.malformed,
        'Server returned non-JSON response (${response.statusCode}).',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (json is Map<String, dynamic> && json.containsKey('data')) {
        return json['data'];
      }
      return json;
    }

    String message = 'Request failed.';
    if (json is Map<String, dynamic>) {
      final err = json['error'];
      if (err is Map<String, dynamic> && err['message'] is String) {
        message = err['message'] as String;
      }
    }

    if (response.statusCode == 401) {
      throw AcademicApiFailure(AcademicApiFailureKind.unauthorized, message);
    }
    if (response.statusCode == 403) {
      throw AcademicApiFailure(AcademicApiFailureKind.consentRequired, message);
    }
    if (response.statusCode == 409) {
      throw AcademicApiFailure(AcademicApiFailureKind.conflict, message);
    }
    if (response.statusCode == 400) {
      throw AcademicApiFailure(AcademicApiFailureKind.validation, message);
    }
    if (response.statusCode >= 500) {
      throw AcademicApiFailure(AcademicApiFailureKind.unavailable, message);
    }
    throw AcademicApiFailure(AcademicApiFailureKind.malformed, message);
  }
}
