import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'assistant_models.dart';

enum AssistantApiFailureKind {
  unauthorized,
  validation,
  conflict,
  expired,
  unavailable,
  network,
  malformed,
}

class AssistantApiFailure implements Exception {
  const AssistantApiFailure(this.kind, this.message);
  final AssistantApiFailureKind kind;
  final String message;
  @override
  String toString() => message;
}

class AssistantChatResponse {
  const AssistantChatResponse({
    required this.messageId,
    required this.clientMessageId,
    required this.reply,
    this.references = const [],
    this.actionProposal,
  });

  factory AssistantChatResponse.fromJson(Map<String, dynamic> json) {
    ActionProposalModel? proposal;
    if (json['actionProposal'] is Map<String, dynamic>) {
      proposal = ActionProposalModel.fromJson(
        json['actionProposal'] as Map<String, dynamic>,
      );
    }
    return AssistantChatResponse(
      messageId: json['messageId'] as String? ?? '',
      clientMessageId: json['clientMessageId'] as String? ?? '',
      reply: json['reply'] as String? ?? '',
      references: (json['references'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      actionProposal: proposal,
    );
  }

  final String messageId;
  final String clientMessageId;
  final String reply;
  final List<String> references;
  final ActionProposalModel? actionProposal;
}

abstract class AssistantApi {
  Future<AssistantChatResponse> sendMessage({
    required String clientMessageId,
    required String message,
    Map<String, dynamic>? context,
    required String accessToken,
  });

  Future<bool> confirmAction({
    required String actionId,
    required String accessToken,
  });

  Future<bool> sendFeedback({
    required String messageId,
    required bool helpful,
    required String accessToken,
  });
}

class HttpAssistantApi implements AssistantApi {
  HttpAssistantApi({
    required Uri baseApiUrl,
    http.Client Function()? clientFactory,
    Duration timeout = const Duration(seconds: 15),
  })  : _base = _normalize(baseApiUrl),
        _clientFactory = clientFactory ?? http.Client.new,
        _timeout = timeout;

  final Uri _base;
  final http.Client Function() _clientFactory;
  final Duration _timeout;

  static Uri _normalize(Uri url) {
    if ((url.scheme != 'https' &&
            !(url.scheme == 'http' &&
                (url.host == 'localhost' || url.host == '127.0.0.1'))) ||
        url.hasQuery ||
        url.hasFragment ||
        url.userInfo.isNotEmpty ||
        !url.path.replaceFirst(RegExp(r'/$'), '').endsWith('/api/v1')) {
      throw ArgumentError(
        'Use an API URL ending in /api/v1 without credentials, query or fragment.',
      );
    }
    return url.replace(path: '${url.path.replaceFirst(RegExp(r'/$'), '')}/');
  }

  @override
  Future<AssistantChatResponse> sendMessage({
    required String clientMessageId,
    required String message,
    Map<String, dynamic>? context,
    required String accessToken,
  }) async {
    final payload = <String, dynamic>{
      'clientMessageId': clientMessageId,
      'message': message,
    };
    if (context != null) {
      payload['context'] = context;
    }

    final data = await _request(
      'POST',
      'ai/chat',
      accessToken: accessToken,
      body: payload,
    );
    return AssistantChatResponse.fromJson(data);
  }

  @override
  Future<bool> confirmAction({
    required String actionId,
    required String accessToken,
  }) async {
    final data = await _request(
      'POST',
      'ai/actions/$actionId/confirm',
      accessToken: accessToken,
    );
    return data['confirmed'] == true;
  }

  @override
  Future<bool> sendFeedback({
    required String messageId,
    required bool helpful,
    required String accessToken,
  }) async {
    final data = await _request(
      'POST',
      'ai/feedback',
      accessToken: accessToken,
      body: {
        'messageId': messageId,
        'helpful': helpful,
      },
    );
    return data['recorded'] == true;
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    required String accessToken,
  }) async {
    final client = _clientFactory();
    final abort = Completer<void>();
    final timer = Timer(_timeout, () {
      if (!abort.isCompleted) abort.complete();
    });

    try {
      final request = http.AbortableRequest(
        method,
        _base.resolve(path),
        abortTrigger: abort.future,
      )
        ..followRedirects = false
        ..maxRedirects = 0
        ..headers['accept'] = 'application/json'
        ..headers['authorization'] = 'Bearer $accessToken';

      if (body != null) {
        request.headers['content-type'] = 'application/json';
        request.body = jsonEncode(body);
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
        throw const AssistantApiFailure(
          AssistantApiFailureKind.malformed,
          'Invalid JSON envelope.',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = decoded['error'] as Map<String, dynamic>?;
        final message = error?['message'] as String? ?? 'Request failed.';
        final status = response.statusCode;

        if (status == 401) {
          throw AssistantApiFailure(AssistantApiFailureKind.unauthorized, message);
        }
        if (status == 400) {
          throw AssistantApiFailure(AssistantApiFailureKind.validation, message);
        }
        if (status == 409) {
          throw AssistantApiFailure(AssistantApiFailureKind.conflict, message);
        }
        if (status == 410) {
          throw AssistantApiFailure(AssistantApiFailureKind.expired, message);
        }
        if (status == 503) {
          throw AssistantApiFailure(AssistantApiFailureKind.unavailable, message);
        }
        throw AssistantApiFailure(AssistantApiFailureKind.network, message);
      }

      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        throw const AssistantApiFailure(
          AssistantApiFailureKind.malformed,
          'Missing data payload.',
        );
      }
      return data;
    } on AssistantApiFailure {
      rethrow;
    } on TimeoutException {
      throw const AssistantApiFailure(
        AssistantApiFailureKind.network,
        'Assistant request timed out.',
      );
    } catch (e) {
      throw AssistantApiFailure(
        AssistantApiFailureKind.network,
        'Could not reach AI Assistant: $e',
      );
    } finally {
      timer.cancel();
      client.close();
    }
  }
}
