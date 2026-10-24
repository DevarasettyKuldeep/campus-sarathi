import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:campus_sarathi/features/academic/academic_api.dart';

void main() {
  group('HttpAcademicApi', () {
    test('syncAcademic serializes batch records and returns receipt data', () async {
      late http.Request capturedRequest;
      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'data': {
              'syncedAt': '2026-10-23T12:00:00.000Z',
              'subjectsCount': 1,
              'classesCount': 1,
              'attendanceCount': 1,
              'assignmentsCount': 1,
            },
            'meta': {'requestId': 'req-123'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = HttpAcademicApi(
        baseUrl: Uri.parse('https://api.campussarathi.amrita.edu/api/v1/'),
        client: mockClient,
      );

      final result = await api.syncAcademic(
        'mock-token-xyz',
        operationId: 'op-001',
        consentSequence: '5',
        subjects: [{'code': '23CSE301', 'name': 'Algorithms'}],
        classes: [{'subjectName': 'Algorithms', 'weekday': 1, 'startMinute': 540, 'endMinute': 600, 'room': 'AB1-101'}],
        attendance: [{'subjectKey': 'algorithms', 'subjectName': 'Algorithms', 'attended': 18, 'conducted': 20}],
        assignments: [{'subjectName': 'Algorithms', 'title': 'DP Set 1', 'dueAt': '2026-10-25T18:00:00.000Z'}],
      );

      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.url.path, '/api/v1/sync/academic');
      expect(capturedRequest.headers['authorization'], 'Bearer mock-token-xyz');
      expect(result['subjectsCount'], 1);
      expect(result['classesCount'], 1);
      expect(result['attendanceCount'], 1);
      expect(result['assignmentsCount'], 1);
    });

    test('getAnnouncements parses list of announcements correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/announcements');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 'ann-1',
                'scope': 'public',
                'title': 'Mid-term exams schedule',
                'body': 'Starting November 10th.',
                'originUrl': 'https://amrita.edu/exams',
                'publishedAt': '2026-10-20T10:00:00.000Z',
                'fetchedAt': '2026-10-20T10:00:00.000Z',
              }
            ],
            'meta': {'requestId': 'req-1'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = HttpAcademicApi(
        baseUrl: Uri.parse('https://api.campussarathi.amrita.edu/api/v1/'),
        client: mockClient,
      );

      final list = await api.getAnnouncements('mock-token-xyz');
      expect(list.length, 1);
      expect(list.first.title, 'Mid-term exams schedule');
      expect(list.first.scope, 'public');
    });

    test('maps 403 response to consentRequired failure', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {'code': 'CONSENT_REQUIRED', 'message': 'Academic processing consent is required.'},
            'requestId': 'req-err',
          }),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = HttpAcademicApi(
        baseUrl: Uri.parse('https://api.campussarathi.amrita.edu/api/v1/'),
        client: mockClient,
      );

      expect(
        () => api.getAnnouncements('token'),
        throwsA(isA<AcademicApiFailure>().having((e) => e.kind, 'kind', AcademicApiFailureKind.consentRequired)),
      );
    });

    test('maps 409 response to conflict failure', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {'code': 'SYNC_CONFLICT', 'message': 'Conflict detected.'},
            'requestId': 'req-conflict',
          }),
          409,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = HttpAcademicApi(
        baseUrl: Uri.parse('https://api.campussarathi.amrita.edu/api/v1/'),
        client: mockClient,
      );

      expect(
        () => api.syncAcademic('token', operationId: 'op-1', consentSequence: '1'),
        throwsA(isA<AcademicApiFailure>().having((e) => e.kind, 'kind', AcademicApiFailureKind.conflict)),
      );
    });
  });
}
