import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/academic_models.dart';
import '../../repositories/academic_store.dart';
import '../auth/session_controller.dart';
import 'assistant_models.dart';
import 'assistant_api.dart';
import 'local_assistant_engine.dart';

class AssistantController extends ChangeNotifier {
  AssistantController({
    required AcademicStore store,
    SessionController? session,
    AssistantApi? api,
    LocalAssistantEngine? localEngine,
  })  : _store = store,
        _session = session,
        _api = api,
        _localEngine = localEngine ?? LocalAssistantEngine() {
    _initWelcome();
  }

  final AcademicStore _store;
  final SessionController? _session;
  final AssistantApi? _api;
  final LocalAssistantEngine _localEngine;
  static const _uuid = Uuid();

  final List<AssistantMessage> _messages = [];
  bool _isProcessing = false;
  String? _errorMessage;

  List<AssistantMessage> get messages => List.unmodifiable(_messages);
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;

  bool get isOnlineMode =>
      _session != null &&
      _session.phase == SessionPhase.ready &&
      _session.tokens?.accessToken != null &&
      _api != null;

  void _initWelcome() {
    _messages.add(
      AssistantMessage(
        id: _uuid.v4(),
        isUser: false,
        text:
            'Hello! I am Campus Sārathi, your academic companion. I can help you plan your day, analyze your attendance risk, and prioritize coursework.\n\nWhat would you like to check?',
        timestamp: DateTime.now(),
        references: const [],
      ),
    );
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isProcessing) return;

    final clientMessageId = _uuid.v4();
    final userMsg = AssistantMessage(
      id: clientMessageId,
      isUser: true,
      text: trimmed,
      timestamp: DateTime.now(),
    );

    _messages.add(userMsg);
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isOnlineMode) {
        final token = _session!.tokens!.accessToken;
        final context = _buildAcademicContext();
        try {
          final res = await _api!.sendMessage(
            clientMessageId: clientMessageId,
            message: trimmed,
            context: context,
            accessToken: token,
          );

          _messages.add(
            AssistantMessage(
              id: res.messageId.isNotEmpty ? res.messageId : _uuid.v4(),
              isUser: false,
              text: res.reply,
              timestamp: DateTime.now(),
              references: res.references,
              actionProposal: res.actionProposal,
              isOfflineFallback: false,
            ),
          );
        } catch (_) {
          // Fallback to deterministic local engine when cloud call fails
          final localRes = _localEngine.generateResponse(
            trimmed,
            _store,
            clientMessageId: clientMessageId,
          );
          _messages.add(
            AssistantMessage(
              id: localRes.messageId,
              isUser: false,
              text: '${localRes.reply}\n\n*(Cloud unavailable · Answered using on-device records)*',
              timestamp: DateTime.now(),
              references: localRes.references,
              actionProposal: localRes.actionProposal,
              isOfflineFallback: true,
            ),
          );
        }
      } else {
        // Pure offline mode
        final localRes = _localEngine.generateResponse(
          trimmed,
          _store,
          clientMessageId: clientMessageId,
        );
        _messages.add(
          AssistantMessage(
            id: localRes.messageId,
            isUser: false,
            text: localRes.reply,
            timestamp: DateTime.now(),
            references: localRes.references,
            actionProposal: localRes.actionProposal,
            isOfflineFallback: true,
          ),
        );
      }
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> confirmAction(String messageId) async {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    final msg = _messages[idx];
    final proposal = msg.actionProposal;
    if (proposal == null || proposal.isConfirmed || proposal.isDismissed) return;

    if (proposal.isExpired) {
      _errorMessage = 'Action proposal has expired.';
      notifyListeners();
      return;
    }

    _isProcessing = true;
    notifyListeners();

    try {
      if (isOnlineMode) {
        final token = _session!.tokens!.accessToken;
        try {
          await _api!.confirmAction(actionId: proposal.id, accessToken: token);
        } catch (_) {
          // Continue to apply locally even if network fails
        }
      }

      // Apply action to store
      if (proposal.actionType == 'schedule_study') {
        final subject = proposal.payload['subject'] as String? ?? 'Study Session';
        final duration = proposal.payload['durationMinutes'] as int? ?? 60;
        await _store.addAssignment(
          title: 'Study Block: $subject (${duration}m)',
          subject: subject,
          dueDate: DateTime.now().add(const Duration(hours: 4)),
        );
      } else if (proposal.actionType == 'add_assignment') {
        final title = proposal.payload['title'] as String? ?? 'New Assignment';
        final subject = proposal.payload['subject'] as String? ?? 'General';
        final dueDateStr = proposal.payload['dueAt'] as String?;
        final dueDate = (dueDateStr != null ? DateTime.tryParse(dueDateStr) : null) ??
            DateTime.now().add(const Duration(days: 3));
        await _store.addAssignment(
          title: title,
          subject: subject,
          dueDate: dueDate,
        );
      }

      proposal.isConfirmed = true;
      _messages.add(
        AssistantMessage(
          id: _uuid.v4(),
          isUser: false,
          text: '✓ Confirmed! "${proposal.title}" has been scheduled in your academic records.',
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      _errorMessage = 'Could not apply action: $e';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void dismissAction(String messageId) {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    final proposal = _messages[idx].actionProposal;
    if (proposal != null) {
      proposal.isDismissed = true;
      notifyListeners();
    }
  }

  Future<void> rateMessage(String messageId, FeedbackRating rating) async {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    final msg = _messages[idx];
    msg.feedback = rating;
    notifyListeners();

    if (isOnlineMode) {
      final token = _session!.tokens?.accessToken;
      if (token != null) {
        try {
          await _api!.sendFeedback(
            messageId: messageId,
            helpful: rating == FeedbackRating.helpful,
            accessToken: token,
          );
        } catch (_) {
          // Non-fatal
        }
      }
    }
  }

  void clearChat() {
    _messages.clear();
    _errorMessage = null;
    _initWelcome();
    notifyListeners();
  }

  Map<String, dynamic> _buildAcademicContext() {
    return {
      if (_store.profile?.programme != null)
        'programme': _store.profile!.programme,
      if (_store.profile?.semesterNumber != null)
        'semesterNumber': _store.profile!.semesterNumber,
      'assignments': _store.assignments
          .map((a) => {
                'id': a.id,
                'title': a.title,
                'subject': a.subject,
                'dueAt': a.dueDate.toIso8601String(),
                'complete': a.status == AssignmentStatus.complete,
              })
          .toList(),
      'classes': _store.classes
          .map((c) => {
                'id': c.id,
                'subject': c.subject,
                'weekday': c.day,
                'startMinute': c.startTime.hour * 60 + c.startTime.minute,
                'endMinute': c.endTime.hour * 60 + c.endTime.minute,
                'room': c.room,
              })
          .toList(),
      'attendance': _store.attendance
          .map((att) => {
                'subject': att.subject,
                'attended': att.attended,
                'conducted': att.total,
                if (att.percentage != null) 'percentage': att.percentage,
                if (att.minimumPercentage != null)
                  'minimumPercentage': att.minimumPercentage,
              })
          .toList(),
    };
  }
}
